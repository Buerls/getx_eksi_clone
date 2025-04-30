// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/api_service.dart'; // ApiService'i import et
import '../routes/app_routes.dart'; // Rota isimleri için

class AuthController extends GetxController {
  // ApiService'i GetX Dependency Management ile buluyoruz (AppBinding'de put edilmişti)
  final ApiService _apiService = Get.find<ApiService>();

  // --- State Değişkenleri ---
  // Reaktif değişkenler (.obs kullanarak)
  final RxBool isLoading = false.obs; // Yüklenme durumu
  final RxBool isAuthenticated = false.obs; // Giriş yapıldı mı?
  final RxnString errorMessage = RxnString(); // Hata mesajı (nullable RxString)
  // final Rxn<User> user = Rxn<User>(); // Kullanıcı bilgisi (gerekirse eklenebilir)

  // --- Lifecycle Metotları ---
  @override
  void onInit() {
    super.onInit();
    // Controller ilk yüklendiğinde kullanıcının mevcut giriş durumunu kontrol et
    checkAuthStatus();
  }

  // --- Ana Metotlar ---

  // Başlangıçta veya uygulama açıldığında token kontrolü
  Future<void> checkAuthStatus() async {
    isLoading(true);
    errorMessage(null); // Hata mesajını temizle
    try {
      final token = await _apiService.getAccessToken();
      if (token != null) {
        // Token var, kullanıcıyı giriş yapmış kabul et.
        // İSTEĞE BAĞLI: Burada token'ı doğrulamak için API'ye ek bir istek atılabilir (/api/user/me gibi?)
        // Eğer doğrulama başarısız olursa logout() çağrılabilir.
        isAuthenticated(true);
        print("Auth check: User is authenticated.");
      } else {
        isAuthenticated(false);
        print("Auth check: User is not authenticated.");
      }
    } catch (e) {
      print("Auth check failed: $e");
      isAuthenticated(false);
      errorMessage("Failed to check authentication status.");
    } finally {
      isLoading(false);
    }
  }

  // Giriş Yapma
  Future<void> login(String username, String password) async {
    isLoading(true);
    errorMessage(null);
    try {
      await _apiService.login(username, password); // ApiService login'i çağır
      isAuthenticated(true); // State'i güncelle
      print("Login successful via AuthController.");
      // Başarılı giriş sonrası ana ekrana yönlendir ve önceki tüm sayfaları kapat
      Get.offAllNamed(AppRoutes.HOME);
    } catch (e) {
      print("Login failed via AuthController: $e");
      isAuthenticated(false); // State'i güncelle
      errorMessage(e.toString().replaceFirst('Exception: ', '')); // Hata mesajını ayarla
    } finally {
      isLoading(false); // Yüklenme durumunu bitir
    }
  }

  // Kayıt Olma
  Future<bool> register({ // Başarı durumunu bool olarak döndürelim
    required String username, required String email,
    required String password, required String password2,
    String? firstName, String? lastName,
  }) async {
    isLoading(true);
    errorMessage(null);
    try {
      await _apiService.register( // ApiService register'ı çağır
        username: username, email: email,
        password: password, password2: password2,
        firstName: firstName, lastName: lastName,
      );
      print("Registration successful via AuthController.");
      // Başarılı kayıt sonrası kullanıcıya bilgi ver ve login ekranına yönlendir (veya otomatik login yap)
      Get.snackbar(
        'Success',
        'Registration successful! Please login.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // Otomatik login istenmiyorsa, sadece bir önceki sayfaya (muhtemelen login) dönelim
      // Eğer Register ekranı Login'den açıldıysa Get.back() yeterli.
      // Eğer direkt Register açıldıysa Login'e yönlendirme gerekebilir: Get.offNamed(AppRoutes.LOGIN);
      // Şimdilik Get.back() varsayalım.
      isLoading(false); // Snackbar sonrası loading'i kapat
      return true;
    } catch (e) {
      print("Registration failed via AuthController: $e");
      errorMessage(e.toString().replaceFirst('Exception: ', '')); // Hata mesajını ayarla
      isLoading(false);
      return false;
    }
    // Finally bloğu burada şart değil, try/catch içinde isLoading(false) yapıldı.
  }

  // Çıkış Yapma
  Future<void> logout() async {
    isLoading(true);
    errorMessage(null);
    try {
      await _apiService.clearTokens(); // Tokenları sil
      isAuthenticated(false); // State'i güncelle
      // user(null); // Kullanıcı bilgisi varsa temizle
      print("Logout successful via AuthController.");
      // Login ekranına yönlendir ve geçmişi temizle
      Get.offAllNamed(AppRoutes.LOGIN);
    } catch (e) {
      print("Logout failed via AuthController: $e");
      // Hata olsa bile çıkış yapmış kabul edelim
      isAuthenticated(false);
      // user(null);
      errorMessage("Logout failed: $e");
      // Yine de login ekranına yönlendirebiliriz
      Get.offAllNamed(AppRoutes.LOGIN);
    } finally {
      isLoading(false);
    }
  }
}