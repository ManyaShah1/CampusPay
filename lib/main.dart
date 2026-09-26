import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'ui/screens/main_navigation_screen.dart';
import 'ui/viewmodels/p2p_viewmodel.dart';
import 'ui/viewmodels/payment_viewmodel.dart';
import 'ui/viewmodels/soundbox_viewmodel.dart';
import 'ui/viewmodels/wallet_viewmodel.dart';
import 'ui/viewmodels/ussd_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CampusPayApp());
}

class CampusPayApp extends StatelessWidget {
  const CampusPayApp({super.key});

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
        home: const MainNavigationScreen(),
      ),
    );
  }
}
