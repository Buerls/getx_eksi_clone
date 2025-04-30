// lib/bindings/app_binding.dart
import 'package:get/get.dart';
import '../data/services/api_service.dart'; // ApiService'i import et

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // ApiService'i uygulama başlarken yükle ve uygulama kapanana kadar yaşat (permanent: true)
    Get.put(ApiService(), permanent: true);

    // Diğer genel servisler (örn: StorageService) buraya eklenebilir
    // Get.put(StorageService());
  }
}