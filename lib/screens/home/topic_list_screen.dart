// lib/screens/home/topic_list_screen2.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_eksi_clone/shared/widgets/main_layout.dart';
import '../../controllers/topic_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../data/models/topic.dart';
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
    return Scaffold(

      appBar: AppBar(
        title: Container( // Container ile padding vs. ayarlanabilir
          height: 40, // Yüksekliği ayarla
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
                borderSide: BorderSide.none, // Kenarlık olmasın
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
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
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
            ),
          );
        }
        // Veri Listeleme Durumu
        else {
        return RefreshIndicator(
        onRefresh: controller.refreshTopics,
        child: ListView.builder(
        controller: _scrollController, // ScrollController'ı ListView'a bağla
        itemCount: controller.topicList.length + (controller.hasMoreTopics.value ? 1 : 0),
        itemBuilder: (context, index) {
        if (index == controller.topicList.length) {
        // Yükleme göstergesi (Artık sadece gösterge, tetikleme listener'da)
        return const Center(
        child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator()));
        }

        // Normal liste elemanı (Card içinde ListTile)
        final Topic topic = controller.topicList[index];
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
      }),
      floatingActionButton: FloatingActionButton(
        // onPressed: _showCreateTopicDialog, // ESKİSİ SİLİNDİ
        onPressed: () { // YENİSİ
          Get.toNamed(AppRoutes.CREATE_TOPIC); // Yeni ekrana yönlendir
        },
        tooltip: 'Create Topic',
        child: const Icon(Icons.add),
      ),
    );
  }
// _buildInfoWidget metodu buraya eklenebilir
// Widget _buildInfoWidget(String message, {bool showError = false, VoidCallback? onRetry}) { ... }
}