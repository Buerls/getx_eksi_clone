// lib/screens/home/topic_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/topic_detail_controller.dart';
import '../../data/models/entry.dart';
import '../../routes/app_routes.dart';
import '../../utils/date_formatter.dart'; // Entry modelini import et

class TopicDetailScreen extends GetView<TopicDetailController> {
  const TopicDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Başlık yüklenince AppBar'da gösterelim
        title: Obx(() => Text(controller.topic.value?.title ?? 'Loading Topic...')),
      ),
      // Ana Obx tüm body'yi sarmalar ve state'e göre farklı widgetlar gösterir
      body: Obx(() {
        // 1. Genel Yüklenme veya Hata Durumu
        if (controller.isLoadingTopic.value || (controller.isLoadingEntries.value && controller.entryList.isEmpty)) {
          // Eğer topic veya ilk entryler yükleniyorsa göster
          return const Center(child: CircularProgressIndicator());
        } else if (controller.errorMessage.value != null && controller.topic.value == null) {
          // Eğer başlık yüklenirken hata olduysa (veya ID geçersizse)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: ${controller.errorMessage.value}', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      // Yeniden deneme tüm veriyi çekmeyi tetikler
                      onPressed: () => controller.fetchAllData(isRefresh: true),
                      child: const Text('Retry'),
                    )
                  ]
              ),
            ),
          );
        } else if (controller.topic.value == null) {
          // ID geçerli ama topic bulunamadıysa (API 404 döndüyse)
          return const Center(child: Text('Topic not found.'));
        }
        // 2. Başlık ve Entry'lerin Gösterilmesi
        else {
          // RefreshIndicator ile pull-to-refresh ekleyelim
          return RefreshIndicator(
            onRefresh: controller.refreshAll,
            child: CustomScrollView( // Farklı tipte içerikleri (başlık + liste) birleştirmek için
              slivers: [
                // Başlık Detay Alanı
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.topic.value!.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'by ${controller.topic.value!.authorUsername} on ${formatDate(controller.topic.value!.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Divider(height: 30),
                        // Başlıkla ilgili başka bilgiler veya butonlar buraya eklenebilir
                      ],
                    ),
                  ),
                ),

                // Entry Listesi (SliverList ile)
                Obx(() { // Entry listesi değişikliklerini dinlemek için iç Obx
                  if (controller.isLoadingEntries.value && controller.entryList.isEmpty) {
                    // Entry'ler yükleniyor (başlık yüklendi ama entryler henüz gelmedi)
                    return const SliverFillRemaining( // Ekranı doldurması için
                        child: Center(child: CircularProgressIndicator())
                    );
                  } else if (controller.errorMessage.value != null && controller.entryList.isEmpty) {
                    // Entry yüklemede hata oldu
                    return SliverFillRemaining(
                        child: Center(child: Text('Error loading entries: ${controller.errorMessage.value}', style: const TextStyle(color: Colors.red)))
                    );
                  } else if (controller.entryList.isEmpty) {
                    // Hiç entry yoksa
                    return const SliverFillRemaining(
                        child: Center(child: Text('No entries found for this topic yet.'))
                    );
                  } else {
                    // Entry listesini göster
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(

                            (context, index) {
                          // Listenin sonu ve daha fazla entry varsa
                          if (index == controller.entryList.length) {
                            if (controller.hasMoreEntries.value) {
                              // Daha fazla yükleme göstergesi
                              // Görünür olduğunda yüklemeyi tetikleyebiliriz
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if(controller.hasMoreEntries.value && !controller.isLoadingMoreEntries.value) {
                                  controller.loadMoreEntries();
                                }
                              });
                              return const Center(
                                  child: Padding( padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())
                              );
                            } else {
                              // Daha fazla entry yoksa boşluk
                              return const SizedBox.shrink();
                            }
                          }

                          // Normal entry elemanı
                          final Entry entry = controller.entryList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Senin margin değerlerin farklı olabilir, onları koru
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12), // Padding ayarı
                              // Başlık olarak Entry içeriği
                              title: Text(entry.content),

                              // Subtitle olarak Column kullanarak hem yazar/tarih hem de oylama butonlarını ekle
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // İçeriği sola yasla
                                children: [
                                  // Yazar ve Tarih (Önceki Padding kaldırıldı, Column içinde)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0), // Üst ve alt boşluk
                                    child: Text(
                                      'by ${entry.authorUsername} - ${formatDate(entry.createdAt)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),

                                  // --- YENİ: OYLAMA BÖLÜMÜ (Row olarak eklendi) ---
                                  Row(
                                    // mainAxisAlignment: MainAxisAlignment.end, // Sağa yaslamak yerine başta kalsın? Veya Spacer() kullan?
                                    children: [
                                      // Upvote Butonu
                                      IconButton(
                                        icon: Icon(
                                          entry.isUpvoted ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                                          color: entry.isUpvoted ? Theme.of(context).colorScheme.primary : Colors.grey,
                                        ),
                                        iconSize: 18,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.only(right: 4), // Sağ boşluk
                                        splashRadius: 20, // Tıklama efekti alanı
                                        tooltip: 'Upvote',
                                        onPressed: () {
                                          controller.vote(entry.id, entry.isUpvoted ? 0 : 1);
                                        },
                                      ),
                                      Text(entry.upvotesCount.toString(), style: Theme.of(context).textTheme.bodySmall),
                                      const SizedBox(width: 12), // Butonlar arası boşluk

                                      // Downvote Butonu
                                      IconButton(
                                        icon: Icon(
                                          entry.isDownvoted ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
                                          color: entry.isDownvoted ? Colors.blueGrey : Colors.grey,
                                        ),
                                        iconSize: 18,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.only(right: 4), // Sağ boşluk
                                        splashRadius: 20,
                                        tooltip: 'Downvote',
                                        onPressed: () {
                                          controller.vote(entry.id, entry.isDownvoted ? 0 : -1);
                                        },
                                      ),
                                      Text(entry.downvotesCount.toString(), style: Theme.of(context).textTheme.bodySmall),

                                      // Buraya Spacer() ekleyerek sonraki ikonları sağa itebiliriz
                                      // const Spacer(),
                                      // IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}), // Favori vb.
                                    ],
                                  ),
                                  // --- OYLAMA BÖLÜMÜ SONU ---
                                ],
                              ), // Subtitle Column sonu
                              // trailing: ... // İstersen sağ tarafa başka bir ikon vb. ekleyebilirsin
                            ), // ListTile sonu
                          );
                            },
                        childCount: controller.entryList.length + (controller.hasMoreEntries.value ? 1 : 0),
                      ),
                    );
                  }
                }),
              ],
            ),
          );
        }
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async { // async olduğundan emin ol
          if (controller.topicId.value != null) {
            // Navigasyondan dönen sonucu al
            Get.toNamed(
              AppRoutes.CREATE_ENTRY,
              arguments: controller.topicId.value,
              // Binding hala GetPage tanımında olduğu için burada belirtmeye gerek yok
            );
          } else {
            Get.snackbar('Error', 'Cannot create entry without a valid topic ID.');
          }
        },
        tooltip: 'Add Entry',
        child: const Icon(Icons.add),
      ),
      // İsteğe bağlı: Yeni entry eklemek için FloatingActionButton
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Yeni entry ekleme ekranına git (topicId ile birlikte)
      //     // Get.toNamed(...);
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}