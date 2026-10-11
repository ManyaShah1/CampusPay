// lib/login_signup_page.dart
// NO extra package needed. Authentication abhi nahi hai - sirf UI + dummy login.
// Baad me sirf AuthService class ke andar real authentication lagani hai.

import 'dart:math' as math;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------
// COLORS
// ---------------------------------------------------------------
class AppColors {
  static const purple = Color(0xFF6A1B9A);
  static const purpleLight = Color(0xFFF3E5F5);
  static const yellow = Color(0xFFFFC107);
  static const white = Colors.white;
}

// ---------------------------------------------------------------
// AUTH SERVICE (dummy)
// Baad me yahin Firebase / API wala code daalna hai.
// Baaki poori UI ko change karne ki zarurat nahi padegi.
// ---------------------------------------------------------------
class AppUser {
  final String name;
  final String email;
  const AppUser({required this.name, required this.email});
}

class AuthService {
  /// Current logged-in user. null = logged out.
  static final ValueNotifier<AppUser?> currentUser = ValueNotifier(null);

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    // TODO: real authentication yahan lagao
    await Future.delayed(const Duration(milliseconds: 800)); // fake loading
    currentUser.value = AppUser(name: email.split('@').first, email: email);
  }

  static Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // TODO: real authentication yahan lagao
    await Future.delayed(const Duration(milliseconds: 800)); // fake loading
    currentUser.value = AppUser(name: name, email: email);
  }

  static Future<void> forgotPassword(String email) async {
    // TODO: real forgot password yahan lagao
    await Future.delayed(const Duration(milliseconds: 500));
  }

  static void logout() {
    // TODO: real logout yahan lagao
    currentUser.value = null;
  }
}

