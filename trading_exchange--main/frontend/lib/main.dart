import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ApexExchangeApp());
}

class ApexExchangeApp extends StatefulWidget {
  const ApexExchangeApp({super.key});

  @override
  State<ApexExchangeApp> createState() => _ApexExchangeAppState();
}

class _ApexExchangeAppState extends State<ApexExchangeApp> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        return MaterialApp(
          title: 'Apex Trading Exchange',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0B0E14),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00C087),
              secondary: Color(0xFF2962FF),
              surface: Color(0xFF131722),
              error: Color(0xFFF6465D),
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF131722),
              indicatorColor: const Color(0xFF00C087).withValues(alpha: 0.18),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    color: Color(0xFF00C087),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                }
                return const TextStyle(
                  color: Color(0xFF848E9C),
                  fontSize: 11,
                );
              }),
            ),
          ),
          // If logged in -> redirected to actual app; otherwise AuthScreen
          home: _auth.isLoggedIn
              ? MainNavigationScreen(auth: _auth)
              : AuthScreen(auth: _auth),
        );
      },
    );
  }
}
