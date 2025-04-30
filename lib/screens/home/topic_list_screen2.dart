// lib/screens/home/topic_list_screen2.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_eksi_clone/utils/date_formatter.dart';
import '../../controllers/topic_controller.dart';
import '../../controllers/auth_controller.dart'; // Logout için
import '../../routes/app_routes.dart'; // Navigasyon için
import '../../data/models/topic.dart'; // Topic modeli için

class TopicListScreen extends GetView<TopicController> {
  const TopicListScreen({super.key});



  @override
  Widget build(BuildContext context) {
    // AuthController'a erişim (Logout butonu için)
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Emin misiniz diye sormak iyi olabilir
              Get.defaultDialog(
                  title: "Logout",
                  middleText: "Are you sure you want to logout?",
                  textConfirm: "Logout",
                  textCancel: "Cancel",
                  confirmTextColor: Colors.white,
                  onConfirm: () {
                    authController.logout();
                  }
              );
            },
          )
        ],
      ),
      // Obx ile tüm body'yi sarmalayarak state değişikliklerine göre UI'ı güncelle
      body: Obx(() {
        // 1. İlk Yüklenme Durumu
        if (controller.isLoading.value && controller.isFirstLoad.value) {
          return const Center(child: CircularProgressIndicator());
        }
        // 2. Hata Durumu
        else if (controller.errorMessage.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: ${controller.errorMessage.value}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => controller.refreshTopics(),
                    child: const Text('Retry'),
                  )
                ],
              ),
            ),
          );
        }
        // 3. Boş Liste Durumu
        else if (controller.topicList.isEmpty) {
          return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No topics found.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => controller.refreshTopics(),
                    child: const Text('Refresh'),
                  )
                ],
              )
          );
        }
        // 4. Veri Listeleme Durumu
        else {
          // Pull-to-refresh ve Infinite Scroll ekleyelim
          return RefreshIndicator(
            onRefresh: controller.refreshTopics, // Aşağı çekince tetiklenecek metot
            child: ListView.builder(
              // Infinite scroll için controller dinleme
              // TODO: ScrollController ekleyip 'loadMoreTopics' tetiklenecek
              itemCount: controller.topicList.length + (controller.hasMoreTopics.value ? 1 : 0),
              itemBuilder: (context, index) {
                // Eğer son eleman ise ve daha fazla veri varsa yükleme göstergesi
                if (index == controller.topicList.length) {
                  // Yükleme göstergesi görünür olduğunda daha fazla veri çek
                  // Bu basit kontrol her zaman çalışmayabilir, ScrollController daha iyi.
                  // Şimdilik sadece göstergeyi koyalım. 'loadMore' butonu eklenebilir.
                  // VEYA:
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Build bittikten sonra kontrol et, doğrudan build içinde state değiştirme
                    if(controller.hasMoreTopics.value && !controller.isLoadingMore.value) {
                      controller.loadMoreTopics();
                    }
                  });
                  final Topic topic = controller.topicList[index];
                  return Card( // ListTile'ı Card ile sar
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 1, // Hafif bir gölge
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(topic.title, style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text(
                        'by ${topic.authorUsername} - ${formatDate(topic.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () {
                        Get.toNamed(AppRoutes.TOPIC_DETAIL.replaceFirst(':topicId', topic.id.toString()));
                      },
                    ),
                  );
                }

                // Normal liste elemanı (Topic)
                final Topic topic = controller.topicList[index];
                return ListTile(
                  title: Text(topic.title),
                  subtitle: Text('by ${topic.authorUsername} - ${formatDate(topic.createdAt)}'), // Tarihi lokal saate çevir
                  // trailing: Text('#${topic.id}'), // ID'yi göstermek istersen
                  onTap: () {
                    // TODO: Topic Detail sayfasına yönlendirme
                    Get.toNamed(AppRoutes.TOPIC_DETAIL.replaceFirst(':topicId', topic.id.toString()));
                    print('Tapped on topic ${topic.id}');
                  },
                );
              },
            ),
          );
        }
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () { // Burası _showCreateTopicDialog() OLMAMALI!
          Get.toNamed(AppRoutes.CREATE_TOPIC); // Doğrusu bu olmalı
        },
        tooltip: 'Create Topic',
        child: const Icon(Icons.add),
      ),
    );
  }
}