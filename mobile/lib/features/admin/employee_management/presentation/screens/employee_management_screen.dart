import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';

class EmployeeManagementScreen extends ConsumerStatefulWidget {
  const EmployeeManagementScreen({super.key});
  @override
  ConsumerState<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends ConsumerState<EmployeeManagementScreen> {
  List<dynamic> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiConstants.adminUsers, queryParameters: {'role': 'EMPLOYEE'});
      setState(() {
        _employees = res.data['users'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(String userId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('${ApiConstants.adminUsers}/$userId/toggle');
      _load();
    } catch (e) {
      if (mounted) {
        final err = (e as dynamic).response?.data?['error'] ?? 'İşlem başarısız';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çalışanı Sil'),
        content: Text('$name isimli çalışan hesabını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.delete('${ApiConstants.adminUsers}/$userId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çalışan hesabı silindi'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silme işlemi başarısız'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showCreateForm() {
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    final passwordC = TextEditingController();
    final firstC = TextEditingController();
    final lastC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Yeni Çalışan Hesabı Oluştur', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            const Text('Çalışan bu e-posta ve şifre ile sisteme giriş yapabilir.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: firstC,
                          decoration: const InputDecoration(labelText: 'Ad *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Zorunlu' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lastC,
                          decoration: const InputDecoration(labelText: 'Soyad *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Zorunlu' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-posta *', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => v == null || !v.contains('@') ? 'Geçerli e-posta giriniz' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneC,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefon *', hintText: '5XX XXX XX XX', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (v) => v == null || v.trim().length < 10 ? 'Geçerli telefon giriniz' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordC,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Şifre *',
                      hintText: 'En az 8 krk (Büyük/Küçük harf + Rakam)',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Şifre gereklidir';
                      if (v.length < 8) return 'En az 8 karakter olmalıdır';
                      if (!RegExp(r'[A-Z]').hasMatch(v)) return 'En az 1 büyük harf (A-Z) içermelidir';
                      if (!RegExp(r'[a-z]').hasMatch(v)) return 'En az 1 küçük harf (a-z) içermelidir';
                      if (!RegExp(r'[0-9]').hasMatch(v)) return 'En az 1 rakam (0-9) içermelidir';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        try {
                          final api = ref.read(apiClientProvider);
                          String rawPhone = phoneC.text.trim();
                          String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
                          if (digits.startsWith('90') && digits.length == 12) {
                            rawPhone = '+$digits';
                          } else if (digits.length == 10) {
                            rawPhone = '+90$digits';
                          } else if (digits.length == 11 && digits.startsWith('0')) {
                            rawPhone = '+90${digits.substring(1)}';
                          }

                          await api.post(ApiConstants.adminStaff, data: {
                            'email': emailC.text.trim(),
                            'phone': rawPhone,
                            'password': passwordC.text,
                            'firstName': firstC.text.trim(),
                            'lastName': lastC.text.trim(),
                            'role': 'EMPLOYEE',
                          });
                          if (mounted) {
                            Navigator.pop(ctx);
                            _load();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Çalışan hesabı başarıyla oluşturuldu!'), backgroundColor: AppColors.primary),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            final err = (e as dynamic).response?.data?['error'] ?? 'Çalışan oluşturulamadı';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Hata: $err'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                      child: const Text('Çalışan Hesabını Oluştur', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Çalışan Yönetimi', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 95),
        child: FloatingActionButton.extended(
          onPressed: _showCreateForm,
          backgroundColor: const Color(0xFF10B981),
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Yeni Çalışan Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                        child: const Icon(Icons.badge_outlined, size: 64, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Henüz sisteme kayıtlı çalışan yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showCreateForm,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Çalışan Ekle', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                  itemCount: _employees.length,
                  itemBuilder: (_, i) {
                    final e = _employees[i];
                    final isActive = e['isActive'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primarySurface,
                            child: const Icon(Icons.badge_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${e['firstName']} ${e['lastName']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                const SizedBox(height: 2),
                                Text(e['email'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                Text(e['phone'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                                onPressed: () => _deleteUser(e['id'], '${e['firstName']} ${e['lastName']}'),
                                tooltip: 'Çalışanı Sil',
                              ),
                              Switch(
                                value: isActive,
                                activeColor: AppColors.primary,
                                onChanged: (_) => _toggleStatus(e['id']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

