// lib/bindings/create_entry_binding.dart
import 'package:get/get.dart';
import '../controllers/create_entry_controller.dart';

class CreateEntryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateEntryController());
  }
}