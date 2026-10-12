// lib/login_signup_page.dart
// NO extra package needed. NO image / asset needed.
// Background (CampusPay wala look) poora code se draw hota hai (CustomPainter).
// Authentication abhi nahi hai - sirf UI + dummy login.
// Baad me sirf AuthService class ke andar real authentication lagani hai.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/student_profile.dart';

// ---------------------------------------------------------------
// COLORS
// ---------------------------------------------------------------
class AuthColors {
  static const purple = Color(0xFF6A1B9A);
  static const purpleLight = Color(0xFFF3E5F5);
  static const yellow = Color(0xFFFFC107);
  static const white = Colors.white;
}

// ---------------------------------------------------------------
// AUTH SERVICE (Passwordless OTP + Student Profile)
// ---------------------------------------------------------------
class AppUser {
  final String name;
  final String email;
  const AppUser({required this.name, required this.email});
}

class AuthService {
  static const _profileStorageKey = 'campuspay_student_profile';
  static const _accountsRegistryKey = 'campuspay_registered_accounts';
  static const standardOtp = '1234';

  static final List<StudentProfile> _defaultDemoAccounts = [
    const StudentProfile(
      firstName: 'Rahul',
      lastName: 'Sharma',
      phone: '9876543210',
      email: 'rahul.sharma@dbit.ac.in',
      studentId: 'DBIT2024001',
      collegeName: 'Don Bosco Institute of Technology',
      branch: 'Computer Engineering',
      year: 'Third Year (TE)',
    ),
  ];

  /// Current logged-in student profile. null = logged out.
  static final ValueNotifier<StudentProfile?> currentStudent = ValueNotifier(null);

