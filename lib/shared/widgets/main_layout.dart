// lib/app/shared/widgets/main_layout.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart'; // Logout için

class MainLayout extends StatelessWidget {
  final Widget body; // İçerik bu widget'a parametre olarak gelecek
  final String title; // AppBar başlığı
  final List<Widget>? actions; // AppBar actions (Logout vb.)
  final FloatingActionButton? floatingActionButton; // FAB (varsa)

  const MainLayout({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    // AuthController'a erişim (Logout butonu her sayfada olsun istenirse)
    // final AuthController authController = Get.find<AuthController>(); // Her seferinde bulmak yerine binding ile yönetmek daha iyi

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions, // Dışarıdan gelen action'ları kullan
      ),
      body: Center( // İçeriği yatayda ortala
        child: ConstrainedBox( // İçeriğin maksimum genişliğini sınırla
          constraints: const BoxConstraints(maxWidth: 1200), // Maksimum genişlik
          // *** DEĞİŞİKLİK: Padding eklendi ***
          child: Padding(
            // Yatayda (sağ ve sol) boşluk ekleyelim
            padding: const EdgeInsets.symmetric(horizontal: 64.0), // 16.0 iyi bir başlangıç, ayarlayabilirsiniz
            child: body, // Asıl içerik artık Padding içinde
          ),
        ),
      ),
      floatingActionButton: floatingActionButton, // Varsa FAB'ı göster
      // İsteğe bağlı Footer eklenebilir:
      // bottomNavigationBar: Container(
      //   height: 50,
      //   color: Theme.of(context).colorScheme.surfaceVariant, // Veya başka bir renk
      //   child: Center(child: Text("© 2025 Ekşi Clone", style: Theme.of(context).textTheme.bodySmall)),
      // ),
    );
  }
}