// lib/screens/topic/create_topic_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_topic_controller.dart';

class CreateTopicScreen extends GetView<CreateTopicController> {
  const CreateTopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>(); // Form key'i build içinde tanımlayabiliriz

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Topic'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Çok uzun entry girme ihtimaline karşı SingleChildScrollView
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık Giriş Alanı
                TextFormField(
                  controller: controller.titleController,
                  decoration: const InputDecoration(
                    labelText: 'Topic Title',
                    hintText: 'Enter the topic title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.trim().isEmpty ? 'Title cannot be empty' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),

                // İlk Entry Giriş Alanı
                TextFormField(
                  controller: controller.contentController,
                  decoration: const InputDecoration(
                    labelText: 'First Entry Content',
                    hintText: 'Enter the content for the first entry...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true, // Çok satırlı için label'ı yukarı hizala
                  ),
                  maxLines: 8, // Başlangıçta görünecek satır sayısı
                  minLines: 5, // Minimum satır sayısı
                  keyboardType: TextInputType.multiline,
                  validator: (value) => value!.trim().isEmpty ? 'Entry content cannot be empty' : null,
                  textInputAction: TextInputAction.newline, // Enter ile yeni satır
                ),
                const SizedBox(height: 15),

                // Hata Mesajı Alanı
                Obx(() {
                  if (controller.errorMessage.value != null) {
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        controller.submitTopicAndEntry();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Create Topic & Entry'),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}