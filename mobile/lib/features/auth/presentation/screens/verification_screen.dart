import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String target;
  final String channel;
  const VerificationScreen({super.key, required this.target, required this.channel});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  Future<void> _sendCode() async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.sendVerification, data: {'target': widget.target, 'channel': widget.channel});
      setState(() => _codeSent = true);
    } catch (_) {}
  }

  Future<void> _verify() async {
    if (_codeController.text.length != 6) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.verifyCode, data: {'target': widget.target, 'code': _codeController.text, 'channel': widget.channel});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doğrulama başarılı!'), backgroundColor: AppColors.success));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Geçersiz kod'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doğrulama')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.verified_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text('Doğrulama Kodu', style: AppTypography.headlineLarge),
            const SizedBox(height: 8),
            Text('${widget.target} adresine gönderilen\n6 haneli kodu giriniz', textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
            if (_codeSent) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('💡 Test kodu: 123456', style: AppTypography.bodySmall.copyWith(color: AppColors.info)),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge.copyWith(letterSpacing: 8),
              decoration: const InputDecoration(counterText: '', hintText: '______'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Doğrula'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _sendCode, child: const Text('Kodu tekrar gönder')),
            TextButton(onPressed: () => context.go('/home'), child: Text('Şimdilik atla', style: TextStyle(color: AppColors.textSecondary))),
          ],
        ),
      ),
    );
  }
}

