import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';

class CourierOrdersScreen extends ConsumerStatefulWidget {
  const CourierOrdersScreen({super.key});

  @override
  ConsumerState<CourierOrdersScreen> createState() => _CourierOrdersScreenState();
}

class _CourierOrdersScreenState extends ConsumerState<CourierOrdersScreen> {
  List<dynamic> _pendingOrders = [];
  List<dynamic> _completedOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final resPending = await api.get(ApiConstants.courierPending);
      final resEarnings = await api.get(ApiConstants.courierEarnings);
      if (mounted) {
        setState(() {
          _pendingOrders = resPending.data['orders'] ?? [];
          _completedOrders = resEarnings.data['orders'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Siparişlerim', style: TextStyle(fontWeight: FontWeight.w700)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Color(0xFF64748B),
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: [
              Tab(text: 'Bekleyen & Aktif'),
              Tab(text: 'Tamamlananlar'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [

                  _buildPendingOrdersList(),

                  _buildCompletedOrdersList(),
                ],
              ),
      ),
    );
  }

  Widget _buildPendingOrdersList() {
    if (_pendingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty_rounded, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Bekleyen sipariş yok', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Müsait olduğunuzda yeni siparişler burada görünecektir', textAlign: TextAlign.center, style: AppTypography.bodySmall),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Yenile')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: _pendingOrders.length,
        itemBuilder: (_, i) {
          final o = _pendingOrders[i];
          final status = o['status'] ?? '';
          final items = (o['items'] as List?) ?? [];
          final isUnassigned = status == 'SEARCHING_COURIER';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => context.go('/courier/order/${o['id']}'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isUnassigned ? AppColors.primary : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isUnassigned)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                            child: const Text('YENİ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Müşteri: ${o['customer']?['firstName'] ?? ''} ${o['customer']?['lastName'] ?? ''}'.trim(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${items.length} Kalem Ürün • ${(o['totalWeight'] as num? ?? 0).toStringAsFixed(1)} kg',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '₺${(o['courierFee'] as num? ?? 0).toStringAsFixed(2)} Kazanç',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                        const Spacer(),
                        if (o['distanceKm'] != null)
                          Text('${(o['distanceKm'] as num).toStringAsFixed(1)} km mesafe', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletedOrdersList() {
    if (_completedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history_rounded, size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text('Henüz teslim edilmiş sipariş yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            SizedBox(height: 8),
            Text('Tamamladığınız teslimatlar bu sekmede detaylarıyla saklanır', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: _completedOrders.length,
        itemBuilder: (_, i) {
          final o = _completedOrders[i];
          final orderNum = o['orderNumber'] ?? '';
          final courierFee = (o['courierFee'] as num? ?? 0).toDouble();
          final weight = (o['totalWeight'] as num? ?? 0).toDouble();
          final distance = (o['distanceKm'] as num? ?? 0).toDouble();
          final marketName = o['market']?['name'] ?? 'Pazar';
          final customerName = '${o['customer']?['firstName'] ?? ''} ${o['customer']?['lastName'] ?? ''}'.trim();
          final itemsCount = (o['items'] as List?)?.length ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => context.push('/courier/earnings'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#$orderNum', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          const SizedBox(height: 2),
                          Text('$marketName ${customerName.isNotEmpty ? "• $customerName" : ""}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                          const SizedBox(height: 4),
                          Text('${weight.toStringAsFixed(1)} kg • ${distance.toStringAsFixed(1)} km ${itemsCount > 0 ? "• $itemsCount Ürün" : ""}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('+₺${courierFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        const Text('Teslim Edildi ✅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

