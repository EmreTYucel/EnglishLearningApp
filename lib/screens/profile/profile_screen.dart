import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/quiz_settings_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final quizSettingsProvider = Provider.of<QuizSettingsProvider>(context);
    final user = authProvider.user;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void changePassword() async {
      if (!formKey.currentState!.validate()) return;
      final current = currentPasswordController.text;
      final newPass = newPasswordController.text;
      final confirm = confirmPasswordController.text;
      if (newPass != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni şifreler eşleşmiyor!'), backgroundColor: Colors.red),
        );
        return;
      }
      final result = await authProvider.changePassword(current, newPass);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre başarıyla güncellendi!'), backgroundColor: Colors.green),
        );
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Ana Ekrana Dön',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user?['username']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?['username'] ?? 'Kullanıcı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user?['email'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                if (user?['createdAt'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Kayıt Tarihi: ${user?['createdAt']?.toString().split('T').first ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Tema'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (v) => themeProvider.toggleTheme(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.format_list_numbered),
            title: const Text('Quiz Soru Sayısı'),
            trailing: DropdownButton<int>(
              value: quizSettingsProvider.questionCount,
              items: const [
                DropdownMenuItem(value: 5, child: Text('5')),
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 15, child: Text('15')),
                DropdownMenuItem(value: 20, child: Text('20')),
              ],
              onChanged: (v) {
                if (v != null) quizSettingsProvider.setQuestionCount(v);
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Şifre Güncelle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
                    validator: (v) => v == null || v.isEmpty ? 'Mevcut şifreyi giriniz' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Yeni Şifre'),
                    validator: (v) => v == null || v.length < 6 ? 'En az 6 karakter olmalı' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Yeni Şifre (Tekrar)'),
                    validator: (v) => v == null || v.isEmpty ? 'Yeni şifreyi tekrar giriniz' : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: changePassword,
                      child: const Text('Şifreyi Güncelle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Çıkış Yap'),
            onTap: () {
              authProvider.logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
} 