// lib/controllers/topic_detail_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../data/services/api_service.dart';
import '../data/models/topic.dart';
import '../data/models/entry.dart';
import 'package:dio/dio.dart';

class TopicDetailController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // --- State Değişkenleri ---
  final RxnInt topicId = RxnInt(); // Rota parametresinden gelen ID
  final Rxn<Topic> topic = Rxn<Topic>(); // Yüklenen başlık detayı
  final RxList<Entry> entryList = <Entry>[].obs; // Entry listesi

  // Yüklenme Durumları
  final RxBool isLoadingTopic = true.obs;
  final RxBool isLoadingEntries = true.obs; // İlk entry yüklemesi
  final RxBool isLoadingMoreEntries = false.obs; // Daha fazla entry yükleniyor mu?

  // Sayfalama (Entry'ler için)
  final RxInt currentEntryPage = 1.obs;
  final RxInt totalEntries = 0.obs;
  final RxBool hasMoreEntries = true.obs;

  // Hata Durumu
  final RxnString errorMessage = RxnString();

  // --- Lifecycle ---
  @override
  void onInit() {
    super.onInit();
    // Rota parametresinden topicId'yi al
    final idParam = Get.parameters['topicId'];
    if (idParam != null) {
      final parsedId = int.tryParse(idParam);
      if (parsedId != null) {
        topicId.value = parsedId;
        // ID geçerliyse verileri çekmeye başla
        fetchAllData();
      } else {
        errorMessage("Invalid Topic ID format.");
        _setLoading(false); // Tüm yüklemeleri durdur
      }
    } else {
      errorMessage("Topic ID not found in route parameters.");
      _setLoading(false);
    }
  }

  // --- Veri Çekme Metotları ---

  // Hem başlığı hem de ilk sayfa entry'leri çek
  Future<void> fetchAllData({bool isRefresh = false}) async {
    if (topicId.value == null) return; // ID yoksa işlem yapma

    _setLoading(true, isFirstLoad: true); // Yüklemeyi başlat
    errorMessage(null); // Hataları temizle

    // İki isteği paralel olarak yapabiliriz (Future.wait)
    try {
      await Future.wait([
        fetchTopicDetails(),
        fetchEntries(isRefresh: true), // Refresh ise entry'leri de sıfırla
      ]);
    } catch(e) {
      // Hata zaten ilgili fetch metodunda ayarlanmış olmalı
      print("Error fetching all data: $e");
    } finally {
      _setLoading(false, isFirstLoad: false); // Yükleme bitti
    }
  }


  // Başlık detayını çek
  Future<void> fetchTopicDetails() async {
    if (topicId.value == null) return;
    isLoadingTopic(true); // Sadece topic yükleniyor
    try {
      final Response response = await _apiService.getTopicDetail(topicId.value!);
      if (response.statusCode == 200 && response.data != null) {
        topic.value = Topic.fromJson(response.data);
      } else {
        throw Exception('Failed to parse topic detail');
      }
    } catch (e) {
      print("Error fetching topic details: $e");
      errorMessage("Failed to load topic details: ${e.toString()}");
      topic.value = null; // Hata durumunda başlığı temizle
    } finally {
      isLoadingTopic(false);
    }
  }

  // Entry'leri çek (sayfalama ile)
  Future<void> fetchEntries({bool isRefresh = false}) async {
    if (topicId.value == null) return;

    // Zaten yükleniyorsa veya daha fazla veri yoksa (ve refresh değilse) işlem yapma
    if (isLoadingMoreEntries.value || (!hasMoreEntries.value && !isRefresh)) return;

    if (isRefresh) {
      currentEntryPage.value = 1;
      hasMoreEntries.value = true;
      entryList.clear();
      isLoadingEntries(true); // İlk sayfa yükleniyor
      errorMessage(null); // Hataları temizle (entry için)
    } else {
      isLoadingMoreEntries(true); // Daha fazla yükleniyor
    }

    try {
      final Response response = await _apiService.getEntriesForTopic(topicId.value!, page: currentEntryPage.value);

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List? ?? [];
        final List<Entry> newEntries = results.map((entryJson) => Entry.fromJson(entryJson)).toList();

        if (isRefresh) {
          entryList.assignAll(newEntries);
        } else {
          entryList.addAll(newEntries);
        }

        totalEntries(data['count'] as int? ?? 0);
        hasMoreEntries(data['next'] != null);

        if (hasMoreEntries.value) {
          currentEntryPage.value++;
        }
        print("Entries fetched. Page: ${currentEntryPage.value - 1}, Total: ${totalEntries.value}, HasMore: ${hasMoreEntries.value}");
      } else {
        throw Exception('Failed to parse entries data');
      }
    } catch (e) {
      print("Error fetching entries: $e");
      errorMessage("Failed to load entries: ${e.toString()}");
      if (isRefresh) {
        entryList.clear();
        hasMoreEntries.value = false;
      }
    } finally {
      isLoadingEntries(false);
      isLoadingMoreEntries(false);
    }
  }

  // Daha fazla entry yükleme metodu
  void loadMoreEntries() {
    fetchEntries();
  }

  // Tüm veriyi yenileme metodu (Pull-to-refresh için)
  Future<void> refreshAll() async {
    await fetchAllData(isRefresh: true);
  }

  // Yardımcı yükleme state ayarlama metodu
  void _setLoading(bool loading, {bool isFirstLoad = false}) {
    isLoadingTopic(loading);
    isLoadingEntries(loading);
    if (!loading) { // Yükleme bitince 'more' flag'ini de kapat
      isLoadingMoreEntries(false);
    }
    // İlk yükleme flag'i sadece başlangıçta veya refresh'te true olmalı
  }

  Future<void> vote(int entryId, int newVoteType) async {
    // newVoteType: 1 (up), -1 (down), 0 (cancel)

    // 1. Optimistic Update: UI'ı hemen güncelle
    final index = entryList.indexWhere((e) => e.id == entryId);
    if (index == -1) return; // Entry bulunamadı

    final Entry originalEntry = entryList[index]; // Orijinal entry'i sakla (geri almak için)

    // Geçici olarak güncellenecek değerleri hesapla
    int tempUpvotes = originalEntry.upvotesCount;
    int tempDownvotes = originalEntry.downvotesCount;
    int? tempUserVote = newVoteType; // Yeni oy durumu

    // Önceki oyu geri al (sayılardan düş)
    if (originalEntry.isUpvoted) tempUpvotes--;
    else if (originalEntry.isDownvoted) tempDownvotes--;

    // Yeni oyu uygula (sayılara ekle)
    if (newVoteType == 1) tempUpvotes++;
    else if (newVoteType == -1) tempDownvotes++;
    // Eğer aynı oya tekrar basıldıysa (iptal)
    else if (newVoteType == 0) {
      if (originalEntry.currentUserVote == null) return; // Zaten oy yoksa bir şey yapma
      tempUserVote = null; // Oyu null yap (iptal)
      print("Canceling vote for entry $entryId");
    }

    // Yeni entry nesnesini oluştur (immutable update)
    final Entry updatedEntry = Entry(
        id: originalEntry.id, topic: originalEntry.topic, topicTitle: originalEntry.topicTitle,
        author: originalEntry.author, authorUsername: originalEntry.authorUsername,
        content: originalEntry.content, createdAt: originalEntry.createdAt, updatedAt: originalEntry.updatedAt,
        upvotesCount: tempUpvotes, // Güncel sayı
        downvotesCount: tempDownvotes, // Güncel sayı
        currentUserVote: tempUserVote // Güncel oy
    );

    // Listeyi güncelle (GetX RxList değişikliği algılar)
    entryList[index] = updatedEntry;
    print("Optimistic update: Entry $entryId, Vote: $tempUserVote, Up: $tempUpvotes, Down: $tempDownvotes");

    // 2. API İsteğini Gönder
    try {
      if (tempUserVote != null) { // Oy verme veya değiştirme
        await _apiService.voteEntry(entryId, tempUserVote);
      } else { // Oyu iptal etme
        await _apiService.removeVote(entryId); // Veya voteEntry(entryId, 0)
      }
      print("API vote/remove successful for entry $entryId");
      // Başarılı olursa bir şey yapmaya gerek yok, UI zaten güncel.
      // Backend'den dönen güncel sayılarla listeyi tekrar güncellemek isteyebiliriz (isteğe bağlı)
      // final response = await _apiService...
      // final freshEntryData = Entry.fromJson(response.data['entry']); // Backend response'una göre
      // entryList[index] = freshEntryData;

    } catch (e) {
      print("API vote failed for entry $entryId: $e. Reverting UI.");
      // 3. Hata Olursa Geri Al
      entryList[index] = originalEntry; // Orijinal entry'i geri yükle
      // Hata mesajı göster
      Get.snackbar('Error', 'Failed to submit vote: ${e.toString().replaceFirst('Exception: ', '')}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  } // vote metodu sonu


}