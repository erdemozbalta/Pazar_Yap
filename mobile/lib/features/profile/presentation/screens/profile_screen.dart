import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showChangePasswordModal() {
    final currentPassC = TextEditingController();
    final newPassC = TextEditingController();
    final confirmPassC = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 40),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Text('Şifre Değiştir', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentPassC,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mevcut Şifre',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassC,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Yeni Güçlü Şifre',
                    hintText: 'En az 8 karakter',
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setModalState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre Tekrarı',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (currentPassC.text.isEmpty || newPassC.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lütfen tüm alanları doldurunuz')),
                        );
                        return;
                      }
                      if (newPassC.text != confirmPassC.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yeni şifreler eşleşmiyor!'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      if (newPassC.text.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yeni şifre en az 8 karakter olmalıdır'), backgroundColor: AppColors.error),
                        );
                        return;
                      }

                      try {
                        final api = ref.read(apiClientProvider);
                        await api.post('/auth/change-password', data: {
                          'currentPassword': currentPassC.text,
                          'newPassword': newPassC.text,
                        });
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Şifreniz başarıyla değiştirildi! 🔒'), backgroundColor: AppColors.success),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          final err = (e as dynamic).response?.data?['error'] ?? 'Şifre değiştirme başarısız';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    child: const Text('Şifreyi Güncelle', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpSupportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Text('Destek ve Yardım', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Sorularınız, önerileriniz veya destek talepleriniz için aşağıdaki iletişim kanallarından bize ulaşabilirsiniz:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.email_outlined, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('E-Posta Adresi', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        SelectableText('erdemozbalta@pazaryap.com', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.phone_outlined, color: Color(0xFF16A34A), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Telefon / Destek Hattı', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        SelectableText('+901111111111', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    );
  }

  void _showPrivacyPolicyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Text('Gizlilik ve Üyelik Sözleşmesi', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 17)),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Taraflar ve Amaç\n'
                'Pazar Yap platformu, müşteriler ile semt pazarlarındaki esnafları ve kuryeleri buluşturan bir pazaryeri hizmetidir.\n\n'
                '2. Kişisel Verilerin Korunması\n'
                '6698 sayılı KVKK uyarınca, kişisel verileriniz (ad, soyad, adres, e-posta) siparişlerin teslimatı ve üyelik işlemlerinin yürütülmesi amacıyla işlenmektedir.\n\n'
                '3. Sipariş ve Teslimat Koşulları\n'
                'Siparişleriniz atanan kuryeler tarafından pazar tezgahlarından taze olarak toplanıp belirttiğiniz adrese ulaştırılır.\n\n'
                '4. Gizlilik Esasları\n'
                'Verileriniz üçüncü şahıslarla reklam amacıyla asla paylaşılmaz.',
                style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final initial = (auth.userName ?? 'U').substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profilim', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 36,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              auth.userName ?? 'Kullanıcı',
              style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              auth.userEmail ?? 'ornek@email.com',
              style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 28),

            const _SectionHeader(title: 'Hesap Ayarları'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (auth.userRole == 'CUSTOMER') ...[
                    _ProfileSettingTile(
                      icon: Icons.location_on_outlined,
                      title: 'Adres Bilgilerim',
                      onTap: () => context.push('/addresses'),
                    ),
                    const _TileDivider(),
                    _ProfileSettingTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sipariş Geçmişim',
                      onTap: () => context.go('/orders'),
                    ),
                    const _TileDivider(),
                  ],
                  if (auth.userRole == 'COURIER') ...[
                    _ProfileSettingTile(
                      icon: Icons.payments_outlined,
                      title: 'Kazançlarım',
                      onTap: () => context.push('/courier/earnings'),
                    ),
                    const _TileDivider(),
                    _ProfileSettingTile(
                      icon: Icons.price_change_outlined,
                      title: 'Ücretlendirme Ayarlarım',
                      onTap: () => context.push('/courier/pricing'),
                    ),
                    const _TileDivider(),
                  ],
                  _ProfileSettingTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Şifre Değiştir',
                    onTap: _showChangePasswordModal,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _SectionHeader(title: 'Diğer'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ProfileSettingTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Destek ve Yardım',
                    onTap: _showHelpSupportModal,
                  ),
                  const _TileDivider(),
                  _ProfileSettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Gizlilik ve Üyelik Sözleşmesi',
                    onTap: _showPrivacyPolicyModal,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Çıkış Yap'),
                      content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Vazgeç'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () {
                            Navigator.pop(ctx);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ref.read(authStateProvider.notifier).logout();
                            });
                          },
                          child: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: Color(0xFFFECDD3), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: const Color(0xFFFFF1F2),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Oturumu Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: const Color(0xFF334155),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileSettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 60,
      endIndent: 20,
      color: Color(0xFFF1F5F9),
    );
  }
}

