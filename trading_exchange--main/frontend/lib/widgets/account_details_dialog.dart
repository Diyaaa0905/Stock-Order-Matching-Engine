import 'package:flutter/material.dart';
import '../services/auth_service.dart';

void showAccountDetailsDialog(BuildContext context, AuthService auth) {
  showDialog(
    context: context,
    builder: (ctx) => _AccountDetailsDialogContent(auth: auth),
  );
}

class _AccountDetailsDialogContent extends StatefulWidget {
  final AuthService auth;
  const _AccountDetailsDialogContent({required this.auth});

  @override
  State<_AccountDetailsDialogContent> createState() => _AccountDetailsDialogContentState();
}

class _AccountDetailsDialogContentState extends State<_AccountDetailsDialogContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = widget.auth.currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (name.isEmpty) {
      setState(() => _error = 'Full name cannot be empty.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (newPass.isNotEmpty) {
      if (newPass.length < 6) {
        setState(() => _error = 'New password must be at least 6 characters.');
        return;
      }
      if (newPass != confirmPass) {
        setState(() => _error = 'Passwords do not match.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await widget.auth.updateProfile(
      fullName: name,
      email: email,
      newPassword: newPass.isNotEmpty ? newPass : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account details updated successfully!'),
          backgroundColor: Color(0xFF00C087),
        ),
      );
    } else {
      setState(() => _error = widget.auth.errorMessage ?? 'Update failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.currentUser;

    return Dialog(
      backgroundColor: const Color(0xFF131722),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2A2E39)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.manage_accounts, color: Color(0xFF00C087), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Account Details',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF848E9C), size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Read-only meta info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trader ID', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                      Text(user?.id ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Username', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                      Text('@${user?.username ?? '-'}', style: const TextStyle(color: Color(0xFF00C087), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Full Name
            const Text('Full Name', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(prefixIcon: Icons.person_outline),
            ),
            const SizedBox(height: 14),

            // Email
            const Text('Email Address', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(prefixIcon: Icons.email_outlined),
            ),
            const SizedBox(height: 16),

            const Divider(color: Color(0xFF2A2E39)),
            const SizedBox(height: 8),

            const Text(
              'Change Password (Optional)',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // New Password with eye blink toggle
            const Text('New Password', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _newPassController,
              obscureText: _obscureNewPass,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPass ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF848E9C),
                    size: 20,
                  ),
                  tooltip: 'Eye blink toggle',
                  onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Confirm Password with eye blink toggle
            const Text('Confirm New Password', style: TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmPassController,
              obscureText: _obscureConfirmPass,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPass ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF848E9C),
                    size: 20,
                  ),
                  tooltip: 'Eye blink toggle',
                  onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFF6465D), fontSize: 12)),
            ],
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C087),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required IconData prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
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
