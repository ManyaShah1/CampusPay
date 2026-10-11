// lib/login_signup_page.dart
// NO extra package needed. NO image / asset needed.
// Background (CampusPay wala look) poora code se draw hota hai (CustomPainter).
// Authentication abhi nahi hai - sirf UI + dummy login.
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

class _LoginSignupPageState extends State<LoginSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _hidePass = true;

  @override
  void dispose() {
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
          // ---- CampusPay style background (code se bana, no image) ----
          const Positioned.fill(child: _CampusBackground()),
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

                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(_isLogin ? "Don't have an account? " : 'Already have an account? '),
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

// ---------------------------------------------------------------
// CAMPUSPAY BACKGROUND (poora CustomPainter se bana, koi image nahi)
// Corners me purple/yellow blobs aur side me payment doodles (QR, card, coins, NFC, cap, heart...).
// ---------------------------------------------------------------
class _CampusBackground extends StatelessWidget {
  const _CampusBackground();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _CampusBgPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _CampusBgPainter extends CustomPainter {
  const _CampusBgPainter();

  static const _bg = Color(0xFFFCFBFF);
  static const _violet = Color(0xFF5B3FD0);
  static const _violetMid = Color(0xFF7C5CF0);
  static const _lavender = Color(0xFFEDE7FB);
  static const _cloud = Color(0xFFF0EBFC);
  static const _yellow = Color(0xFFFFC107);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 900x1600 design ko screen ke hisaab se scale karte hain
    final k = math.min(w / 900, h / 1600);

    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);
    _clouds(canvas, w, h, k);
    _corners(canvas, w, h, k);
    _doodles(canvas, w, h, k);
  }

  // ---------- helpers ----------
  Paint _stroke(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _fill(Color c) => Paint()..color = c;

  void _at(Canvas c, double x, double y, double k, double rot, VoidCallback draw) {
    c.save();
    c.translate(x, y);
    c.rotate(rot);
    c.scale(k);
    draw();
    c.restore();
  }

  void _dashed(Canvas c, Path p, Paint paint, {double dash = 8, double gap = 7}) {
    for (final m in p.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        c.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
        d += dash + gap;
      }
    }
  }

  void _text(Canvas c, String s, TextStyle style, Offset center) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// Chhoti yellow "spark" lines, origin ke around
  void _sparks(Canvas c, List<double> angles, double r1, double r2) {
    final p = _stroke(_yellow, 4);
    for (final a in angles) {
      c.drawLine(
        Offset(math.cos(a) * r1, math.sin(a) * r1),
        Offset(math.cos(a) * r2, math.sin(a) * r2),
        p,
      );
    }
  }

  // ---------- clouds ----------
  void _clouds(Canvas canvas, double w, double h, double k) {
    final p = _fill(_cloud);
    void cloud(double cx, double cy, double r) {
      canvas.drawCircle(Offset(cx, cy), r * k, p);
      canvas.drawCircle(Offset(cx + r * 0.9 * k, cy + r * 0.2 * k), r * 0.75 * k, p);
      canvas.drawCircle(Offset(cx - r * 0.9 * k, cy + r * 0.3 * k), r * 0.7 * k, p);
    }

    cloud(w * 0.97, h * 0.585, 55);
    cloud(20 * k, h * 0.48, 45);
    cloud(w * 0.93, h * 0.77, 95);
    cloud(w * 0.05, h * 0.80, 110);
  }

  // ---------- corner blobs ----------
  void _corners(Canvas canvas, double w, double h, double k) {
    // top-left
    canvas.save();
    canvas.scale(k);
    final tlLight = Path()
      ..moveTo(0, 0)
      ..lineTo(300, 0)
      ..cubicTo(280, 70, 190, 100, 110, 150)
      ..cubicTo(60, 185, 40, 250, 0, 350)
      ..close();
    canvas.drawPath(tlLight, _fill(_lavender));
    final tlMid = Path()
      ..moveTo(0, 0)
      ..lineTo(260, 0)
      ..cubicTo(240, 55, 160, 85, 95, 125)
      ..cubicTo(50, 160, 25, 215, 0, 285)
      ..close();
    canvas.drawPath(tlMid, _fill(_violetMid));
    final tlDark = Path()
      ..moveTo(0, 0)
      ..lineTo(190, 0)
      ..cubicTo(170, 60, 110, 110, 60, 170)
      ..cubicTo(40, 200, 20, 235, 0, 265)
      ..close();
    canvas.drawPath(tlDark, _fill(_violet));
    final tlLine = Path()
      ..moveTo(0, 185)
      ..cubicTo(120, 150, 240, 110, 305, 5);
    canvas.drawPath(tlLine, _stroke(_yellow, 5));
    canvas.restore();

    // bottom-left
    canvas.save();
    canvas.translate(0, h);
    canvas.scale(k);
    final blYellow = Path()
      ..moveTo(0, -175)
      ..cubicTo(130, -170, 260, -95, 365, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(blYellow, _fill(_yellow));
    final blPurple = Path()
      ..moveTo(0, -150)
      ..cubicTo(120, -145, 235, -75, 335, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(blPurple, _fill(_violet));
    canvas.restore();

    // bottom-right
    canvas.save();
    canvas.translate(w, h);
    canvas.scale(k);
    final brYellow = Path()
      ..moveTo(0, -185)
      ..cubicTo(-60, -120, -170, -80, -320, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(brYellow, _fill(_yellow));
    final brLine = Path()
      ..moveTo(0, -120)
      ..cubicTo(-110, -88, -230, -40, -300, 0);
    canvas.drawPath(brLine, _stroke(_violet, 4));
    canvas.restore();
  }

  // ---------- doodles ----------
  void _doodles(Canvas canvas, double w, double h, double k) {
    final xl = math.max(75 * k, w * 0.11);
    final xr = w - math.max(75 * k, w * 0.11);
    final v = _stroke(_violet, 4);

    // --- LEFT ---
    // paper plane + dashed trail
    _at(canvas, xl + 5 * k, h * 0.225, k, 0, () {
      final plane = Path()
        ..moveTo(-30, 5)
        ..lineTo(38, -28)
        ..lineTo(8, 32)
        ..lineTo(-4, 9)
        ..close();
      canvas.drawPath(plane, v);
      canvas.drawLine(const Offset(38, -28), const Offset(-4, 9), v);
      final trail = Path()
        ..moveTo(-40, 28)
        ..cubicTo(-90, 50, -110, 80, -150, 62);
      _dashed(canvas, trail, _stroke(_yellow, 3));
      canvas.drawCircle(const Offset(-82, 52), 14, _stroke(_yellow, 3));
    });

    // QR phone
    _at(canvas, xl, h * 0.395, k, -0.12, () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTRB(-48, -68, 48, 68), const Radius.circular(12)),
        v,
      );
      final q = _stroke(_violet, 3);
      for (final o in [const Offset(-30, -45), const Offset(8, -45), const Offset(-30, -7)]) {
        canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 22, 22), q);
        canvas.drawRect(Rect.fromLTWH(o.dx + 7, o.dy + 7, 8, 8), _fill(_violet));
      }
      for (final o in [const Offset(8, -7), const Offset(24, -7), const Offset(8, 9), const Offset(24, 9), const Offset(-10, 30), const Offset(10, 30)]) {
        canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 8, 8), _fill(_violet));
      }
      canvas.save();
      canvas.translate(72, -10);
      _sparks(canvas, [-0.6, 0.1, 0.8], 10, 24);
      canvas.restore();
    });

    // coins with rupee
    _at(canvas, xl, h * 0.565, k, 0, () {
      for (final y in [-22.0, -8.0, 6.0]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(-14, y), width: 56, height: 18), _fill(_bg));
        canvas.drawOval(Rect.fromCenter(center: Offset(-14, y), width: 56, height: 18), v);
      }
      canvas.drawCircle(const Offset(16, 16), 26, _fill(Colors.white));
      canvas.drawCircle(const Offset(16, 16), 26, _stroke(_yellow, 5));
      _text(canvas, '₹',
          const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _violet),
          const Offset(16, 16));
      canvas.save();
      canvas.translate(52, -34);
      _sparks(canvas, [-1.2, -0.4, 0.4], 8, 22);
      canvas.restore();
    });

    // "Tap Pay Go"
    _at(canvas, xl + 20 * k, h * 0.705, k, -0.12, () {
      const style = TextStyle(
        fontSize: 40,
        height: 1.0,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
        color: _violet,
        fontFamilyFallback: ['cursive', 'Segoe Script', 'Brush Script MT'],
      );
      _text(canvas, 'Tap\nPay\nGo', style, const Offset(0, 0));
      canvas.drawLine(const Offset(-70, 82), const Offset(80, 70), _stroke(_yellow, 5));
    });

    // --- RIGHT ---
    // CampusPay wordmark
    _at(canvas, xr - 10 * k, h * 0.085, k, -0.12, () {
      const style = TextStyle(
        fontSize: 56,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
        color: _violet,
        fontFamilyFallback: ['cursive', 'Segoe Script', 'Brush Script MT'],
      );
      _text(canvas, 'CampusPay', style, const Offset(0, 0));
      canvas.drawLine(const Offset(-110, 42), const Offset(120, 28), _stroke(_yellow, 5));
      canvas.save();
      canvas.translate(-70, -48);
      _sparks(canvas, [-1.9, -1.2, -0.5], 8, 24);
      canvas.restore();
    });

    // NFC / wifi waves
    _at(canvas, xr, h * 0.222, k, 0, () {
      canvas.drawCircle(const Offset(-24, 0), 6, _fill(_violet));
      for (final r in [20.0, 38.0, 56.0]) {
        canvas.drawArc(Rect.fromCircle(center: const Offset(-24, 0), radius: r), -0.85, 1.7, false, v);
      }
    });

    // contactless card
    _at(canvas, xr, h * 0.34, k, 0.14, () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTRB(-58, -36, 58, 36), const Radius.circular(8)),
        v,
      );
      final y = _stroke(_yellow, 4);
      canvas.drawLine(const Offset(-42, 4), const Offset(-8, 4), y);
      canvas.drawLine(const Offset(-42, 16), const Offset(-22, 16), y);
      for (final r in [6.0, 11.0, 16.0]) {
        canvas.drawArc(Rect.fromCircle(center: const Offset(26, 10), radius: r), -0.9, 1.8, false, _stroke(_violet, 2.5));
      }
      canvas.save();
      canvas.translate(-70, -40);
      _sparks(canvas, [-2.4, -1.7, -1.0], 8, 22);
      canvas.restore();
    });

    // graduation cap
    _at(canvas, xr, h * 0.48, k, 0, () {
      final top = Path()
        ..moveTo(-62, -6)
        ..lineTo(0, -32)
        ..lineTo(62, -6)
        ..lineTo(0, 20)
        ..close();
      canvas.drawPath(top, v);
      final base = Path()
        ..moveTo(-34, 8)
        ..lineTo(-34, 32)
        ..quadraticBezierTo(0, 52, 34, 32)
        ..lineTo(34, 8);
      canvas.drawPath(base, v);
      canvas.drawLine(const Offset(52, -2), const Offset(52, 30), _stroke(_yellow, 6));
      canvas.drawCircle(const Offset(52, 36), 4, _fill(_yellow));
    });

    // heart
    _at(canvas, xr - 5 * k, h * 0.675, k, 0, () {
      final heart = Path()
        ..moveTo(0, 28)
        ..cubicTo(-42, -4, -22, -42, 0, -16)
        ..cubicTo(22, -42, 42, -4, 0, 28);
      canvas.drawPath(heart, v);
      canvas.save();
      canvas.translate(-48, -4);
      _sparks(canvas, [2.6, 3.3, 3.9], 6, 20);
      canvas.restore();
      canvas.save();
      canvas.translate(50, -14);
      _sparks(canvas, [-0.6, 0.1, 0.8], 6, 20);
      canvas.restore();
    });
  }

  @override
  bool shouldRepaint(covariant _CampusBgPainter oldDelegate) => false;
}