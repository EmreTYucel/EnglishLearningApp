import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:english_learning_app/providers/word_provider.dart';
import 'package:english_learning_app/providers/auth_provider.dart';
import 'package:english_learning_app/providers/statistics_provider.dart';
import 'package:english_learning_app/providers/quiz_provider.dart';
import 'package:english_learning_app/providers/quiz_settings_provider.dart';
import 'package:english_learning_app/providers/theme_provider.dart';
import 'package:english_learning_app/screens/splash_screen.dart';
import 'package:english_learning_app/screens/auth/login_screen.dart';
import 'package:english_learning_app/screens/auth/register_screen.dart';
import 'package:english_learning_app/screens/auth/forgot_password_screen.dart';
import 'package:english_learning_app/screens/home/home_screen.dart';
import 'package:english_learning_app/screens/quiz/quiz_screen.dart';
import 'package:english_learning_app/screens/statistics/statistics_screen.dart';
import 'package:english_learning_app/screens/wordle/wordle_screen.dart';
import 'package:english_learning_app/screens/word_chain/word_chain_screen.dart';
import 'package:english_learning_app/screens/profile/profile_screen.dart';
import 'package:english_learning_app/screens/words/word_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WordProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => QuizSettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'İngilizce Kelime Öğrenme',
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const SplashScreen(),
                ),
                GoRoute(
                  path: '/login',
                  builder: (context, state) => const LoginScreen(),
                ),
                GoRoute(
                  path: '/register',
                  builder: (context, state) => const RegisterScreen(),
                ),
                GoRoute(
                  path: '/forgot-password',
                  builder: (context, state) => const ForgotPasswordScreen(),
                ),
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
                GoRoute(
                  path: '/quiz',
                  builder: (context, state) => const QuizScreen(),
                ),
                GoRoute(
                  path: '/statistics',
                  builder: (context, state) => const StatisticsScreen(),
                ),
                GoRoute(
                  path: '/wordle',
                  builder: (context, state) => const WordleScreen(),
                ),
                GoRoute(
                  path: '/word-chain',
                  builder: (context, state) => const WordChainScreen(),
                ),
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
                GoRoute(
                  path: '/words',
                  builder: (context, state) => const WordListScreen(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
