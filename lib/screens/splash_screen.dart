import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:english_learning_app/providers/auth_provider.dart';

// Açılış ekranı widget'ı
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  // Sonraki ekrana yönlendirme
  Future<void> _navigateToNextScreen() async {
    // 2 saniye bekle
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Kullanıcının oturum durumunu kontrol et
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      // Oturum açıksa ana sayfaya yönlendir
      if (mounted) {
        context.go('/home');
      }
    } else {
      // Oturum açık değilse giriş sayfasına yönlendir
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Uygulama logosu
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.school,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Uygulama başlığı
            const Text(
              'İngilizce Kelime Öğrenme',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Yükleme göstergesi
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 