import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();
  String _role = 'beekeeper';
  bool _loading = false;
  bool _obscure = true;

  Future<void> _handleRegister() async {
    if (_passwordCtrl.text != _password2Ctrl.text) {
      _showSnack('Passwords do not match');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      _showSnack('Password too short');
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService.register({
        'username': _usernameCtrl.text.trim(),
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'region': _regionCtrl.text.trim(),
        'role': _role,
        'password': _passwordCtrl.text,
        'password2': _password2Ctrl.text,
      });
      if (data.containsKey('tokens')) {
        _showSnack('Account created! Please sign in.');
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        final errors = (data as Map).values
            .expand((v) => v is List ? v : [v])
            .join(' ');
        _showSnack(errors.toString());
      }
    } catch (e) {
      _showSnack('Cannot connect to server.');
    }
    setState(() => _loading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.combDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.amberGlow,
      appBar: AppBar(
        backgroundColor: AppColors.combDark,
        foregroundColor: AppColors.amberLight,
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ROLE SELECTOR
            const Text(
              'I AM A',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _roleChip('beekeeper', '🐝 Beekeeper'),
                const SizedBox(width: 8),
                _roleChip('buyer', '🛒 Buyer'),
                const SizedBox(width: 8),
                _roleChip('inspector', '🔬 Inspector'),
              ],
            ),
            const SizedBox(height: 20),

            // FIELDS
            Row(
              children: [
                Expanded(
                  child: _field(
                    'First Name',
                    _firstNameCtrl,
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    'Last Name',
                    _lastNameCtrl,
                    Icons.person_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _field('Username', _usernameCtrl, Icons.badge_outlined),
            const SizedBox(height: 14),
            _field(
              'Email',
              _emailCtrl,
              Icons.email_outlined,
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _field(
              'Phone',
              _phoneCtrl,
              Icons.phone_outlined,
              type: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _field(
              'Region / Location',
              _regionCtrl,
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 14),
            _field(
              'Password',
              _passwordCtrl,
              Icons.lock_outline,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textLight,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 14),
            _field(
              'Confirm Password',
              _password2Ctrl,
              Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 28),

            // REGISTER BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.combDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        '🐝  Create My Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String value, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _role == value
              ? AppColors.amberPale
              : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _role == value
                ? AppColors.amberWarm
                : AppColors.amberWarm.withOpacity(0.3),
            width: _role == value ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _role == value ? AppColors.combDark : AppColors.textLight,
          ),
        ),
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType type = TextInputType.text,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
          letterSpacing: 1.0,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: type,
        style: const TextStyle(color: AppColors.textDark, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.amberWarm.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.amberWarm.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.amberWarm,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    ],
  );
}
