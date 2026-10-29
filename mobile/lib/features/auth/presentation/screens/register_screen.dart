import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? role;
  const RegisterScreen({super.key, this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstC = TextEditingController();
  final _lastC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController(text: '+90');
  final _passwordC = TextEditingController();
  late String _selectedRole;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role ?? 'CUSTOMER';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String rawPhone = _phoneC.text.trim();
    String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90') && digits.length == 12) {
      rawPhone = '+$digits';
    } else if (digits.length == 10) {
      rawPhone = '+90$digits';
    } else if (digits.length == 11 && digits.startsWith('0')) {
      rawPhone = '+90${digits.substring(1)}';
    }

    final success = await ref.read(authStateProvider.notifier).register({
      'email': _emailC.text.trim(),
      'password': _passwordC.text,
      'firstName': _firstC.text.trim(),
      'lastName': _lastC.text.trim(),
      'phone': rawPhone,
      'role': _selectedRole,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.push('/verification', extra: {'email': _emailC.text.trim(), 'phone': rawPhone});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(authStateProvider).error ?? 'Kayıt başarısız'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hesap Oluşturun',
                  style: AppTypography.displayLarge.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pazar Yap ailesine katılın',
                  style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _RolePill(
                        title: 'Müşteri',
                        icon: Icons.person_rounded,
                        isSelected: _selectedRole == 'CUSTOMER',
                        onTap: () => setState(() => _selectedRole = 'CUSTOMER'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RolePill(
                        title: 'Kurye',
                        icon: Icons.delivery_dining_rounded,
                        isSelected: _selectedRole == 'COURIER',
                        onTap: () => setState(() => _selectedRole = 'COURIER'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ad', style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _firstC,
                            decoration: const InputDecoration(hintText: 'Adınız'),
                            validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Soyad', style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _lastC,
                            decoration: const InputDecoration(hintText: 'Soyadınız'),
                            validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('E-posta adresi', style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailC,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'ornek@email.com',
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF94A3B8)),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Geçerli e-posta giriniz' : null,
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Telefon Numarası', style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneC,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+90 5XX XXX XX XX',
                    prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF94A3B8)),
                  ),
                  validator: (v) => v == null || v.length < 10 ? 'Geçerli telefon giriniz' : null,
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Şifre', style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordC,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Şifrenizi giriniz',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Şifre gereklidir';
                    if (v.length < 8) return 'Şifre en az 8 karakter olmalıdır';
                    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'En az 1 büyük harf (A-Z) içermelidir';
                    if (!RegExp(r'[a-z]').hasMatch(v)) return 'En az 1 küçük harf (a-z) içermelidir';
                    if (!RegExp(r'[0-9]').hasMatch(v)) return 'En az 1 rakam (0-9) içermelidir';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                Builder(
                  builder: (context) {
                    final pwd = _passwordC.text;
                    final hasMinLength = pwd.length >= 8;
                    final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
                    final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
                    final hasDigit = RegExp(r'[0-9]').hasMatch(pwd);

                    Widget buildReqItem(String label, bool isMet) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            Icon(
                              isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 15,
                              color: isMet ? AppColors.primary : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isMet ? FontWeight.w700 : FontWeight.w500,
                                  color: isMet ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Şifre Gereksinimleri:',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 6),
                          buildReqItem('En az 8 karakter uzunluğunda olmalı', hasMinLength),
                          buildReqItem('En az 1 büyük harf (A-Z) içermeli', hasUpper),
                          buildReqItem('En az 1 küçük harf (a-z) içermeli', hasLower),
                          buildReqItem('En az 1 rakam (0-9) içermeli', hasDigit),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Kayıt Ol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Zaten hesabınız var mı?', style: TextStyle(color: Color(0xFF64748B))),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: Text(
                        'Giriş Yapın',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RolePill({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : const Color(0xFF64748B), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryDark : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

