import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiConstants.orders}/${widget.orderId}');
      if (mounted) {
        setState(() {
          _order = res.data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('Siparişi İptal Et', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text('Bu siparişi iptal etmek istediğinizden emin misiniz? Ödemeniz kartınıza iade edilecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(false),
            child: const Text('Vazgeç', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(true),
            child: const Text('Evet, İptal Et', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.post('${ApiConstants.orders}/${widget.orderId}/cancel');
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sipariş başarıyla iptal edildi.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        final err = (e as dynamic).response?.data?['error'] ?? 'İptal işlemi başarısız';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ $err'), backgroundColor: AppColors.error));
      }
    }
  }

  int _getStepIndex(String status) {
    switch (status) {
      case 'PAYMENT_PENDING':
      case 'SEARCHING_COURIER':
      case 'COURIER_ASSIGNED':
        return 1;
      case 'SHOPPING_IN_PROGRESS':
      case 'COLLECTING':
      case 'ITEMS_COLLECTED':
        return 2;
      case 'ON_THE_WAY':
        return 3;
      case 'DELIVERED':
        return 4;
      case 'CANCELLED':
        return -1;
      default:
        return 1;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'PAYMENT_PENDING':
      case 'SEARCHING_COURIER':
      case 'COURIER_ASSIGNED':
        return 'Sipariş Kuryeye Ulaştı 🛵';
      case 'SHOPPING_IN_PROGRESS':
      case 'COLLECTING':
      case 'ITEMS_COLLECTED':
        return 'Ürünler Toplanıyor 🧺';
      case 'ON_THE_WAY':
        return 'Kurye Yola Çıktı 🚀';
      case 'DELIVERED':
        return 'Teslim Edildi ✅';
      case 'CANCELLED':
        return 'Sipariş İptal Edildi ❌';
      default:
        return 'Sipariş Hazırlanıyor ⏳';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'PAYMENT_PENDING':
      case 'SEARCHING_COURIER':
      case 'COURIER_ASSIGNED':
        return 'Siparişiniz kuryemize ulaştı. Kuryeniz pazarda ürün hazırlıklarına başladı.';
      case 'SHOPPING_IN_PROGRESS':
      case 'COLLECTING':
      case 'ITEMS_COLLECTED':
        return 'Kuryeniz taze pazar ürünlerinizi pazardaki tezgahlardan özenle tek tek topluyor.';
      case 'ON_THE_WAY':
        return 'Tüm ürünleriniz toplandı ve paketlendi. Kuryeniz adresinize teslim etmek üzere yola çıktı!';
      case 'DELIVERED':
        return 'Siparişiniz adresinize başarıyla teslim edilmiştir. Afiyet olsun!';
      case 'CANCELLED':
        return 'Bu sipariş iptal edilmiştir. İade tutarı bankanıza iletilmiştir.';
      default:
        return 'Sipariş durumunuz güncellenmektedir.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNum = _order?['orderNumber'] ?? '';
    final status = _order?['status'] ?? '';
    final items = (_order?['items'] as List?) ?? [];
    final marketName = _order?['market']?['name'] ?? 'Semt Pazarı';
    final marketAddress = _order?['market']?['fullAddress'] ?? '';
    final courier = _order?['courier'];
    final canCancel = ['PAYMENT_PENDING', 'SEARCHING_COURIER', 'COURIER_ASSIGNED', 'SHOPPING_IN_PROGRESS'].contains(status);
    final currentStep = _getStepIndex(status);

    final subtotal = (_order?['subtotal'] as num? ?? 0).toDouble();
    final courierFee = (_order?['courierFee'] as num? ?? 0).toDouble();
    final serviceFee = (_order?['serviceFee'] as num? ?? subtotal * 0.05).toDouble();
    final totalAmount = (_order?['totalAmount'] as num? ?? 0).toDouble();
    final totalWeight = (_order?['totalWeight'] as num? ?? 0).toDouble();
    final distanceKm = (_order?['distanceKm'] as num? ?? 0).toDouble();

    final collectedCount = items.where((i) => i['isCollected'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('#$orderNum', style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/orders');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: status == 'CANCELLED'
                            ? const LinearGradient(colors: [Color(0xFFBE123C), Color(0xFFE11D48)])
                            : AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: (status == 'CANCELLED' ? AppColors.error : AppColors.primary).withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status == 'DELIVERED' ? 'TESLİM EDİLDİ' : (status == 'CANCELLED' ? 'İPTAL EDİLDİ' : 'CANLI TAKİP ⚡'),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ),
                              const Spacer(),
                              if (status != 'DELIVERED' && status != 'CANCELLED')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('⏱️ Tahmini 20-30 dk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _getStatusTitle(status),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getStatusDescription(status),
                            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                          ),
                          const SizedBox(height: 20),

                          if (status != 'CANCELLED') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStepNode(1, 'Kuryeye Ulaştı', currentStep),
                                _buildStepConnector(1, currentStep),
                                _buildStepNode(2, 'Toplanıyor', currentStep),
                                _buildStepConnector(2, currentStep),
                                _buildStepNode(3, 'Yola Çıktı', currentStep),
                                _buildStepConnector(3, currentStep),
                                _buildStepNode(4, 'Teslim Edildi', currentStep),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (courier != null) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 30),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Görevli Kuryeniz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${courier['firstName']} ${courier['lastName']}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('Pazar Kuryesi 🛵', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                final phone = courier['phone'] ?? 'Belirtilmedi';
                                showDialog(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Row(
                                      children: const [
                                        Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 26),
                                        SizedBox(width: 10),
                                        Text('Kuryeyi Ara', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                    content: Text('Kurye Telefon Numarası:\n\n📞 $phone', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(dialogCtx),
                                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                        child: const Text('Tamam'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.phone_rounded, size: 16, color: Colors.white),
                              label: const Text('Ara', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(marketName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                    if (marketAddress.isNotEmpty)
                                      Text(marketAddress, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.straighten_rounded, size: 15, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text('${distanceKm.toStringAsFixed(1)} km mesafe', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.scale_rounded, size: 15, color: Color(0xFFD97706)),
                                      const SizedBox(width: 4),
                                      Text('${totalWeight.toStringAsFixed(1)} kg ağırlık', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (status == 'SHOPPING_IN_PROGRESS' || status == 'COLLECTING' || status == 'ITEMS_COLLECTED' || status == 'COURIER_ASSIGNED') ...[
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: items.isEmpty ? 0 : (collectedCount / items.length),
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: AppColors.primary,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '🧺 Tezgahlardan Toplanan Ürünler: $collectedCount / ${items.length}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Sipariş Edilen Ürünler', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),

                    ...items.map((item) {
                      final vp = item['vendorProduct'];
                      final prodName = vp?['product']?['name'] ?? 'Ürün';
                      final vendorName = vp?['vendor']?['name'] ?? 'Tezgah';
                      final unit = vp?['product']?['unit'] ?? 'kg';
                      final qty = (item['quantity'] as num? ?? 1).toDouble();
                      final price = (item['totalPrice'] as num? ?? 0).toDouble();
                      final isCollected = item['isCollected'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCollected ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isCollected ? Icons.check_circle_rounded : Icons.shopping_basket_rounded,
                                color: isCollected ? AppColors.primary : const Color(0xFF64748B),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prodName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 2),
                                  Text('$vendorName • ${qty.toStringAsFixed(1)} $unit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                  if (item['note'] != null && item['note'].toString().isNotEmpty)
                                    Text('📝 ${item['note']}', style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                                ],
                              ),
                            ),
                            Text('₺${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ödeme Özeti & Fiş', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          const SizedBox(height: 12),
                          _buildReceiptRow('Ürünler Tutarı', '₺${subtotal.toStringAsFixed(2)}'),
                          _buildReceiptRow('Mesafe & Ağırlık Kurye Ücreti', '₺${courierFee.toStringAsFixed(2)}'),
                          _buildReceiptRow('Hizmet Bedeli (%5)', '₺${serviceFee.toStringAsFixed(2)}'),
                          const Divider(height: 22),
                          _buildReceiptRow('Toplam Tutar', '₺${totalAmount.toStringAsFixed(2)}', isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (canCancel)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _cancelOrder,
                          icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                          label: const Text('Siparişi İptal Et', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepNode(int step, String label, int currentStep) {
    final isDone = currentStep > step;
    final isCurrent = currentStep == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone || isCurrent ? Colors.white : Colors.white24,
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                  ]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isCurrent ? AppColors.primary : Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
            color: isCurrent ? Colors.white : Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int step, int currentStep) {
    final isPassed = currentStep > step;
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 18),
        color: isPassed ? Colors.white : Colors.white24,
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 15 : 13, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: isBold ? AppColors.primary : const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

