// lib/screens/entry/create_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_entry_controller.dart';

class CreateEntryScreen extends GetView<CreateEntryController> {
  const CreateEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Entry'),
        // topicId varsa başlığı da gösterebiliriz (controller.topicId.value)
      ),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Entry Giriş Alanı
            Expanded( // Alanın kalan tüm yüksekliği kaplaması için
              child: TextFormField(
                controller: controller.contentController,
                decoration: const InputDecoration(
                  hintText: 'Enter your entry here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null, // Sınırsız satır
                keyboardType: TextInputType.multiline,
                expands: true, // Alanın genişlemesini sağlar
                textAlignVertical: TextAlignVertical.top, // Yazıyı yukarıdan başlat
              ),
            ),
            const SizedBox(height: 15),

            // Hata Mesajı Alanı
            Obx(() {
              if (controller.errorMessage.value != null &&
                  controller.errorMessage.value!.isNotEmpty) {
                return Text(
                  controller.errorMessage.value!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
            const SizedBox(height: 10),

            // Gönderme Butonu veya Yüklenme Indicator'ı
            Obx(() {
              return controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.submitEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Submit Entry'),
              );
            }),
          ],
        ),
      ),
    );
  }
}