// ---------------------------------------------------------------
// LOGIN / SIGNUP PAGE
// ---------------------------------------------------------------
class LoginSignupPage extends StatefulWidget {
  /// Login/signup ke baad kahan jana hai (e.g. HomePage)
  final VoidCallback onSuccess;
  const LoginSignupPage({super.key, required this.onSuccess});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _hidePass = true;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    if (_isLogin) {
      await AuthService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
    } else {
      await AuthService.signUp(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);
    widget.onSuccess();
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Please enter your email first.');
      return;
    }
    await AuthService.forgotPassword(email);
    _snack('Password reset link sent (demo).');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.purple),
    );
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.purple),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.purpleLight.withOpacity(0.5),
      labelStyle: const TextStyle(color: AppColors.purple),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.yellow, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: _AnimatedBackground(animation: _bgController),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.93),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.purple, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.purple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 48, color: AppColors.yellow),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isLogin ? 'Welcome Back!' : 'Create Account',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isLogin ? 'Log in to your account' : 'Create a new account',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 28),

                          // Login / Signup toggle
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.purpleLight,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                _toggleButton('Login', _isLogin, () => setState(() => _isLogin = true)),
                                _toggleButton('Sign Up', !_isLogin, () => setState(() => _isLogin = false)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: _decoration('Full Name', Icons.person_outline),
                              validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _decoration('Email', Icons.email_outlined),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter your email';
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _hidePass,
                            decoration: _decoration(
                              'Password',
                              Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _hidePass ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.purple,
                                ),
                                onPressed: () => setState(() => _hidePass = !_hidePass),
                              ),
                            ),
                            validator: (v) =>
                            (v == null || v.length < 6) ? 'At least 6 characters' : null,
                          ),

                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: const Text('Forgot Password?',
                                    style: TextStyle(color: AppColors.purple)),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Main button: yellow with purple text
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.yellow,
                                foregroundColor: AppColors.purple,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.purple,
                                ),
                              )
                                  : Text(
                                _isLogin ? 'LOGIN' : 'SIGN UP',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_isLogin ? "Don't have an account?" : 'Already have an account?'),
                              TextButton(
                                onPressed: () => setState(() => _isLogin = !_isLogin),
                                child: Text(
                                  _isLogin ? 'Sign Up' : 'Login',
                                  style: const TextStyle(
                                    color: AppColors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.purple : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.yellow : AppColors.purple,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// PROFILE PAGE SECTION
// Logged out -> "Login / Sign Up" button
// Logged in  -> naam, email aur Logout button
// ---------------------------------------------------------------
class ProfileAuthSection extends StatelessWidget {
  const ProfileAuthSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: AuthService.currentUser,
      builder: (context, user, _) {
        if (user == null) {
          return Card(
            color: AppColors.purpleLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.account_circle, size: 64, color: AppColors.purple),
                  const SizedBox(height: 8),
                  const Text(
                    'You are not logged in',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: AppColors.purple,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginSignupPage(
                              onSuccess: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Login / Sign Up',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          color: AppColors.purpleLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.purple,
                  child: Text(
                    (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
                    style: const TextStyle(fontSize: 28, color: AppColors.yellow),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.purple,
                  ),
                ),
                Text(user.email),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.purple,
                    side: const BorderSide(color: AppColors.purple),
                  ),
                  onPressed: AuthService.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


// ---------------------------------------------------------------
// MOVING BACKGROUND (floating purple & yellow bubbles on white)
// ---------------------------------------------------------------
class _AnimatedBackground extends StatelessWidget {
  final Animation<double> animation;
  const _AnimatedBackground({required this.animation});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BubblesPainter(animation),
        size: Size.infinite,
      ),
    );
  }
}

class _Bubble {
  final double x; // base position (0..1)
  final double y;
  final double radius;
  final double phase; // 0..1
  final int speed; // whole number => seamless loop
  final Color color;
  const _Bubble(this.x, this.y, this.radius, this.phase, this.speed, this.color);
}

class _BubblesPainter extends CustomPainter {
  final Animation<double> animation;
  _BubblesPainter(this.animation) : super(repaint: animation);

  static final List<_Bubble> _bubbles = [
    _Bubble(0.10, 0.12, 90, 0.00, 1, AppColors.purple.withOpacity(0.14)),
    _Bubble(0.88, 0.10, 60, 0.30, 2, AppColors.yellow.withOpacity(0.35)),
    _Bubble(0.80, 0.35, 110, 0.55, 1, AppColors.purple.withOpacity(0.10)),
    _Bubble(0.06, 0.48, 55, 0.80, 2, AppColors.yellow.withOpacity(0.30)),
    _Bubble(0.22, 0.85, 100, 0.20, 1, AppColors.yellow.withOpacity(0.28)),
    _Bubble(0.90, 0.80, 80, 0.65, 2, AppColors.purple.withOpacity(0.14)),
    _Bubble(0.55, 0.05, 40, 0.45, 2, AppColors.purple.withOpacity(0.12)),
    _Bubble(0.50, 0.95, 50, 0.90, 1, AppColors.purple.withOpacity(0.10)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final b in _bubbles) {
      final angle = 2 * math.pi * (t * b.speed + b.phase);
      final dx = (b.x + 0.05 * math.sin(angle)) * size.width;
      final dy = (b.y + 0.05 * math.cos(angle)) * size.height;
      canvas.drawCircle(Offset(dx, dy), b.radius, Paint()..color = b.color);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => false;
}
// ---------------------------------------------------------------
// PROFILE PAGE BUTTON
// Logged out -> "Login / Sign Up"  |  Logged in -> "Logout"
// ---------------------------------------------------------------
class ProfileAuthButton extends StatelessWidget {
  const ProfileAuthButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: AuthService.currentUser,
      builder: (context, user, _) {
        final loggedIn = user != null;
        return OutlinedButton.icon(
          onPressed: () {
            if (loggedIn) {
              AuthService.logout();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginSignupPage(
                    onSuccess: () => Navigator.pop(context),
                  ),
                ),
              );
            }
          },
          icon: Icon(
            loggedIn ? Icons.logout_rounded : Icons.login_rounded,
            size: 16,
          ),
          label: Text(
            loggedIn ? 'Logout' : 'Login / Sign Up',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70, width: 1.5),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
        );
      },
    );
  }
}