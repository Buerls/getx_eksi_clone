// lib/bindings/create_topic_binding.dart
import 'package:get/get.dart';
import '../controllers/create_topic_controller.dart';

class CreateTopicBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateTopicController());
  }
}