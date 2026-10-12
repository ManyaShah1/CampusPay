import 'package:flutter/material.dart';
import 'login_signup_page.dart';
import '../screens/main_navigation_screen.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback? onSuccess;

  const LoginScreen({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return LoginSignupPage(
      onSuccess: () {
        if (onSuccess != null) {
          onSuccess!();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MainNavigationScreen(startTour: false),
            ),
          );
        }
      },
    );
  }
}
