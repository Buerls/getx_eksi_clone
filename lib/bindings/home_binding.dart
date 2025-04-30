import 'package:get/get.dart';
import '../controllers/topic_controller.dart'; // TopicController'ı varsayıyoruz

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TopicController());
  }
}