import 'package:flutter/material.dart';
import 'login_signup_page.dart';
import '../screens/main_navigation_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginSignupPage(
      onSuccess: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(startTour: true),
          ),
        );
      },
    );
  }
}
