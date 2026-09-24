import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'services/websocket_service.dart';
import 'screens/cart_screen.dart';
import 'screens/forget_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize ApiConfig asynchronously
  ApiConfig.init();
  // Initialize Realtime WebSocket Connection for immediate data updates without refresh
  VexaWebSocketService().connect();
  runApp(const VexaMobileApp());
}

class VexaMobileApp extends StatelessWidget {
  const VexaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VEXA Style Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forget': (context) => const ForgetPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartScreen(cartItems: []),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
