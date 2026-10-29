import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});
  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabC;
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _roleFilter = '';
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabC = TabController(length: 5, vsync: this);
    _tabC.addListener(_onTabChange);
    _load();
  }

  @override
  void dispose() {
    _tabC.dispose();
    _searchC.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tabC.indexIsChanging) return;
    final newRole = ['', 'CUSTOMER', 'COURIER', 'EMPLOYEE', 'ADMIN'][_tabC.index];
    if (_roleFilter != newRole) {
      _roleFilter = newRole;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final params = <String, dynamic>{};
      if (_roleFilter.isNotEmpty) params['role'] = _roleFilter;
      if (_searchC.text.trim().isNotEmpty) params['search'] = _searchC.text.trim();

      final res = await api.get(ApiConstants.adminUsers, queryParameters: params);
      setState(() {
        _users = res.data['users'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleUser(String userId) async {
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

  Future<void> _deleteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kullanıcıyı Sil'),
        content: Text('$userName adlı kullanıcıyı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.delete('${ApiConstants.adminUsers}/$userId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı başarıyla silindi'), backgroundColor: AppColors.success),
          );
        }
        _load();
      } catch (e) {
        if (mounted) {
          final err = (e as dynamic).response?.data?['error'] ?? 'Silme işlemi başarısız';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err.toString()), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFF8B5CF6);
      case 'EMPLOYEE':
        return const Color(0xFF10B981);
      case 'COURIER':
        return const Color(0xFFF59E0B);
      case 'CUSTOMER':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'EMPLOYEE':
        return 'Çalışan';
      case 'COURIER':
        return 'Kurye';
      case 'CUSTOMER':
      default:
        return 'Müşteri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchC,
                  onChanged: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Ad, e-posta veya telefon ile ara...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchC.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchC.clear();
                              _load();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
              TabBar(
                controller: _tabC,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                onTap: (index) {
                  final newRole = ['', 'CUSTOMER', 'COURIER', 'EMPLOYEE', 'ADMIN'][index];
                  if (_roleFilter != newRole) {
                    _roleFilter = newRole;
                    _load();
                  }
                },
                tabs: const [
                  Tab(text: 'Tümü'),
                  Tab(text: 'Müşteriler'),
                  Tab(text: 'Kuryeler'),
                  Tab(text: 'Çalışanlar'),
                  Tab(text: 'Adminler'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.person_search_rounded, size: 64, color: Color(0xFF94A3B8)),
                      SizedBox(height: 12),
                      Text('Aramanıza uygun kullanıcı bulunamadı', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final isActive = u['isActive'] == true;
                    final role = u['role'] ?? 'CUSTOMER';
                    final roleColor = _getRoleColor(role);

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
                            backgroundColor: roleColor.withValues(alpha: 0.12),
                            child: Text(
                              (u['firstName'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(color: roleColor, fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${u['firstName']} ${u['lastName']}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: roleColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getRoleLabel(role),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(u['email'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                Text(u['phone'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                                onPressed: () => _deleteUser(u['id'], '${u['firstName']} ${u['lastName']}'),
                                tooltip: 'Kullanıcıyı Sil',
                              ),
                              Switch(
                                value: isActive,
                                activeColor: AppColors.primary,
                                onChanged: (_) => _toggleUser(u['id']),
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

