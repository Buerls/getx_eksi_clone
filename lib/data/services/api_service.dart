// lib/data/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // debugPrint için

// Sabitler (constants.dart içine taşınabilir)
const String _apiBaseUrl = 'http://127.0.0.1:8000/api'; // Backend adresiniz
const String _accessTokenKey = 'access_token';
const String _refreshTokenKey = 'refresh_token';

class ApiService {
  late final Dio _dio;
  bool _isRefreshing = false; // Token yenileme işlemi sırasında tekrar tekrar denemeyi önlemek için flag

  // Bu sınıf GetX tarafından (örn: AppBinding içinde Get.put ile) oluşturulacak.
  ApiService() {
    debugPrint("ApiService Constructor Called");
    final options = BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    );
    _dio = Dio(options);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequestInterceptor,
        onError: _onErrorInterceptor,
      ),
    );
    debugPrint("ApiService Initialized with Interceptors");
  }

  // --- Token Yönetimi (SharedPreferences) ---

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      debugPrint('Tokens saved.');
    } catch (e) {
      debugPrint('Error saving tokens: $e');
    }
  }

  Future<String?> getAccessToken() async { // AuthController'ın erişebilmesi için public yaptım
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  Future<String?> _getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      debugPrint('Error getting refresh token: $e');
      return null;
    }
  }

  Future<void> clearTokens() async { // AuthController'ın erişebilmesi için public yaptım
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      debugPrint('Tokens cleared.');
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }

  // --- Interceptors ---

  Future<void> _onRequestInterceptor(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final publicPaths = ['/token/', '/register/', '/token/refresh/'];
    if (!publicPaths.contains(options.path)) {
      final accessToken = await getAccessToken(); // Public metodu kullan
      if (accessToken != null) {
        if (accessToken.startsWith('Bearer ')) {
          // Zaten varsa direkt ata
          options.headers['Authorization'] = accessToken;
          debugPrint("--> Request Interceptor: Auth Header Found (prefixed): Bearer ${accessToken.substring(7, 20)}...");
        } else {
          // Yoksa "Bearer " ekleyerek ata
          options.headers['Authorization'] = 'Bearer $accessToken';
          debugPrint("--> Request Interceptor: Auth Header Attached: Bearer ${accessToken.substring(0, 15)}...");
        }
      } else {
        debugPrint('Access token not found for protected route: ${options.path}');
      }
    } else {
      // debugPrint('Token not added for public route: ${options.path}');
    }

    final requestPath = options.path;
    final authHeader = options.headers['Authorization'];
    debugPrint("--> Request Interceptor: Path: $requestPath");
    if (authHeader != null) {
      debugPrint("--> Request Interceptor: Auth Header Attached: Bearer ${authHeader.substring(0, 15)}..."); // Token'ın başını logla
    } else {
      debugPrint("--> Request Interceptor: Auth Header NOT Attached for this request.");
    }
    handler.next(options);
  }

  Future<void> _onErrorInterceptor(
      DioException err, ErrorInterceptorHandler handler) async {
    // debugPrint('DioError Path: ${err.requestOptions.path}');
    // debugPrint('DioError Status: ${err.response?.statusCode}');

    // Token yenileme işlemi zaten devam ediyorsa veya hata 401 değilse veya refresh path'inden geliyorsa devam et
    if (_isRefreshing || err.response?.statusCode != 401 || err.requestOptions.path == '/token/refresh/') {
      debugPrint('Passing error without refresh check. IsRefreshing: $_isRefreshing, Status: ${err.response?.statusCode}, Path: ${err.requestOptions.path}');
      return handler.next(err); // Hatanın normal akışta devam etmesini sağla
    }

    _isRefreshing = true; // Yenileme işlemi başladı
    debugPrint('Attempting to refresh token...');
    final refreshToken = await _getRefreshToken();

    if (refreshToken == null) {
      debugPrint('No refresh token found. Clearing tokens.');
      await clearTokens(); // Refresh token yoksa çıkış yap
      _isRefreshing = false;
      // Hata olarak devam et, Controller hatayı yakalayıp logout tetiklemeli
      return handler.next(err);
    }

    try {
      // Yeni token almak için refresh endpoint'ini çağır (yeni Dio instance ile)
      final Dio refreshDio = Dio(BaseOptions(baseUrl: _apiBaseUrl));
      final response = await refreshDio.post(
        '/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        // Yeni token'ı kaydet (refresh token değişmediyse sadece access yeterli)
        await _saveTokens(newAccessToken, refreshToken);
        debugPrint('Token refreshed successfully.');

        // Başarısız olan orijinal isteği yeni token ile tekrar dene
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newAccessToken';
        debugPrint('Retrying the original request with new token...');

        // İsteği tekrar gönder
        final retryResponse = await _dio.fetch(options);
        debugPrint('Original request retried successfully.');
        _isRefreshing = false;
        // Orijinal isteğin yerine bu başarılı yanıtı döndür
        return handler.resolve(retryResponse);
      } else {
        // Refresh endpoint'i 200 döndürmedi (beklenmedik durum)
        throw DioException(requestOptions: response.requestOptions, response: response, message: "Refresh endpoint did not return 200");
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e. Clearing tokens.');
      await clearTokens(); // Başarısız olursa tokenları temizle (logout)
      _isRefreshing = false;
      // Hata olarak devam et, Controller hatayı yakalayıp logout tetiklemeli
      return handler.next(DioException(
          requestOptions: err.requestOptions,
          error: e,
          message: "Token refresh failed, logged out.",
          response: err.response // Orijinal 401 yanıtını koruyabiliriz
      ));
    }
  }


  // --- API Metotları ---

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/token/',
        data: {'username': username, 'password': password},
      );
      // Başarılı yanıt kontrolü (status code vs.) dio interceptor'ları tarafından
      // otomatik olarak yapılır, 2xx dışı durumlar DioException fırlatır.
      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];
      await _saveTokens(accessToken, refreshToken);
      debugPrint('Login successful via ApiService.');
      return response.data; // Tokenları içeren yanıtı döndür
    } on DioException catch (e) {
      debugPrint('Login failed via ApiService: ${e.response?.data ?? e.message}');
      throw Exception('Login failed: ${e.response?.data?['detail'] ?? 'Invalid credentials or server error'}');
    } catch (e) {
      debugPrint('Login failed via ApiService (unexpected): $e');
      throw Exception('An unexpected error occurred during login.');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username, required String email,
    required String password, required String password2,
    String? firstName, String? lastName,
  }) async {
    try {
      final response = await _dio.post(
        '/register/',
        data: {
          'username': username, 'email': email, 'password': password, 'password2': password2,
          if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
          if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        },
      );
      // 201 Created beklenir
      debugPrint('Registration successful via ApiService.');
      return response.data; // Oluşturulan kullanıcı bilgisini (veya API'nin döndürdüğünü) dön
    } on DioException catch (e) {
      debugPrint('Registration failed via ApiService: ${e.response?.data ?? e.message}');
      String errorMessage = 'Registration failed.';
      if (e.response?.data is Map) {
        errorMessage = e.response!.data.entries.map((entry) {
          final value = entry.value;
          // Gelen hata listesini birleştir
          final message = (value is List) ? value.join(', ') : value.toString();
          return '${entry.key}: $message';
        }).join('\n');
      } else if (e.response?.data?['detail'] != null) {
        errorMessage = e.response!.data['detail'];
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Registration failed via ApiService (unexpected): $e');
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  // --- Diğer API Metotları (Örnekler) ---

  Future<Response> getTopics({int page = 1, String? searchQuery}) async { // searchQuery parametresi eklendi
    try {
      // Query parametrelerini dinamik olarak oluştur
      final Map<String, dynamic> queryParams = {
        'page': page,
      };
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery; // Arama parametresini ekle
      }
      debugPrint("4. ApiService fetching topics with params: $queryParams");
      debugPrint("Fetching topics with params: $queryParams"); // Log eklendi
      final response = await _dio.get(
          '/topics/',
          queryParameters: queryParams // Güncellenmiş parametreler
      );
      return response;
    } on DioException catch (e) {
      debugPrint('Failed to get topics: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load topics: ${e.response?.data?['detail'] ?? e.message}');
    } catch (e) {
      debugPrint('Failed to get topics (unexpected): $e');
      throw Exception('An unexpected error occurred while fetching topics.');
    }
  }


  Future<Response> getTopicDetail(int topicId) async {
    try {
      // GET /api/topics/{topicId}/ endpoint'ine istek at
      final response = await _dio.get('/topics/$topicId/');
      debugPrint('Topic detail ($topicId) fetched successfully.');
      return response; // Ham Response nesnesini döndür
    } on DioException catch (e) {
      debugPrint('Failed to get topic detail ($topicId): ${e.response?.data ?? e.message}');
      // Controller'ın yakalaması için hatayı yeniden fırlat
      throw Exception('Failed to load topic detail: ${e.response?.data?['detail'] ?? e.message}');
    } catch (e) {
      debugPrint('Failed to get topic detail ($topicId) (unexpected): $e');
      throw Exception('An unexpected error occurred while fetching topic detail.');
    }
  }


  Future<Response> getEntriesForTopic(int topicId, {int page = 1}) async {
    return _dio.get('/entries/', queryParameters: {'topic': topicId, 'page': page});
  }

  // createEntry, vote, favorite, follow... metotları eklenecek
  // Örnek:
  Future<Response> createTopic({required String title, required String firstEntryContent}) async { // content parametresi eklendi
    try {
      // POST /api/topics/ endpoint'ine istek at
      final response = await _dio.post(
        '/topics/',
        data: {
          'title': title,
          'first_entry_content_input': firstEntryContent, // Backend'deki serializer alan adı
        },
      );
      debugPrint('Topic "$title" created successfully with first entry.');
      // Backend muhtemelen oluşturulan Topic nesnesini döndürür
      return response;
    } on DioException catch (e) {
      debugPrint('Failed to create topic "$title": ${e.response?.data ?? e.message}');
      throw Exception('Failed to create topic: ${e.response?.data?['detail'] ?? e.message}');
    } catch (e) {
      debugPrint('Failed to create topic (unexpected): $e');
      throw Exception('An unexpected error occurred while creating the topic.');
    }
  }

  Future<Response> createEntry({required int topicId, required String content}) async {
    try {
      // POST /api/entries/ endpoint'ine istek at
      // Interceptor giriş yapmış kullanıcının token'ını otomatik ekleyecektir.
      final response = await _dio.post(
        '/entries/',
        data: {
          'topic': topicId,   // Hangi başlığa ait olduğu
          'content': content, // Entry içeriği
        },
      );
      debugPrint("--> ApiService.createEntry: Sending data: $response");
      debugPrint('Entry created successfully for topic $topicId.');
      return response; // Başarılı yanıtı döndür (oluşturulan entry'i içerir)
    } on DioException catch (e) {
      debugPrint('Failed to create entry for topic $topicId: ${e.response?.data ?? e.message}');
      throw Exception('Failed to create entry: ${e.response?.data?['detail'] ?? e.message}');
    } catch (e) {
      debugPrint('Failed to create entry (unexpected): $e');
      throw Exception('An unexpected error occurred while creating the entry.');
    }
  }

  Future<Response> voteEntry(int entryId, int voteType) async {
    // voteType: 1 (upvote), -1 (downvote)
    try {
      final response = await _dio.post(
        '/entries/$entryId/vote/', // Backend endpoint'inizin bu olduğunu varsayıyoruz
        data: {'vote_type': voteType},
      );
      debugPrint('Vote ($voteType) successful for entry $entryId.');
      return response; // Backend güncel entry veya sadece success dönebilir
    } on DioException catch (e) {
      debugPrint('Failed to vote ($voteType) for entry $entryId: ${e.response?.data ?? e.message}');
      throw Exception('Failed to submit vote: ${e.response?.data?['detail'] ?? e.message}');
    } catch (e) {
      debugPrint('Failed to vote (unexpected): $e');
      throw Exception('An unexpected error occurred while voting.');
    }
  }

  Future<Response> removeVote(int entryId) async {
    try {
      // DELETE /api/entries/{entry_id}/vote/ endpoint'ini varsayıyoruz
      final response = await _dio.delete('/entries/$entryId/vote/');
      debugPrint('Vote removed successfully for entry $entryId.');
      return response;
    } on DioException catch (e) {
      debugPrint('Failed to remove vote for entry $entryId: ${e.response?.data ?? e.message}');
      throw Exception('Failed to remove vote: ${e.response?.data?['detail'] ?? e.message}');
    } catch (e) {
      debugPrint('Failed to remove vote (unexpected): $e');
      throw Exception('An unexpected error occurred while removing vote.');
    }
  }

  Future<Response> getPopularTopics() async {
    // Backend endpoint'inin '/topics/popular-today/' olduğunu varsayıyoruz
    // (views.py'daki @action'da url_path='popular-today' belirlemiştik)
    try {
      final response = await _dio.get('/topics/popular-today/');
      debugPrint('Popular topics fetched successfully.');
      return response; // Backend listeyi doğrudan döndürüyor olmalı
    } on DioException catch (e) {
      debugPrint('Failed to get popular topics: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load popular topics: ${e.response?.data?['detail'] ?? e.message}');
    } catch (e) {
      debugPrint('Failed to get popular topics (unexpected): $e');
      throw Exception('An unexpected error occurred while fetching popular topics.');
    }
  }


}