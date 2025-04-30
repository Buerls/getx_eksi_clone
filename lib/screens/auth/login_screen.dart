// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX importları
import '../../controllers/auth_controller.dart'; // AuthController'ı import et
import '../../routes/app_routes.dart'; // Rota isimleri için

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // TextEditingController'lar (State içinde yönetilir)
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  // AuthController'ı GetX'ten bul
  // Bu ekranın AuthBinding ile yüklendiğini varsayıyoruz (main.dart'ta tanımlı)
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();

    // Başlangıçta hata mesajı varsa temizle (isteğe bağlı)
    authController.errorMessage(null);
  }

  @override
  void dispose() {
    // Controller'ları temizle
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _performLogin() {
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();
    // Formu doğrula
    if (_formKey.currentState!.validate()) {
      // Controller'dan login metodunu çağır
      authController.login(
        _usernameController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true, // Başlığı ortala (web için daha estetik olabilir)
      ),
      body: Center(
        // Center ve ConstrainedBox ile formu ortalayıp genişliğini sınırlayalım (web için)
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400), // Maksimum genişlik
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Butonun genişlemesi için
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Username cannot be empty' : null,
                    // Enter'a basınca bir sonraki alana geç (opsiyonel)
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) =>
                    value!.isEmpty ? 'Password cannot be empty' : null,
                    // Enter'a basınca formu gönderme (opsiyonel)
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _performLogin(), // Enter ile login tetikle
                  ),
                  const SizedBox(height: 15),

                  // Hata Mesajı Alanı (Obx ile dinlenir)
                  Obx(() {
                    // errorMessage null değilse ve boş değilse göster
                    if (authController.errorMessage.value != null &&
                        authController.errorMessage.value!.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          authController.errorMessage.value!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else {
                      return const SizedBox.shrink(); // Hata yoksa boşluk gösterme
                    }
                  }),

                  // Login Butonu veya Yüklenme Indicator'ı (Obx ile dinlenir)
                  Obx(() {
                    return authController.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      // isLoading true ise onPressed null olur ve buton disable görünür
                      onPressed: authController.isLoading.value ? null : _performLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Login'),
                    );
                  }),

                  const SizedBox(height: 20),
                  // Kayıt Ekranına Yönlendirme Butonu
                  Obx(() { // isLoading durumuna göre disable etmek için Obx içine aldık
                    return TextButton(
                      onPressed: authController.isLoading.value ? null : () {
                        // GetX ile isimlendirilmiş rotaya git
                        Get.toNamed(AppRoutes.REGISTER);
                      },
                      child: const Text('Don\'t have an account? Register'),
                    );
                  })
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}