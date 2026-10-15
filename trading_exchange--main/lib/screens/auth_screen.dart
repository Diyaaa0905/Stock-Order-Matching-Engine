import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final AuthService auth;
  const AuthScreen({super.key, required this.auth});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;

  // Controllers
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regUserCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();

  // Eye blink toggles
  bool _obscureLoginPass = true;
  bool _obscureRegPass = true;
  bool _obscureRegConfirmPass = true;

  @override
  void dispose() {
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regUserCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final user = _loginUserCtrl.text.trim();
    final pass = _loginPassCtrl.text;

    if (user.isEmpty || pass.isEmpty) {
      _showSnackbar('Please enter username/email and password.');
      return;
    }

    final success = await widget.auth.login(
      username: user,
      password: pass,
    );

    if (!success && mounted) {
      _showSnackbar(widget.auth.errorMessage ?? 'Login failed. Please check credentials.');
    }
  }

  Future<void> _handleRegister() async {
    final name = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final user = _regUserCtrl.text.trim();
    final pass = _regPassCtrl.text;
    final confirm = _regConfirmPassCtrl.text;

    if (user.length < 3) {
      _showSnackbar('Username must be at least 3 characters.');
      return;
    }
    if (!email.contains('@')) {
      _showSnackbar('Please enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      _showSnackbar('Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      _showSnackbar('Passwords do not match.');
      return;
    }

    final success = await widget.auth.register(
      username: user,
      email: email,
      fullName: name,
      password: pass,
    );

    if (!success && mounted) {
      _showSnackbar(widget.auth.errorMessage ?? 'Registration failed.');
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFF6465D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C087).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF00C087), width: 1.5),
                        ),
                        child: const Icon(Icons.candlestick_chart, color: Color(0xFF00C087), size: 32),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'APEX TRADER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Stock Matching Exchange Platform',
                            style: TextStyle(color: Color(0xFF848E9C), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Auth Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131722),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF2A2E39)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Toggle Segment
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E222D),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isLogin = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isLogin ? const Color(0xFF2A2E39) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: _isLogin ? Colors.white : const Color(0xFF848E9C),
                                        fontWeight: _isLogin ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isLogin = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isLogin ? const Color(0xFF2A2E39) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Register',
                                      style: TextStyle(
                                        color: !_isLogin ? Colors.white : const Color(0xFF848E9C),
                                        fontWeight: !_isLogin ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_isLogin) ..._buildLoginForm() else ..._buildRegisterForm(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info footer
                  const Center(
                    child: Text(
                      '🔒 Encrypted Passwords • ACID Compliant Matching Engine',
                      style: TextStyle(color: Color(0xFF5E6673), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLoginForm() {
    return [
      const Text('Username or Email', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: _loginUserCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(
          hint: 'Enter your username or email',
          prefixIcon: Icons.person_outline,
        ),
      ),
      const SizedBox(height: 16),

      const Text('Password', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: _loginPassCtrl,
        obscureText: _obscureLoginPass,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(
          hint: 'Enter password',
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureLoginPass ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF848E9C),
              size: 20,
            ),
            tooltip: 'Eye blink toggle',
            onPressed: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
          ),
        ),
      ),
      const SizedBox(height: 24),

      ElevatedButton(
        onPressed: widget.auth.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C087),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: widget.auth.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text('Sign In to Exchange', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    ];
  }

  List<Widget> _buildRegisterForm() {
    return [
      const Text('Full Name', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: _regNameCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(
          hint: 'e.g. Rahul Sharma',
          prefixIcon: Icons.badge_outlined,
        ),
      ),
      const SizedBox(height: 12),

      const Text('Email Address', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: _regEmailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(
          hint: 'e.g. rahul@example.com',
          prefixIcon: Icons.email_outlined,
        ),
      ),
      const SizedBox(height: 12),

      const Text('Username', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: _regUserCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(
          hint: 'Choose a unique username',
          prefixIcon: Icons.alternate_email,
        ),
      ),
      const SizedBox(height: 12),

      const Text('Password (Encrypted)', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: _regPassCtrl,
        obscureText: _obscureRegPass,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(
          hint: 'Min 6 characters',
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureRegPass ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF848E9C),
              size: 20,
            ),
            tooltip: 'Eye blink toggle',
            onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
          ),
        ),
      ),
      const SizedBox(height: 12),

      const Text('Confirm Password', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: _regConfirmPassCtrl,
        obscureText: _obscureRegConfirmPass,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(
          hint: 'Re-enter password',
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureRegConfirmPass ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF848E9C),
              size: 20,
            ),
            tooltip: 'Eye blink toggle',
            onPressed: () => setState(() => _obscureRegConfirmPass = !_obscureRegConfirmPass),
          ),
        ),
      ),
      const SizedBox(height: 8),

      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E222D),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF00C087), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'New traders start with ₹0 balance. You can add balance anytime from your profile.',
                style: TextStyle(color: Color(0xFF848E9C), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),

      ElevatedButton(
        onPressed: widget.auth.isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C087),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: widget.auth.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text('Create Account & Start Trading', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    ];
  }

  InputDecoration _inputDecoration({required String hint, required IconData prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF5E6673), fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF848E9C), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF1E222D),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2E39)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2E39)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00C087)),
      ),
    );
  }
}
