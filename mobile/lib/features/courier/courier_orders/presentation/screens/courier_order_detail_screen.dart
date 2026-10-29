import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';

class CourierOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const CourierOrderDetailScreen({super.key, required this.orderId});
  @override
  ConsumerState<CourierOrderDetailScreen> createState() => _CourierOrderDetailScreenState();
}

class _CourierOrderDetailScreenState extends ConsumerState<CourierOrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _actionLoading = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiConstants.orders}/${widget.orderId}');
      setState(() { _order = res.data; _isLoading = false; });
    } catch (_) { setState(() => _isLoading = false); }
  }

  Future<void> _action(String action) async {
    if (action == 'on-the-way') {
      final items = (_order?['items'] as List?) ?? [];
      final uncollected = items.where((i) => i['isCollected'] != true).toList();
      if (uncollected.isNotEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Lütfen tüm ürünleri aldığınızı onaylayınız! (${uncollected.length} ürün eksik)'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    setState(() => _actionLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('${ApiConstants.orders}/${widget.orderId}/$action');
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'deliver' ? '🎉 Sipariş başarıyla teslim edildi!' : 'İşlem başarıyla gerçekleştirildi',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final err = (e as dynamic).response?.data?['error'] ?? 'Hata oluştu, lütfen tekrar deneyiniz';
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $err'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _collectItem(String itemId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('${ApiConstants.orders}/${widget.orderId}/items/$itemId/collect');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final items = (_order?['items'] as List?) ?? [];
    final status = _order?['status'] ?? '';
    final customer = _order?['customer'];
    final address = _order?['address'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_order?['orderNumber'] ?? 'Sipariş Detayı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/courier');
            }
          },
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (status == 'DELIVERED') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF15803D), Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 48),
                  SizedBox(height: 10),
                  Text(
                    'Sipariş Başarıyla Teslim Edildi! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Teslimat ücretiniz bakiyenize aktarılmıştır. Aşağıdaki yeşil butona basarak anasayfaya dönebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (customer != null) Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Müşteri Bilgileri', style: AppTypography.labelSmall),
              Text('${customer['firstName']} ${customer['lastName']}', style: AppTypography.titleMedium),
              Text(customer['phone'] ?? '', style: AppTypography.bodySmall),
              if (address != null) ...[
                const Divider(height: 16),
                Text('Teslimat Adresi', style: AppTypography.labelSmall),
                Text(address['title'] ?? '', style: AppTypography.titleMedium),
                Text(address['fullAddress'] ?? '', style: AppTypography.bodySmall),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          if (_order?['notes'] != null && _order!['notes'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.notes_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sipariş Notu', style: AppTypography.labelLarge),
                  Text(_order!['notes'], style: AppTypography.bodySmall),
                ])),
              ]),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ürün Listesi', style: AppTypography.headlineMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: items.every((i) => i['isCollected'] == true) ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Toplanan: ${items.where((i) => i['isCollected'] == true).length}/${items.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: items.every((i) => i['isCollected'] == true) ? const Color(0xFF166534) : const Color(0xFF92400E),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final vp = item['vendorProduct'];
            final collected = item['isCollected'] == true;
            final stallLoc = vp?['stallLocation'] ?? 'Tezgah konumu belirtilmemiş';
            final vendorName = vp?['vendor']?['name'] ?? 'Satıcı';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  if (status != 'SHOPPING_IN_PROGRESS') {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Ürünleri işaretleyebilmek için lütfen önce en alttaki "Alışverişe Başla" butonuna basınız!'),
                        backgroundColor: AppColors.error,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  _collectItem(item['id']);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: collected ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: collected ? AppColors.primary : const Color(0xFFE2E8F0), width: collected ? 2 : 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Checkbox(
                          value: collected,
                          onChanged: status == 'SHOPPING_IN_PROGRESS'
                              ? (_) => _collectItem(item['id'])
                              : (_) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('⚠️ Ürünleri işaretleyebilmek için lütfen önce en alttaki "Alışverişe Başla" butonuna basınız!'),
                                      backgroundColor: AppColors.error,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                },
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              vp?['product']?['name'] ?? '',
                              style: AppTypography.titleMedium.copyWith(
                                decoration: collected ? TextDecoration.lineThrough : null,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text('$vendorName • ${(item['quantity'] as num).toStringAsFixed(1)} ${vp?['product']?['unit'] ?? 'kg'}', style: AppTypography.bodySmall),
                          ]),
                        ),
                        Text('₺${(item['totalPrice'] as num).toStringAsFixed(2)}', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tezgah Konumu: $stallLoc',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item['note'] != null && item['note'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                          child: Text('📝 Müşteri Notu: ${item['note']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ürün Toplamı', style: AppTypography.bodyMedium), Text('₺${(_order?['subtotal'] as num? ?? 0).toStringAsFixed(2)}', style: AppTypography.titleMedium)]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Kurye Teslimat Kazancınız', style: AppTypography.bodyMedium), Text('₺${(_order?['courierFee'] as num? ?? 0).toStringAsFixed(2)}', style: AppTypography.priceSmall)]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Uygulama Komisyonu (%5)', style: AppTypography.bodyMedium), Text('₺${((_order?['serviceFee'] as num?)?.toDouble() ?? ((_order?['subtotal'] as num? ?? 0) * 0.05)).toStringAsFixed(2)}', style: AppTypography.titleMedium)]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Teslimat Mesafesi', style: AppTypography.bodyMedium), Text('${(_order?['distanceKm'] as num? ?? 0).toStringAsFixed(1)} km', style: AppTypography.titleMedium)]),
            ]),
          ),
          const SizedBox(height: 24),
        ]),
      ),
      bottomNavigationBar: _isLoading ? null : SafeArea(child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildActionButton(status),
      )),
    );
  }

  Widget _buildActionButton(String status) {
    switch (status) {
      case 'SEARCHING_COURIER':
        return SizedBox(height: 56, child: ElevatedButton.icon(
          onPressed: _actionLoading ? null : () => _action('accept'),
          icon: const Icon(Icons.check_rounded),
          label: Text(_actionLoading ? 'İşleniyor...' : 'Siparişi Kabul Et'),
        ));
      case 'COURIER_ASSIGNED':
        return SizedBox(height: 56, child: ElevatedButton.icon(
          onPressed: _actionLoading ? null : () => _action('start-shopping'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
          icon: const Icon(Icons.shopping_bag_rounded),
          label: Text(_actionLoading ? 'İşleniyor...' : 'Alışverişe Başla'),
        ));
      case 'SHOPPING_IN_PROGRESS':
        return SizedBox(height: 56, child: ElevatedButton.icon(
          onPressed: _actionLoading ? null : () => _action('on-the-way'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
          icon: const Icon(Icons.delivery_dining_rounded),
          label: Text(_actionLoading ? 'İşleniyor...' : 'Yola Çıktım 🚀'),
        ));
      case 'ON_THE_WAY':
        return SizedBox(height: 56, child: ElevatedButton.icon(
          onPressed: _actionLoading ? null : () => _action('deliver'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          icon: const Icon(Icons.check_circle_rounded),
          label: Text(_actionLoading ? 'İşleniyor...' : 'Teslim Ettim ✅'),
        ));
      case 'DELIVERED':
        return SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              context.go('/courier');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            icon: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
            label: const Text(
              'Sipariş Tamamlandı - Anasayfaya Dön',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

