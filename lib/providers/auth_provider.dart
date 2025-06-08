import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// Kimlik doğrulama yönetimi provider sınıfı
class AuthProvider extends ChangeNotifier {
  // Kimlik doğrulama durumu değişkenleri
  bool _isAuthenticated = false;   // Kimlik doğrulama durumu
  bool _isLoading = false;         // Yükleme durumu
  String? _token;                  // Kimlik doğrulama token'ı
  Map<String, dynamic>? _user;     // Kullanıcı bilgileri

  // Getter metodları
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  // Constructor - kimlik doğrulama durumunu yükle
  AuthProvider() {
    _loadAuthState();
  }

  // Kimlik doğrulama durumunu yerel depolamadan yükle
  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_data');
      
      if (_token != null && userJson != null) {
        _isAuthenticated = true;
        // Gerekirse JSON'dan kullanıcı verilerini ayrıştır
      }
    } catch (e) {
      debugPrint('Error loading auth state: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Kullanıcı girişi
  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user'];
        _isAuthenticated = true;
        print('Login başarılı: isAuthenticated=$_isAuthenticated, user=$_user');

        // Kimlik doğrulama bilgilerini yerel depolamaya kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(_user));
        if (_user?['id'] != null) {
          await prefs.setInt('userId', _user!['id']);
        }

        _isLoading = false;
        notifyListeners();
        return null; // Başarılı
      } else {
        final data = jsonDecode(response.body);
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return data['message'] ?? 'Giriş başarısız';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Login error: $e');
      return 'Bir hata oluştu';
    }
  }

  // Kullanıcı kaydı
  Future<String?> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user'];
        _isAuthenticated = true;
        print('Register başarılı: isAuthenticated=$_isAuthenticated, user=$_user');

        // Kimlik doğrulama bilgilerini yerel depolamaya kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(_user));

        _isLoading = false;
        notifyListeners();
        return null; // Başarılı
      } else {
        final data = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return data['message'] ?? 'Kayıt başarısız';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Registration error: $e');
      return 'Bir hata oluştu';
    }
  }

  // Kullanıcı çıkışı
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Kimlik doğrulama bilgilerini yerel depolamadan sil
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');

      _token = null;
      _user = null;
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Şifre değiştirme
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.changePasswordUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return null; // Başarılı
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Şifre güncellenemedi';
      }
    } catch (e) {
      return 'Bir hata oluştu: $e';
    }
  }
} 