  /// Backwards-compatibility notifier for any UI widgets listening to currentUser
  static final ValueNotifier<AppUser?> currentUser = ValueNotifier(null);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_profileStorageKey);
      if (data != null && data.isNotEmpty) {
        final profile = StudentProfile.fromJson(data);
        _setProfile(profile);
        await registerAccount(profile);
      }
    } catch (e) {
      debugPrint('[AuthService] Error loading stored profile: $e');
    }
  }

  static void _setProfile(StudentProfile? profile) {
    currentStudent.value = profile;
    if (profile != null) {
      currentUser.value = AppUser(name: profile.firstName, email: profile.email);
    } else {
      currentUser.value = null;
    }
  }

  static Future<void> _persistProfile(StudentProfile? profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (profile == null) {
        await prefs.remove(_profileStorageKey);
      } else {
        await prefs.setString(_profileStorageKey, profile.toJson());
      }
    } catch (e) {
      debugPrint('[AuthService] Error persisting profile: $e');
    }
  }

  /// Get all registered accounts from local storage + built-in demo accounts
  static Future<List<StudentProfile>> getRegisteredAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_accountsRegistryKey);
      final accounts = <StudentProfile>[];
      if (listJson != null && listJson.isNotEmpty) {
        for (final item in listJson) {
          try {
            accounts.add(StudentProfile.fromJson(item));
          } catch (_) {}
        }
      }
      // Ensure seed demo accounts exist in list
      for (final demo in _defaultDemoAccounts) {
        final alreadyPresent = accounts.any(
          (a) => a.phone == demo.phone || a.studentId == demo.studentId,
        );
        if (!alreadyPresent) {
          accounts.add(demo);
        }
      }
      return accounts;
    } catch (e) {
      debugPrint('[AuthService] Error reading registered accounts: $e');
      return List.from(_defaultDemoAccounts);
    }
  }

  /// Register or update an account in the registry
  static Future<void> registerAccount(StudentProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = await getRegisteredAccounts();
      final index = accounts.indexWhere(
        (a) => a.phone == profile.phone || a.studentId == profile.studentId,
      );
      if (index >= 0) {
        accounts[index] = profile;
      } else {
        accounts.add(profile);
      }
      final serialized = accounts.map((a) => a.toJson()).toList();
      await prefs.setStringList(_accountsRegistryKey, serialized);
    } catch (e) {
      debugPrint('[AuthService] Error registering account: $e');
    }
  }

  /// Verifies if an account exists by matching Phone Number, Student ID, or Email.
  /// Queries local registry first, then Supabase if configured.
  static Future<StudentProfile?> findAccount(String rawIdentifier) async {
    final identifier = rawIdentifier.trim();
    if (identifier.isEmpty) return null;

    final cleanDigits = identifier.replaceAll(RegExp(r'\D'), '');
    final last10Digits =
        cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;

    // 1. Search local registered accounts
    final accounts = await getRegisteredAccounts();
    for (final acc in accounts) {
      final accDigits = acc.phone.replaceAll(RegExp(r'\D'), '');
      final accLast10 =
          accDigits.length >= 10 ? accDigits.substring(accDigits.length - 10) : accDigits;

      final phoneMatch =
          last10Digits.isNotEmpty && (accDigits == cleanDigits || accLast10 == last10Digits);
      final idMatch = acc.studentId.trim().toLowerCase() == identifier.toLowerCase();
      final emailMatch = acc.email.trim().toLowerCase() == identifier.toLowerCase();

      if (phoneMatch || idMatch || emailMatch) {
        return acc;
      }
    }

    // 2. Query Supabase if configured
    if (SupabaseService.isConfigured) {
      try {
        final c = SupabaseService.client;
        if (c != null) {
          final query = last10Digits.isNotEmpty
              ? c
                  .from('profiles')
                  .select()
                  .or('phone.ilike.%$last10Digits%,student_id.ilike.$identifier,email.ilike.$identifier')
                  .maybeSingle()
              : c
                  .from('profiles')
                  .select()
                  .or('student_id.ilike.$identifier,email.ilike.$identifier')
                  .maybeSingle();
          final data = await query;
          if (data != null) {
            final profile = StudentProfile.fromMap(data);
            await registerAccount(profile);
            return profile;
          }
        }
      } catch (e) {
        debugPrint('[AuthService] Supabase findAccount error: $e');
      }
    }

    return null;
  }

  static bool get isLoggedIn =>
      currentStudent.value != null ||
      currentUser.value != null ||
      (SupabaseService.isConfigured && SupabaseService.currentUser != null);

  static String get studentName {
    if (currentStudent.value != null) {
      return currentStudent.value!.firstName;
    }
    if (currentUser.value != null) return currentUser.value!.name;
    if (SupabaseService.currentUser != null) {
      final meta = SupabaseService.currentUser!.userMetadata;
      if (meta != null && meta['full_name'] != null) {
        return meta['full_name'].toString();
      }
      return SupabaseService.currentUser!.email?.split('@').first ?? 'Student';
    }
    return 'Guest';
  }

  static Future<bool> verifyAndLogin({
    required String otp,
    required StudentProfile profile,
  }) async {
    if (otp.trim() != standardOtp) {
      return false;
    }
    _setProfile(profile);
    await _persistProfile(profile);
    await registerAccount(profile);
    return true;
  }

  static Future<void> updateSecondaryInfo({
    required String collegeName,
    required String branch,
    required String year,
  }) async {
    final current = currentStudent.value;
    if (current == null) return;
    final updated = current.copyWith(
      collegeName: collegeName.trim(),
      branch: branch.trim(),
      year: year.trim(),
    );
    _setProfile(updated);
    await _persistProfile(updated);
    await registerAccount(updated);
  }

  static Future<void> logout() async {
    if (SupabaseService.isConfigured) {
      SupabaseService.signOut();
    }
    _setProfile(null);
    await _persistProfile(null);
  }

  static void requireAuth(
    BuildContext context, {
    required VoidCallback onAuthenticated,
    String? message,
  }) {
    if (isLoggedIn) {
      onAuthenticated();
      return;
    }
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AuthColors.purple,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginSignupPage(
          onSuccess: () {
            Navigator.pop(context);
            onAuthenticated();
          },
        ),
      ),
    );
  }

  // Legacy fallback methods for test & backward compatibility
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final name = email.split('@').first;
    final profile = StudentProfile(
      firstName: name,
      lastName: '',
      phone: '9876543210',
      email: email,
      studentId: 'DBIT2024001',
    );
    _setProfile(profile);
    await _persistProfile(profile);
    await registerAccount(profile);
  }

  static Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final parts = name.trim().split(' ');
    final first = parts.isNotEmpty ? parts.first : name;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final profile = StudentProfile(
      firstName: first,
      lastName: last,
      phone: '9876543210',
      email: email,
      studentId: 'DBIT${DateTime.now().year.toString().substring(2)}${1000 + (name.hashCode.abs() % 9000)}',
    );
    _setProfile(profile);
    await _persistProfile(profile);
    await registerAccount(profile);
  }

  static Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

