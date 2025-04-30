// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX importları
import '../../controllers/auth_controller.dart'; // AuthController'ı import et
import '../../routes/app_routes.dart'; // Rota isimleri (gerçi burada sadece Get.back kullanacağız)

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // TextEditingController'lar
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _password2Controller;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  // AuthController'ı bul
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _password2Controller = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();

    // Ekrana girildiğinde önceki hata mesajını temizle (isteğe bağlı)
    authController.errorMessage(null);
  }

  @override
  void dispose() {
    // Controller'ları temizle
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // Kayıt işlemini gerçekleştiren metot
  Future<void> _performRegister() async {
    FocusScope.of(context).unfocus(); // Klavyeyi kapat
    if (_formKey.currentState!.validate()) {
      // Controller'dan register metodunu çağır (await ile sonucunu bekle)
      final success = await authController.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        password2: _password2Controller.text,
        // Boşsa null gönder, değilse text'i gönder
        firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
      );

      // Eğer kayıt başarılıysa ve widget hala ekrandaysa, bir önceki sayfaya dön
      if (success && mounted) {
        // Başarı mesajı zaten controller tarafından Snackbar ile gösteriliyor.
        Get.back(); // Login ekranına geri dön
      }
      // Başarısızsa, hata mesajı zaten Obx tarafından gösterilecek.
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      // Klavye açıldığında taşmayı önlemek için ListView veya SingleChildScrollView
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView( // Kaydırma ekledik
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isEmpty) return 'Email cannot be empty';
                      // Basit email format kontrolü
                      if (!GetUtils.isEmail(value)) return 'Please enter a valid email';
                      return null;
                    },
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
                    validator: (value) {
                      if (value!.isEmpty) return 'Password cannot be empty';
                      // İsteğe bağlı: Daha güçlü şifre kontrolü eklenebilir
                      // if (value.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _password2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value!.isEmpty) return 'Please confirm password';
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name (Optional)',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name (Optional)',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _performRegister(), // Enter ile register tetikle
                  ),
                  const SizedBox(height: 15),

                  // Hata Mesajı Alanı
                  Obx(() {
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
                      return const SizedBox.shrink();
                    }
                  }),

                  // Register Butonu veya Yüklenme Indicator'ı
                  Obx(() {
                    return authController.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: authController.isLoading.value ? null : _performRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Register'),
                    );
                  }),

                  const SizedBox(height: 20),
                  // Login Ekranına Yönlendirme Butonu
                  Obx(() {
                    return TextButton(
                      onPressed: authController.isLoading.value ? null : () {
                        // Bir önceki ekrana (Login) dön
                        Get.back();
                      },
                      child: const Text('Already have an account? Login'),
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