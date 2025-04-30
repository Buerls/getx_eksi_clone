// lib/controllers/create_entry_controller.dart
import 'package:flutter/material.dart'; // TextEditingController için
import 'package:get/get.dart';
import '../data/services/api_service.dart';
// TopicDetailController'ı bulup refresh tetiklemek için (opsiyonel)
import 'topic_detail_controller.dart';

class CreateEntryController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // State
  final isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  // Form elemanı için Controller
  late final TextEditingController contentController;

  // Hangi başlığa entry girildiğini tutacak değişken
  late final int topicId;

  @override
  void onInit() {
    super.onInit();
    contentController = TextEditingController();
    // topicId'yi navigasyon argümanlarından alıyoruz
    if (Get.arguments is int) {
      topicId = Get.arguments;
    } else {
      // Argüman gelmediyse veya tipi yanlışsa hata ver/geri dön
      print("Error: topicId argument not found or invalid.");
      errorMessage("Cannot create entry: Missing topic information.");
      // Belki bir önceki sayfaya otomatik yönlendirme yapılabilir
      // Get.back();
    }
  }

  @override
  void onClose() {
    contentController.dispose(); // Controller'ı temizle
    super.onClose();
  }

  // Entry oluşturma metodu
  Future<void> submitEntry() async {
    if (contentController.text.trim().isEmpty) {
      errorMessage("Entry content cannot be empty.");
      return;
    }
    if (topicId == null) { // onInit'te hata oluşmuş olabilir
      errorMessage("Cannot create entry: Missing topic information.");
      return;
    }

    isLoading(true);
    errorMessage(null);

    try {
      await _apiService.createEntry(
        topicId: topicId,
        content: contentController.text.trim(),
      );
      print("Entry submitted successfully via Controller.");

      // Başarı mesajı göster
      Get.snackbar(
        'Success',
        'Entry submitted successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );


      try {
        final TopicDetailController detailController = Get.find<TopicDetailController>();
        // Yenilemenin bitmesini bekleyebiliriz (isteğe bağlı)
        await detailController.fetchEntries(isRefresh: true);
        print("TopicDetailController refreshed directly.");
      } catch (e) {
        print("Could not find/refresh TopicDetailController: $e");
        // Hata olsa bile geri dönmeye devam et.
      }
      print("Attempting to navigate back with result: true");
      Get.back(closeOverlays: true,);


    } catch (e) {
      print("Entry submission failed via Controller: $e");
      errorMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading(false);
    }
  }
}