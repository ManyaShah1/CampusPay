import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'ui/screens/main_navigation_screen.dart';
import 'ui/viewmodels/p2p_viewmodel.dart';
import 'ui/viewmodels/payment_viewmodel.dart';
import 'ui/viewmodels/soundbox_viewmodel.dart';
import 'ui/viewmodels/wallet_viewmodel.dart';
import 'ui/viewmodels/ussd_viewmodel.dart';

import 'core/services/onboarding_service.dart';
import 'ui/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isOnboardingCompleted = await OnboardingService.isOnboardingCompleted();
  runApp(CampusPayApp(initialOnboardingCompleted: isOnboardingCompleted));
}

class CampusPayApp extends StatelessWidget {
  final bool initialOnboardingCompleted;

  const CampusPayApp({super.key, this.initialOnboardingCompleted = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
        ChangeNotifierProvider(create: (_) => SoundBoxViewModel()),
        ChangeNotifierProvider(create: (_) => P2pViewModel()),
        ChangeNotifierProvider(create: (_) => UssdViewModel()),
      ],
      child: MaterialApp(
        title: 'CampusPay DBIT',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: initialOnboardingCompleted
            ? const MainNavigationScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}
