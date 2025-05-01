// lib/controllers/topic_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../data/services/api_service.dart';
import '../data/models/topic.dart'; // Topic modelini import et
import 'package:dio/dio.dart';  // Response tipi için

class TopicController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // --- Reaktif State Değişkenleri ---
  var isLoading = true.obs; // Başlangıçta yükleniyor
  var isFirstLoad = true.obs; // Sadece ilk yükleme için farklı bir indicator gösterebiliriz
  var isLoadingMore = false.obs; // Daha fazla yükleniyor mu?
  var topicList = <Topic>[].obs; // Başlık listesi (RxList)
  var currentPage = 1.obs; // Mevcut sayfa numarası
  var totalTopics = 0.obs; // Toplam başlık sayısı (API'den gelecek)
  var hasMoreTopics = true.obs; // Daha fazla başlık var mı?
  final RxnString errorMessage = RxnString(); // Hata mesajı

  final RxBool isLoadingPopular = true.obs;
  final RxList<Topic> popularTopicList = <Topic>[].obs;
  final RxnString popularTopicsError = RxnString();


  final RxString searchQuery = ''.obs;

  Timer? _debounce;

  // --- Lifecycle ---
  @override
  void onInit() {
    super.onInit();
    fetchTopics(isRefresh: true); // Başlangıçta normal yükleme
    fetchPopularTopics();

    // Arama sorgusu değiştiğinde debounce ile fetchTopics'i çağır
    // 'debounce' GetX'in RxString'e eklediği bir extension metodudur.
    debounce(searchQuery, (_) {
      debugPrint("2. Debounce Triggered! Fetching for query: ${searchQuery.value}"); // Eklendi
      fetchTopics(isRefresh: true, query: searchQuery.value);

    },
      time: const Duration(milliseconds: 500), // 500ms bekleme süresi
    );

  }

  @override
  void onClose() {
    _debounce?.cancel(); // Controller kapanırken debounce timer'ını iptal et
    super.onClose();
  }

  // --- Metotlar ---

  Future<void> fetchPopularTopics() async {
    isLoadingPopular(true);
    popularTopicsError(null);
    try {
      final response = await _apiService.getPopularTopics();
      // Backend'in doğrudan bir liste döndürdüğünü varsayıyoruz
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> results = response.data as List;
        final List<Topic> newPopularTopics = results.map((json) => Topic.fromJson(json)).toList();
        popularTopicList.assignAll(newPopularTopics); // Listeyi ata
        print("Popular topics fetched: ${popularTopicList.length}");
      } else {
        // Eğer backend pagination yapısı döndürüyorsa (beklenmedik ama olabilir):
        // final Map<String, dynamic> data = response.data;
        // final List<dynamic> results = data['results'] as List? ?? [];
        // ...
        throw Exception('Popular topics API did not return a List as expected.');
      }
    } catch (e) {
      print("Error fetching popular topics: $e");
      popularTopicsError("Failed to load popular topics: ${e.toString().replaceFirst('Exception: ', '')}");
      popularTopicList.clear();
    } finally {
      isLoadingPopular(false);
    }
  }



  // Başlıkları getiren ana metot
  Future<void> fetchTopics({bool isRefresh = false, String? query}) async {
    // Eğer arama sorgusu değişmediyse ve refresh değilse tekrar yükleme (bu kontrol debounce ile gereksizleşebilir)
    // if (query == searchQuery.value && !isRefresh && !isLoadingMore.value && hasMoreTopics.value) return;
    debugPrint("3. fetchTopics Called. isRefresh: $isRefresh, query: '$query', currentSearchState: '${searchQuery.value}'");
    // Yükleme state'lerini ayarla
    if (isRefresh) {
      print("Refreshing topics... Query: '$query'");
      currentPage.value = 1;
      hasMoreTopics.value = true;
      topicList.clear(); // Refresh sırasında listeyi temizle
      isFirstLoad.value = true;
      errorMessage(null);
      // searchQuery state'ini burada SIFIRLAMA, arama yapılıyorsa kalsın
    } else {
      if (isLoadingMore.value || !hasMoreTopics.value) return; // Zaten yükleniyor veya daha fazla yoksa çık
      isLoadingMore(true);
      print("Fetching more topics (page ${currentPage.value})... Query: '$query'");
    }
    isLoading(true); // Genel yükleme (ilk veya refresh)

    // Kullanılacak sorguyu belirle (parametre yoksa state'deki kullanılır)
    final effectiveQuery = query ?? searchQuery.value;

    try {
      // ApiService'i güncellenmiş query ile çağır
      final Response response = await _apiService.getTopics(
          page: currentPage.value,
          searchQuery: effectiveQuery // Arama sorgusunu ilet
      );

      // ... (Gelen veriyi işleme kısmı aynı: results, newTopics, pagination state'leri) ...
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List? ?? [];
        final List<Topic> newTopics = results.map((topicJson) => Topic.fromJson(topicJson)).toList();

        debugPrint("5. API Response Count: ${data['count']}, Results: ${results.length}");

        if (isRefresh) {
          topicList.assignAll(newTopics);
        } else {
          topicList.addAll(newTopics);
        }
        debugPrint("6. topicList updated. New total count in list: ${topicList.length}"); // Eklendi

        totalTopics(data['count'] as int? ?? 0);
        hasMoreTopics(data['next'] != null);
        if (hasMoreTopics.value) {
          currentPage.value++;
        }
      } else {
        throw Exception('Failed to parse topic data');
      }

    } catch (e) {
      print("Error fetching topics: $e");
      errorMessage("Failed to load topics: ${e.toString()}");
      if (isRefresh) {
        topicList.clear();
        hasMoreTopics.value = false;
      }
    } finally {
      isLoading(false);
      isLoadingMore(false);
      isFirstLoad(false);
    }
  }
  void updateSearchQuery(String newQuery) {
    // Doğrudan searchQuery'yi güncellemek debounce'u tetikleyecektir.
    searchQuery.value = newQuery;
    debugPrint("1. Search Query Updated in Controller: ${searchQuery.value}"); // Eklendi
  }

  void clearSearch() {
    searchQuery.value = ''; // Bu da debounce'u tetikler ve tüm listeyi getirir
    // Arama kutusunu da temizlemek gerekebilir (UI tarafında)
  }




  // Daha fazla yükleme için UI tarafından çağrılacak metot
  void loadMoreTopics() {
    // Mevcut searchQuery ile bir sonraki sayfayı çek
    fetchTopics(query: searchQuery.value);
  }

  // Yenileme için UI tarafından çağrılacak metot
  Future<void> refreshTopics() async {
    // Refresh hem normal listeyi (mevcut arama sorgusuyla) hem de popüler listeyi tetikler
    print("Refreshing both topic lists...");
    // isFirstLoad'ı tekrar true yapabiliriz ki ana liste için yüklenme göstergesi görünsün
    isFirstLoad(true);
    errorMessage(null); // Hataları temizle
    popularTopicsError(null);

    // İki isteği aynı anda başlat
    final refreshNormalFuture = fetchTopics(isRefresh: true, query: searchQuery.value);
    final refreshPopularFuture = fetchPopularTopics();

    // İkisinin de bitmesini bekle (UI'ın daha tutarlı güncellenmesi için)
    try {
      await Future.wait([refreshNormalFuture, refreshPopularFuture]);
    } catch(e) {
      // Hatalar zaten ilgili metotlarda yakalanıp state'e yazılıyor
      print("Error during parallel refresh: $e");
    }
    print("Both lists refreshed.");
  }

}