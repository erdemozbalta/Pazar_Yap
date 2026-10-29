import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

import '../../../../shared/providers/auth_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiConstants.orders);
      setState(() {
        _orders = res.data['orders'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return AppColors.statusDelivered;
      case 'CANCELLED':
        return AppColors.statusCancelled;
      default:
        return AppColors.primary;
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'DELIVERED':
        return 'Sipariş Tamamlandı ✅';
      case 'CANCELLED':
        return 'Sipariş İptal Oldu ❌';
      default:
        return 'Sipariş Devam Ediyor 🚚';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isStaffOrAdmin = auth.userRole == 'ADMIN' || auth.userRole == 'EMPLOYEE';
    final pageTitle = isStaffOrAdmin
        ? 'Sistem Sipariş Yönetimi'
        : (auth.userRole == 'COURIER' ? 'Teslimat Siparişlerim' : 'Sipariş Geçmişim');

    final emptyTitle = isStaffOrAdmin
        ? 'Sistemde Sipariş Bulunmuyor'
        : (auth.userRole == 'COURIER' ? 'Atanmış Sipariş Yok' : 'Henüz Siparişiniz Yok');

    final emptySubtitle = isStaffOrAdmin
        ? 'Pazar Yap platformu genelinde henüz sipariş oluşturulmamıştır.'
        : (auth.userRole == 'COURIER'
            ? 'Size henüz atanmış aktif bir teslimat bulunmamaktadır.'
            : 'Verdiğiniz siparişler burada listelenecektir.');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(pageTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_rounded, size: 44, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 20),
                      Text(emptyTitle, style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          emptySubtitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                    itemCount: _orders.length,
                    itemBuilder: (context, i) {
                      final o = _orders[i];
                      final status = o['status'] ?? '';
                      final items = (o['items'] as List?) ?? [];
                      final statusColor = _statusColor(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    o['orderNumber'] ?? '',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _translateStatus(status),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    o['market']?['name'] ?? 'Pazar',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.shopping_bag_outlined, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  '${items.length} Kalem',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  '₺${(o['totalAmount'] as num? ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/order/${o['id']}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primarySurface,
                                    foregroundColor: AppColors.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                  label: const Text('Detaylar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