// ---------------------------------------------------------------
// LOGIN / SIGNUP PAGE (PASSWORDLESS OTP + 5 PRIMARY FIELDS)
// ---------------------------------------------------------------
class LoginSignupPage extends StatefulWidget {
  final VoidCallback onSuccess;
  const LoginSignupPage({super.key, required this.onSuccess});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdentifierCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _isLogin = true;
  bool _isOtpStep = false;
  bool _loading = false;
  StudentProfile? _pendingProfile;

  @override
  void dispose() {
    _loginIdentifierCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _studentIdCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    if (_isLogin) {
      final identifier = _loginIdentifierCtrl.text.trim();
      final found = await AuthService.findAccount(identifier);
      if (found == null) {
        setState(() => _loading = false);
        _snack('No account found for "$identifier". Please sign up first.');
        return;
      }
      _pendingProfile = found;
    } else {
      final phone = _phoneCtrl.text.trim();
      final studentId = _studentIdCtrl.text.trim().toUpperCase();

      final existingByPhone = await AuthService.findAccount(phone);
      if (existingByPhone != null) {
        setState(() => _loading = false);
        _snack('An account with this phone number already exists. Please login instead.');
        return;
      }

      final existingById = await AuthService.findAccount(studentId);
      if (existingById != null) {
        setState(() => _loading = false);
        _snack('An account with Student ID "$studentId" already exists. Please login instead.');
        return;
      }

      _pendingProfile = StudentProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: phone,
        email: _emailCtrl.text.trim(),
        studentId: studentId,
      );
    }

    setState(() {
      _loading = false;
      _isOtpStep = true;
      _otpCtrl.clear();
    });

