import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'campus_coins_screen.dart';
import 'payment_flow_screen.dart';
import 'soundbox_screen.dart';
import 'student_home_screen.dart';
import 'token_vault_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    StudentHomeScreen(),
    PaymentFlowScreen(),
    SoundBoxScreen(),
    TokenVaultScreen(),
    CampusCoinsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderStroke, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.volume_up_rounded),
              label: 'Airgap Pay',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.speaker_rounded),
              label: 'SoundBox',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.key_rounded),
              label: 'Tokens',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.stars_rounded),
              label: 'Coins',
            ),
          ],
        ),
      ),
    );
  }
}
