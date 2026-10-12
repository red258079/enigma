import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';

/// Màn hình quên mật khẩu gồm 3 bước:
///   Step 1 → Nhập email
///   Step 2 → Nhập OTP 6 số
///   Step 3 → Nhập mật khẩu mới
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1; // 1 | 2 | 3

  final _emailController   = TextEditingController();
  final _otpController     = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmController = TextEditingController();

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey1.currentState!.validate()) return;
    final authState = context.read<AuthState>();
    final ok = await authState.forgotPassword(_emailController.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _step = 2);
    } else {
      _showError(authState.error ?? 'Không thể gửi mã. Vui lòng thử lại.');
    }
  }

  void _verifyOtp() {
    if (!_formKey2.currentState!.validate()) return;
    setState(() => _step = 3);
  }

  Future<void> _resetPassword() async {
    if (!_formKey3.currentState!.validate()) return;
    final authState = context.read<AuthState>();
    final ok = await authState.resetPassword(
      _emailController.text.trim(),
      _otpController.text.trim(),
      _newPassController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      _showSuccess();
    } else {
      _showError(authState.error ?? 'Mã xác nhận không đúng hoặc đã hết hạn.');
      setState(() => _step = 2);
      _otpController.clear();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.accentCoral,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            const Text('Đặt lại mật khẩu thành công!',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text('Bạn có thể đăng nhập bằng mật khẩu mới ngay bây giờ.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Đăng nhập ngay', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgDark, Color(0xFF1a1040), AppTheme.bgDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _step > 1 ? setState(() => _step--) : Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
                    ),
                    const Spacer(),
                    const Text('Quên mật khẩu',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: List.generate(3, (i) {
                    final active = i + 1 <= _step;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primary : AppTheme.cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _step == 1
                        ? _buildStep1(authState)
                        : _step == 2
                            ? _buildStep2(authState)
                            : _buildStep3(authState),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(AuthState authState) {
    return Form(
      key: _formKey1,
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _stepIcon(Icons.email_outlined)),
          const SizedBox(height: 20),
          const Text('Nhập email của bạn',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Chúng tôi sẽ gửi mã xác nhận 6 số đến email của bạn.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập email';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return 'Email không hợp lệ';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildButton(label: 'Gửi mã xác nhận', isLoading: authState.isLoading, onPressed: authState.isLoading ? null : _sendOtp),
        ],
      ),
    );
  }

  Widget _buildStep2(AuthState authState) {
    return Form(
      key: _formKey2,
      child: Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _stepIcon(Icons.sms_outlined)),
          const SizedBox(height: 20),
          const Text('Nhập mã xác nhận',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              children: [
                const TextSpan(text: 'Mã 6 số đã được gửi đến\n'),
                TextSpan(text: _emailController.text.trim(),
                  style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 12),
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 28, letterSpacing: 12),
              filled: true,
              fillColor: AppTheme.bgSurface,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.5)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.accentCoral)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.accentCoral, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Vui lòng nhập đủ 6 chữ số' : null,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: authState.isLoading ? null : _sendOtp,
              child: const Text('Gửi lại mã', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 12),
          _buildButton(label: 'Tiếp tục', isLoading: false, onPressed: _verifyOtp),
        ],
      ),
    );
  }

  Widget _buildStep3(AuthState authState) {
    return Form(
      key: _formKey3,
      child: Column(
        key: const ValueKey('step3'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _stepIcon(Icons.lock_reset_rounded)),
          const SizedBox(height: 20),
          const Text('Đặt mật khẩu mới',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Mật khẩu mới phải có ít nhất 6 ký tự.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildField(
            controller: _newPassController,
            label: 'Mật khẩu mới',
            icon: Icons.lock_outline,
            obscureText: _obscureNew,
            suffix: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppTheme.textSecondary, size: 20),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
              if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _confirmController,
            label: 'Xác nhận mật khẩu',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppTheme.textSecondary, size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
              if (v != _newPassController.text) return 'Mật khẩu không khớp';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildButton(label: 'Đặt lại mật khẩu', isLoading: authState.isLoading, onPressed: authState.isLoading ? null : _resetPassword),
        ],
      ),
    );
  }

  Widget _stepIcon(IconData icon) => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.15),
      shape: BoxShape.circle,
      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5),
    ),
    child: Icon(icon, size: 36, color: AppTheme.primary),
  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8));

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: AppTheme.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.bgSurface,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.accentCoral)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.accentCoral, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildButton({required String label, required bool isLoading, required VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? const LinearGradient(colors: [AppTheme.bgSurfaceLight, AppTheme.bgSurfaceLight])
              : const LinearGradient(colors: [AppTheme.primary, AppTheme.accentPurple], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed == null ? [] : [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.3)),
        ),
      ),
    );
  }
}
