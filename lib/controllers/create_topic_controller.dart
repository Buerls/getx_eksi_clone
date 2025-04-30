// lib/controllers/create_topic_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/api_service.dart';
import 'topic_controller.dart'; // Topic listesini refresh etmek için

class CreateTopicController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // State
  final isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  // Form elemanları için Controller'lar
  late final TextEditingController titleController;
  late final TextEditingController contentController;

  @override
  void onInit() {
    super.onInit();
    titleController = TextEditingController();
    contentController = TextEditingController();
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    super.onClose();
  }

  // Başlık ve ilk entry'i oluşturma metodu
  Future<void> submitTopicAndEntry() async {
    final String title = titleController.text.trim();
    final String content = contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      errorMessage("Both title and first entry content are required.");
      return;
    }

    isLoading(true);
    errorMessage(null);

    try {
      // API'yi çağır
      await _apiService.createTopic(title: title, firstEntryContent: content);
      print("Topic and first entry submitted successfully via Controller.");

      // Başarı mesajı göster
      Get.snackbar(
        'Success',
        'Topic "$title" created successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      // TopicListScreen'deki listeyi yenilemek için TopicController'ı bul ve refresh et
      try {
        // TopicController'ın hala aktif olduğunu varsayıyoruz
        final TopicController topicController = Get.find<TopicController>();
        await topicController.refreshTopics(); // Listeyi yenile
        print("TopicController refreshed.");
      } catch(e) {
        print("Could not find/refresh TopicController: $e");
        // Hata olsa bile geri dönmeye devam etmeli
      }


      // Başarılı olduktan sonra TopicListScreen'e geri dön
      Get.back(closeOverlays: true); // Sonuç göndermeye gerek yok, refresh'i tetikledik

    } catch (e) {
      print("Topic/Entry submission failed via Controller: $e");
      errorMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading(false);
    }
  }
}