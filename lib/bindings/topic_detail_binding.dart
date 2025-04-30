// lib/bindings/topic_detail_binding.dart
import 'package:get/get.dart';
import '../controllers/topic_detail_controller.dart';

class TopicDetailBinding extends Bindings {
  @override
  void dependencies() {
    // lazyPut ile sadece ihtiyaç duyulduğunda controller oluşturulur
    Get.lazyPut(() => TopicDetailController());
  }
}