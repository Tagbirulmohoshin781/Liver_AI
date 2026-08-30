import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final Function(UserProfile) onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final String _selectedRole = 'Patient';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRealSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isSignUp) {
        if (_passwordController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
          setState(() {
            _errorMessage = 'Please fill in all required fields.';
            _isLoading = false;
          });
          return;
        }

        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'Passwords do not match. Please re-enter carefully.';
            _isLoading = false;
          });
          return;
        }

        final res = await _authService.register(
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Patient User',
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
        );

        if (res['success'] == true && res['user'] != null) {
          setState(() => _successMessage = res['message']);
          await Future.delayed(const Duration(milliseconds: 300));
          widget.onAuthenticated(res['user'] as UserProfile);
        } else {
          setState(() => _errorMessage = res['message'] ?? 'Registration failed.');
        }
      } else {
        if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Please enter your email and password.';
            _isLoading = false;
          });
          return;
        }

        final res = await _authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (res['success'] == true && res['user'] != null) {
          final user = res['user'] as UserProfile;
          setState(() => _successMessage = res['message']);
          await Future.delayed(const Duration(milliseconds: 300));
          widget.onAuthenticated(user);
        } else {
          setState(() => _errorMessage = res['message'] ?? 'Invalid email address or password.');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Authentication Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final res = await _authService.signInWithGoogleNative(role: _selectedRole);
      if (res['success'] == true && res['user'] != null) {
        widget.onAuthenticated(res['user'] as UserProfile);
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      _showGoogleAccountModal();
    }
  }

  void _showGoogleAccountModal() {
    final TextEditingController googleEmailCtrl = TextEditingController(text: 'user.google@gmail.com');
    final TextEditingController googleNameCtrl = TextEditingController(text: 'Google User');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEA4335),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Choose an account to continue to LiverAI',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 12),

              // Account Option 1: Dipto Google Account
              _googleAccountTile(
                name: 'Tagbirul Mohoshin',
                email: 'tagbirul.google@gmail.com',
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  final res = await _authService.signInWithGoogleAccount(
                    email: 'tagbirul.google@gmail.com',
                    displayName: 'Tagbirul Mohoshin',
                    role: _selectedRole,
                  );
                  if (res['success'] == true && res['user'] != null) {
                    widget.onAuthenticated(res['user'] as UserProfile);
                  }
                },
              ),
              const SizedBox(height: 10),

              // Account Option 2: Demo Patient Account
              _googleAccountTile(
                name: 'Google Patient Account',
                email: 'patient.google@liverai.health',
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  final res = await _authService.signInWithGoogleAccount(
                    email: 'patient.google@liverai.health',
                    displayName: 'Google Patient Account',
                    role: _selectedRole,
                  );
                  if (res['success'] == true && res['user'] != null) {
                    widget.onAuthenticated(res['user'] as UserProfile);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Or use another Google email:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: googleEmailCtrl,
                style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'yourname@gmail.com',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final email = googleEmailCtrl.text.trim();
                    final name = googleNameCtrl.text.trim();
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    final res = await _authService.signInWithGoogleAccount(
                      email: email.isNotEmpty ? email : 'user.google@gmail.com',
                      displayName: name.isNotEmpty ? name : 'Google User',
                      role: _selectedRole,
                    );
                    if (res['success'] == true && res['user'] != null) {
                      widget.onAuthenticated(res['user'] as UserProfile);
                    }
                  },
                  child: const Text(
                    'Continue with Google Account',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _googleAccountTile({required String name, required String email, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF2563EB),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'G',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSocialAuth(String provider) async {
    setState(() => _isLoading = true);
    if (provider == 'Facebook') {
      final res = await _authService.signInWithFacebookNative(role: _selectedRole);
      if (res['success'] == true && res['user'] != null) {
        widget.onAuthenticated(res['user'] as UserProfile);
        return;
      }
    } else if (provider == 'GitHub') {
      final res = await _authService.signInWithGithubNative(role: _selectedRole);
      if (res['success'] == true && res['user'] != null) {
        widget.onAuthenticated(res['user'] as UserProfile);
        return;
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111E), // High-Tech Deep Navy #07111E
      body: Stack(
        children: [
          // ── Web App Matching Background Atmosphere & Laboratory Ambiance ────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A192F),
                    Color(0xFF07111E),
                    Color(0xFF040A16),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -140,
            left: -140,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -180,
            right: -140,
            child: Container(
              width: 550,
              height: 550,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF312E81).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      // ── Central Glassmorphic Card (100% Matching Web App Login Page) ─
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.85), // Matching web .auth-glass-card
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                              blurRadius: 35,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                            const BoxShadow(
                              color: Colors.black54,
                              blurRadius: 30,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Official LiverAI Logo & Title Badge ────────────────
                            Center(
                              child: Column(
                                children: [
                                  // Official Emblem Container
                                  Container(
                                    width: 76,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF071B2E).withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CustomPaint(
                                      painter: LiverLogoPainter(),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // LIVER AI Typography
                                  RichText(
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'LIVER ',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'AI',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF00E5FF),
                                            letterSpacing: -0.5,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  // Tagline: PRECISION DIAGNOSTICS & ANALYTICS
                                  const Text(
                                    'PRECISION DIAGNOSTICS & ANALYTICS',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF38BDF8),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _isSignUp ? 'Create Your LiverAI Account' : 'Sign In to Your LiverAI Account',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFDC2626),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],

                            if (_successMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF059669)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _successMessage!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF059669),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],

                            if (_isSignUp) ...[
                              _label('Full Name'),
                              const SizedBox(height: 6),
                              _field(
                                controller: _nameController,
                                hint: 'e.g. Tagbirul Mohoshin',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 18),
                            ],

                            _label('Email Address'),
                            const SizedBox(height: 6),
                            _field(
                              controller: _emailController,
                              hint: 'admin@gmail.com',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 18),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _label('Password'),
                                if (!_isSignUp)
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF60A5FA),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _field(
                              controller: _passwordController,
                              hint: 'Enter your password',
                              icon: Icons.lock_outline_rounded,
                              isPass: true,
                              obscure: _obscurePassword,
                              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),

                            if (_isSignUp) ...[
                              const SizedBox(height: 18),
                              _label('Confirm Password'),
                              const SizedBox(height: 6),
                              _field(
                                controller: _confirmPasswordController,
                                hint: '••••••••',
                                icon: Icons.lock_reset_rounded,
                                isPass: true,
                                obscure: _obscurePassword,
                                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ],
                            const SizedBox(height: 26),

                            // ── Primary Action Button (Deep Navy Pill Button in Screenshot) 
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF102A45), Color(0xFF1E3A8A)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _handleRealSubmit,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _isSignUp ? 'Create Account' : 'Sign In',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // ── Divider ──────────────────────────────────────────
                            Row(
                              children: [
                                const Expanded(child: Divider(color: Colors.white24)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'or continue with',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: Colors.white24)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Social Sign-In Button (Google SSO) ────────────────
                            _socialBtn(
                              label: 'Continue with Google',
                              isGoogle: true,
                              icon: Icons.g_mobiledata_rounded,
                              color: const Color(0xFFEA4335),
                              onTap: _handleGoogleSignIn,
                            ),
                            const SizedBox(height: 26),

                            // ── Footer Links (Sign Up & Guest Mode in Cyan) ──────
                            Center(
                              child: Column(
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        _isSignUp ? "Already have an account? " : "Don't have an account? ",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _isSignUp = !_isSignUp;
                                          _errorMessage = null;
                                          _successMessage = null;
                                        }),
                                        child: Text(
                                          _isSignUp ? 'Sign In' : 'Sign Up',
                                          style: const TextStyle(
                                            color: Color(0xFF60A5FA),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  GestureDetector(
                                    onTap: () => widget.onAuthenticated(UserProfile.defaultPatient()),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Explore in Guest Mode',
                                          style: TextStyle(
                                            color: Color(0xFF60A5FA),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF60A5FA)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Footer Copyright ────────────────────────────────────
                      const Text(
                        '© 2026 LiverAI Diagnostic Systems • Medical Intelligence Engine',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPass = false,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Rounded Light Pill Field matching screenshot
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: const Color(0xFF1E293B).withValues(alpha: 0.4)),
          prefixIcon: Icon(icon, size: 19, color: const Color(0xFF475569)),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 19,
                    color: const Color(0xFF475569),
                  ),
                  onPressed: onToggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _socialBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isGoogle = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // Matching web white pill button
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGoogle)
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFEA4335),
                    ),
                  ),
                )
              else
                Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painter for Official LiverAI Anatomical Emblem ────────────
class LiverLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Anatomical Liver Base Lobe (Left Main Lobe)
    final Path mainLobe = Path();
    mainLobe.moveTo(w * 0.38, h * 0.16);
    mainLobe.cubicTo(w * 0.65, h * 0.12, w * 0.78, h * 0.25, w * 0.80, h * 0.42);
    mainLobe.cubicTo(w * 0.82, h * 0.58, w * 0.74, h * 0.72, w * 0.62, h * 0.82);
    mainLobe.cubicTo(w * 0.45, h * 0.94, w * 0.28, h * 0.90, w * 0.18, h * 0.80);
    mainLobe.cubicTo(w * 0.08, h * 0.70, w * 0.04, h * 0.52, w * 0.08, h * 0.38);
    mainLobe.cubicTo(w * 0.12, h * 0.22, w * 0.22, h * 0.16, w * 0.38, h * 0.16);
    mainLobe.close();

    final Paint mainPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF072B4F), Color(0xFF0E487C), Color(0xFF0A335B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(mainLobe, mainPaint);

    // 2. Right Smaller Lobe
    final Path rightLobe = Path();
    rightLobe.moveTo(w * 0.70, h * 0.35);
    rightLobe.cubicTo(w * 0.86, h * 0.38, w * 0.95, h * 0.48, w * 0.92, h * 0.60);
    rightLobe.cubicTo(w * 0.88, h * 0.72, w * 0.75, h * 0.78, w * 0.65, h * 0.72);
    rightLobe.cubicTo(w * 0.68, h * 0.60, w * 0.70, h * 0.48, w * 0.70, h * 0.35);
    rightLobe.close();

    final Paint rightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0B3763), Color(0xFF062240)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(rightLobe, rightPaint);

    // 3. Glowing Neural Network Mesh Lines
    final Paint linePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Offset centerNode = Offset(w * 0.42, h * 0.48);
    final List<Offset> nodes = [
      Offset(w * 0.28, h * 0.34),
      Offset(w * 0.44, h * 0.28),
      Offset(w * 0.58, h * 0.32),
      Offset(w * 0.64, h * 0.48),
      Offset(w * 0.52, h * 0.68),
      Offset(w * 0.32, h * 0.66),
      Offset(w * 0.22, h * 0.50),
      Offset(w * 0.66, h * 0.22),
      Offset(w * 0.78, h * 0.30),
      Offset(w * 0.82, h * 0.45),
      Offset(w * 0.72, h * 0.64),
      Offset(w * 0.38, h * 0.84),
      Offset(w * 0.14, h * 0.62),
    ];

    // Draw Spoke Lines from Center Core
    for (final node in nodes.take(7)) {
      canvas.drawLine(centerNode, node, linePaint);
    }

    // Secondary Connections
    canvas.drawLine(nodes[0], nodes[1], linePaint);
    canvas.drawLine(nodes[1], nodes[2], linePaint);
    canvas.drawLine(nodes[2], nodes[7], linePaint);
    canvas.drawLine(nodes[7], nodes[8], linePaint);
    canvas.drawLine(nodes[2], nodes[3], linePaint);
    canvas.drawLine(nodes[3], nodes[9], linePaint);
    canvas.drawLine(nodes[3], nodes[10], linePaint);
    canvas.drawLine(nodes[4], nodes[10], linePaint);
    canvas.drawLine(nodes[4], nodes[11], linePaint);
    canvas.drawLine(nodes[5], nodes[4], linePaint);
    canvas.drawLine(nodes[6], nodes[5], linePaint);
    canvas.drawLine(nodes[6], nodes[12], linePaint);

    // 4. Cyan Node Circles
    final Paint nodePaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..style = PaintingStyle.fill;

    for (final node in nodes) {
      canvas.drawCircle(node, 2.6, nodePaint);
    }

    // 5. Central Radiant Core Node
    final Paint auraPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(centerNode, 7, auraPaint);

    final Paint corePaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerNode, 4.5, corePaint);

    final Paint centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerNode, 2, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

