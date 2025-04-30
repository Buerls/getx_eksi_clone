import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController'ı sadece ihtiyaç duyulduğunda (ilgili route'a girildiğinde) oluştur
    Get.lazyPut(() => AuthController());
  }
}