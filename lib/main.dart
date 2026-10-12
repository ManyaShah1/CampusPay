import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/ble/ble_payment_carrier.dart';
import 'core/constants/app_theme.dart';
import 'core/services/env_service.dart';
import 'core/services/onboarding_service.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/main_navigation_screen.dart';
import 'ui/auth/login_signup_page.dart';
import 'ui/viewmodels/p2p_viewmodel.dart';
import 'ui/viewmodels/payment_viewmodel.dart';
import 'ui/viewmodels/soundbox_viewmodel.dart';
import 'ui/viewmodels/wallet_viewmodel.dart';
import 'ui/viewmodels/ussd_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('[Main] Could not load .env file: $e');
  }
  await EnvService.load();

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? EnvService.supabaseUrl;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? EnvService.supabaseAnonKey;
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      debugPrint('[Main] Supabase initialized successfully');
    } catch (e) {
      debugPrint('[Main] Supabase initialization error: $e');
    }
  }

  final isOnboardingCompleted = await OnboardingService.isOnboardingCompleted();
  runApp(CampusPayApp(initialOnboardingCompleted: isOnboardingCompleted));

  if (!kIsWeb) {
    try {
      final bleCarrier = BlePaymentCarrier();
      debugPrint('[MAIN] Starting BLE initialization');
      await bleCarrier.initialize();
      debugPrint('[MAIN] BLE initialization finished');
    } catch (e) {
      debugPrint('[MAIN] BLE initialization skipped or failed: $e');
    }
  }
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
            ? const MainNavigationScreen(startTour: false)
            : const OnboardingScreen(),
      ),
    );
  }
}
