// lib/screens/home/topic_list_screen2.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_eksi_clone/shared/widgets/main_layout.dart';
import '../../controllers/topic_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../data/models/topic.dart';
import '../../shared/widgets/info_message_widget.dart';
import '../../utils/date_formatter.dart'; // date formatter importu

// StatefulWidget'a çevirildi
class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  // GetX Controller'larına erişim (State içinde)
  final TopicController controller = Get.find<TopicController>();
  final AuthController authController = Get.find<AuthController>();

  // ScrollController
  final ScrollController _scrollController = ScrollController();

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Scroll listener'ı ekle
    _searchController = TextEditingController(text: controller.searchQuery.value); // Başlangıç değeri controller'dan gelsin
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Listener'ı ve controller'ı temizle
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose(); // Arama controller'ını da dispose et
    super.dispose();
  }

  // Kaydırma dinleyicisi
  void _onScroll() {
    // Eğer listenin sonuna yaklaşıldıysa, daha fazla veri varsa ve şu an yüklenmiyorsa
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        controller.hasMoreTopics.value &&
        !controller.isLoadingMore.value &&
        !controller.isLoading.value // Genel yükleme de olmamalı
    ) {
      print("Scroll listener triggered: Loading more topics...");
      controller.loadMoreTopics();
    }
  }

  // Dialog gösterme metodu (State içine taşındı)



  @override
  Widget build(BuildContext context) {
    return MainLayout( // Ana Layout'u kullanmaya devam
      title: 'Tatlı Sözlük', // MainLayout'a boş başlık verelim, AppBar'ı aşağıda override edelim
      bgcolor: Colors.blueGrey,
      // BODY kısmını Row ile değiştiriyoruz
      body: Scaffold(
        // Ayrı bir Scaffold ekleyerek AppBar'ı yönetebiliriz
        appBar: AppBar(
          backgroundColor: Colors.white,
          // Arama Çubuğu
          title: Container( // Container ile padding vs. ayarlanabilir
            height: 35,
            width: 450,
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _searchController, // Controller'ı bağla
              decoration: InputDecoration(
                hintText: 'Search Topics...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: Obx(() => // Temizle butonu için Obx
                controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear(); // TextField'ı temizle
                    controller.clearSearch(); // Controller'daki aramayı temizle
                  },
                )
                    : const SizedBox.shrink() // Boşsa icon gösterme
                ),
                // Daha kompakt bir görünüm için
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20), // Yuvarlak kenarlar
                   // Kenarlık olmasın
                ),
                filled: true, // Arka plan rengi olsun
                fillColor: Colors.white.withOpacity(0.9), // Hafif transparan beyaz
              ),
              style: const TextStyle(fontSize: 14), // Yazı boyutu
              // Kullanıcı yazdıkça controller'daki state'i güncelle
              onChanged: controller.updateSearchQuery,
              // VEYA onSubmitted ile sadece Enter'a basınca arama:
              // onSubmitted: controller.searchTopics,
            ),
          ),

          actions: [ // AppBar action'ları
            IconButton(
              icon: const Icon(Icons.logout),
              color: Colors.teal,
              tooltip: 'Logout',
              onPressed: () {
                // Emin misiniz diye sormak iyi olabilir
                Get.defaultDialog(
                    title: "Logout",
                    middleText: "Are you sure you want to logout?",
                    textConfirm: "Logout",
                    textCancel: "Cancel",
                    confirmTextColor: Colors.teal,
                    onConfirm: () {
                      authController.logout();
                    }
                );
              },
            )
          ],


        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Get.toNamed(AppRoutes.CREATE_TOPIC), // CreateTopicScreen'e git
          tooltip: 'Create Topic',
          child: const Icon(Icons.add),
        ),
        body: Row( // Ana içerik alanı için Row
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Sol Sütun: Yeni Başlıklar (Genişleyebilir) ---
            Expanded(
              flex: 3, // Oranları ayarlayabilirsiniz
              child: Obx(() { // Ana liste state'i için Obx
                // Yüklenme, Hata, Boş durumları için InfoMessageWidget kullan
                if (controller.isLoading.value && controller.isFirstLoad.value) {
                  // return const Center(child: CircularProgressIndicator());
                  return const InfoMessageWidget(message: 'Loading topics...', icon: Icons.hourglass_empty);
                } else if (controller.errorMessage.value != null) {
                  return InfoMessageWidget(message: 'Error: ${controller.errorMessage.value}', showError: true, onRetry: controller.refreshTopics);
                } else if (controller.topicList.isEmpty) {
                  return InfoMessageWidget(message: 'No topics found for your search or filter.', icon: Icons.search_off, onRetry: controller.refreshTopics);
                } else {
                  // Yeni başlıklar listesi
                  return RefreshIndicator(
                    onRefresh: controller.refreshTopics,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, right: 8), // Sağdaki sütundan ayırmak için sağ padding
                      itemCount: controller.topicList.length + (controller.hasMoreTopics.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == controller.topicList.length) {
                          // Infinite scroll yükleme göstergesi
                          return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3))));
                        }
                        final Topic topic = controller.topicList[index];
                        // Card içinde Topic gösterimi (önceki adımdaki gibi)
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          elevation: 1,
                          child: InkWell( // Kartın tamamını tıklanabilir yapmak için ListTile'ı InkWell ile sarabiliriz
                            onTap: () {
                              Get.toNamed(AppRoutes.TOPIC_DETAIL.replaceFirst(':topicId', topic.id.toString()));
                            },
                            child: Padding( // ListTile yerine Padding ve Column ile daha fazla kontrol
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Başlık
                                  Text(
                                    topic.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500), // Biraz daha kalın
                                  ),
                                  const SizedBox(height: 4),
                                  // Yazar ve Tarih
                                  Text(
                                    'by ${topic.authorUsername} - ${formatDate(topic.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600), // Biraz daha soluk
                                  ),

                                  // *** YENİ EKLENEN KISIM: İlk Entry Snippet'ı ***
                                  if (topic.firstEntryContent != null && topic.firstEntryContent!.isNotEmpty) ...[
                                    const SizedBox(height: 8), // Üstteki ile araya boşluk
                                    Text(
                                      topic.firstEntryContent!,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 2, // En fazla 2 satır göster
                                      overflow: TextOverflow.ellipsis, // Taşarsa "..." ile bitir
                                    ),
                                  ],
                                  // *** EKLENEN KISIM SONU ***
                                ],
                              ),
                            ),
                          ),
                        );

                      },
                    ),
                  );
                }
              }), // Sol Obx sonu
            ), // Expanded (Sol Sütun) sonu

            // --- Sağ Sütun: Popüler Başlıklar ---
            Container(
              width: 300, // Sabit genişlik
              // height: double.infinity, // Tam yükseklik (opsiyonel)
              decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Theme.of(context).dividerColor, width: 1.0))
              ),
              child: Padding( // Sağ sütunun kendi iç padding'i
                padding: const EdgeInsets.only(left: 12.0, top: 8.0, right: 8.0, bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text( // Sağ sütun başlığı
                      "Popular Today",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 16, thickness: 1),
                    Expanded( // Liste için kalan alanı kullan
                      child: Obx(() { // Popüler liste state'i için Obx
                        if (controller.isLoadingPopular.value) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (controller.popularTopicsError.value != null) {
                          return InfoMessageWidget(message: 'Error: ${controller.popularTopicsError.value}', showError: true, onRetry: controller.fetchPopularTopics);
                        } else if (controller.popularTopicList.isEmpty) {
                          return const InfoMessageWidget(message: 'No popular topics found today.', icon: Icons.whatshot_outlined);
                        } else {
                          // Popüler başlıklar listesi
                          return ListView.builder(
                            itemCount: controller.popularTopicList.length,
                            itemBuilder: (context, index) {
                              final Topic popularTopic = controller.popularTopicList[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                                title: Text(
                                  popularTopic.title,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Entry sayısını göstermek istersek (backend sağlarsa)
                                // trailing: Text(popularTopic.todaysEntryCount.toString()), // Controller'da parse edilmeli
                                onTap: () {
                                  Get.toNamed(AppRoutes.TOPIC_DETAIL.replaceFirst(':topicId', popularTopic.id.toString()));
                                },
                              );
                            },
                          );
                        }
                      }), // Sağ Obx sonu
                    ), // Expanded sonu
                  ], // Column children sonu
                ),
              ),
            ), // Container (Sağ Sütun) sonu
          ], // Row children sonu
        ),
        // Row sonu
      ), // Scaffold sonu
    );
  }
// _buildInfoWidget metodu buraya eklenebilir
// Widget _buildInfoWidget(String message, {bool showError = false, VoidCallback? onRetry}) { ... }
}