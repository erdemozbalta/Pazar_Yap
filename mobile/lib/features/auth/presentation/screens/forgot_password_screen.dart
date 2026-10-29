import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailC = TextEditingController();
  final _codeC = TextEditingController();
  final _newPasswordC = TextEditingController();
  bool _isLoading = false;
  int _step = 0;

  Future<void> _sendResetCode() async {
    if (_emailC.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.forgotPassword, data: {'email': _emailC.text.trim()});
      setState(() => _step = 1);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sıfırlama kodu gönderildi (Test: 123456)'), backgroundColor: AppColors.info));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bir hata oluştu'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_codeC.text.length != 6 || _newPasswordC.text.length < 8) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.resetPassword, data: {'email': _emailC.text.trim(), 'code': _codeC.text, 'newPassword': _newPasswordC.text});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre sıfırlandı! Giriş yapabilirsiniz.'), backgroundColor: AppColors.success));
        context.go('/login');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçersiz kod veya hata'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Icon(Icons.lock_reset_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(_step == 0 ? 'E-posta adresinizi girin' : 'Kodu ve yeni şifrenizi girin', textAlign: TextAlign.center, style: AppTypography.headlineMedium),
            const SizedBox(height: 32),
            if (_step == 0) ...[
              TextFormField(controller: _emailC, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 24),
              SizedBox(height: 56, child: ElevatedButton(onPressed: _isLoading ? null : _sendResetCode, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kod Gönder'))),
            ] else ...[
              TextFormField(controller: _codeC, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Doğrulama Kodu', prefixIcon: Icon(Icons.pin_outlined), counterText: '')),
              const SizedBox(height: 16),
              TextFormField(controller: _newPasswordC, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni Şifre', prefixIcon: Icon(Icons.lock_outlined))),
              const SizedBox(height: 24),
              SizedBox(height: 56, child: ElevatedButton(onPressed: _isLoading ? null : _resetPassword, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Şifreyi Sıfırla'))),
            ],
          ],
        ),
      ),
    );
  }
}

