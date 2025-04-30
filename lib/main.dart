// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX import
import 'package:getx_eksi_clone/screens/topic/create_topic_screen.dart';
import 'package:getx_eksi_clone/utils/theme.dart';
import 'package:intl/date_symbol_data_local.dart';

// Rota isimlerini ve Binding'leri import et
import 'bindings/create_topic_binding.dart';
import 'routes/app_routes.dart';
import 'bindings/app_binding.dart';
import 'bindings/auth_binding.dart';
import 'bindings/home_binding.dart';
import 'bindings/topic_detail_binding.dart';
import 'bindings/create_entry_binding.dart';

// Ekranları import et
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/topic_list_screen.dart';
import 'screens/home/topic_detail_screen.dart';
import 'screens/entry/create_entry_screen.dart';

Future<void> main() async { // main'i async yap
  WidgetsFlutterBinding.ensureInitialized(); // Flutter binding'lerinin hazır olduğundan emin ol
  // Türkçe lokalizasyon verisini yükle
  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp()); // GetX projesi için ProviderScope gerekmez
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ekşi Clone (GetX)',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,

      // Başlangıç Rotası
      initialRoute: AppRoutes.LOGIN, // Uygulama login ekranı ile başlasın

      // Genel Bağımlılıklar (ApiService vb.)
      initialBinding: AppBinding(),

      // Rota Tanımları
      getPages: [
        GetPage(
          name: AppRoutes.LOGIN,
          page: () => const LoginScreen(), // Ekran widget'ı
          binding: AuthBinding(), // Bu ekrana özel controller'ı yükler
        ),
        GetPage(
          name: AppRoutes.REGISTER,
          page: () => const RegisterScreen(),
          binding: AuthBinding(), // Aynı AuthController'ı kullanabilir
        ),
        GetPage(
          name: AppRoutes.HOME,
          page: () => const TopicListScreen(), // Ana ekran
          binding: HomeBinding(), // Ana ekranın controller'ını yükler
        ),

        GetPage(
          name: AppRoutes.TOPIC_DETAIL, // '/topic/:topicId'
           page: () => TopicDetailScreen(),
           binding: TopicDetailBinding(), // İlgili binding
         ),
        GetPage(
          name: AppRoutes.CREATE_ENTRY,
          page: () => const CreateEntryScreen(),
          binding: CreateEntryBinding(), // İlgili binding
        ),
        GetPage(
          name: AppRoutes.CREATE_TOPIC,
          page: () => const CreateTopicScreen(),
          binding: CreateTopicBinding(), // Yeni binding
        ),
      ],

      // Bilinmeyen rota için yönlendirme (opsiyonel)
      // unknownRoute: GetPage(name: '/notfound', page: () => UnknownRouteScreen()),
    );
  }
}