    _snack('Verification code sent successfully.');
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      _snack('Please enter the 4-digit verification code.');
      return;
    }
    setState(() => _loading = true);

    if (_pendingProfile == null) {
      setState(() => _loading = false);
      return;
    }

    final success = await AuthService.verifyAndLogin(
      otp: otp,
      profile: _pendingProfile!,
    );

    setState(() => _loading = false);

    if (success) {
      if (!mounted) return;
      widget.onSuccess();
    } else {
      _snack('Invalid verification code! Please enter the correct code.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AuthColors.purple),
    );
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AuthColors.purple),
      suffixIcon: suffix,
      filled: true,
      fillColor: AuthColors.purpleLight.withOpacity(0.5),
      labelStyle: const TextStyle(color: AuthColors.purple),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthColors.yellow, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.white,
      body: Stack(
        children: [
          // ---- CampusPay style background ----
          const Positioned.fill(child: _CampusBackground()),
          if (Navigator.canPop(context))
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9999),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded, color: AuthColors.purple, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AuthColors.purple, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AuthColors.purple.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: _isOtpStep ? _buildOtpView() : _buildPrimaryDetailsView(),
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

  Widget _buildPrimaryDetailsView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AuthColors.purple,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_rounded, size: 44, color: AuthColors.yellow),
        ),
        const SizedBox(height: 18),
        Text(
          _isLogin ? 'Welcome Back!' : 'Student Account',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AuthColors.purple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isLogin
              ? 'Login with Phone Number or Student ID'
              : 'Enter primary details for instant campus verification',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 22),

        // Login / Signup toggle
        Container(
          decoration: BoxDecoration(
            color: AuthColors.purpleLight,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              _toggleButton('Login', _isLogin, () {
                setState(() => _isLogin = true);
              }),
              _toggleButton('Sign Up', !_isLogin, () {
                setState(() => _isLogin = false);
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_isLogin) ...[
          TextFormField(
            controller: _loginIdentifierCtrl,
            decoration: _decoration(
              'Phone Number or Student ID',
              Icons.phone_android_rounded,
              hint: 'e.g. 9876543210 or DBIT2024021',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your phone number or student ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AuthColors.purpleLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 16, color: AuthColors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Passwordless login: Verification OTP will be requested.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('First Name', Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _lastNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Last Name', Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _decoration('Phone Number', Icons.phone_android_rounded, hint: '10-digit mobile'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter mobile number';
              if (v.trim().replaceAll(RegExp(r'\D'), '').length < 10) {
                return 'Enter valid 10-digit number';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _decoration('Campus Email ID', Icons.email_outlined, hint: 'student@dbit.ac.in'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter email address';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                return 'Enter valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _studentIdCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: _decoration('Student ID', Icons.badge_outlined, hint: 'e.g. DBIT2024021'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Student ID' : null,
          ),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _requestOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthColors.yellow,
              foregroundColor: AuthColors.purple,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AuthColors.purple,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? 'GET OTP & LOGIN' : 'GET OTP & REGISTER',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),

        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(_isLogin ? "New student? " : 'Already registered? '),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin ? 'Sign Up' : 'Login',
                style: const TextStyle(
                  color: AuthColors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpView() {
    final identifier = _pendingProfile?.phone.isNotEmpty == true
        ? _pendingProfile!.phone
        : (_pendingProfile?.studentId ?? 'your device');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AuthColors.purple,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_clock_rounded, size: 44, color: AuthColors.yellow),
        ),
        const SizedBox(height: 18),
        const Text(
          'Verify OTP',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AuthColors.purple,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Verification code sent to $identifier',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 24),

        // OTP PIN field
        TextFormField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 22,
            color: AuthColors.purple,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••',
            hintStyle: const TextStyle(letterSpacing: 22, color: Colors.grey),
            filled: true,
            fillColor: AuthColors.purpleLight.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AuthColors.yellow, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthColors.yellow,
              foregroundColor: AuthColors.purple,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AuthColors.purple,
                    ),
                  )
                : const Text(
                    'VERIFY & PROCEED',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _isOtpStep = false),
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AuthColors.purple),
              label: const Text('Edit Details', style: TextStyle(color: AuthColors.purple)),
            ),
            TextButton(
              onPressed: () => _snack('Verification code resent successfully.'),
              child: const Text('Resend Code', style: TextStyle(color: AuthColors.purple)),
            ),
          ],
        ),
      ],
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
            color: selected ? AuthColors.purple : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? AuthColors.yellow : AuthColors.purple,
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
            color: AuthColors.purpleLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.account_circle, size: 64, color: AuthColors.purple),
                  const SizedBox(height: 8),
                  const Text(
                    'You are not logged in',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AuthColors.purple),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuthColors.yellow,
                        foregroundColor: AuthColors.purple,
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
          color: AuthColors.purpleLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AuthColors.purple,
                  child: Text(
                    (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
                    style: const TextStyle(fontSize: 28, color: AuthColors.yellow),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AuthColors.purple,
                  ),
                ),
                Text(user.email),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AuthColors.purple,
                    side: const BorderSide(color: AuthColors.purple),
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