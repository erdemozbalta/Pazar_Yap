import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';

class CourierEarningsScreen extends ConsumerStatefulWidget {
  const CourierEarningsScreen({super.key});

  @override
  ConsumerState<CourierEarningsScreen> createState() => _CourierEarningsScreenState();
}

class _CourierEarningsScreenState extends ConsumerState<CourierEarningsScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  double _withdrawnAmountPreview = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiConstants.courierEarnings);
      setState(() {
        _data = res.data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showWithdrawalModal(double totalAvailable) {
    final netAvailable = (totalAvailable - _withdrawnAmountPreview).clamp(0.0, double.infinity);
    final amountC = TextEditingController(text: netAvailable.toStringAsFixed(0));
    String selectedBank = 'Garanti BBVA - TR89 0006 2000 0000 0012 3456 78';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF166534), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text('Hesabıma Para Çek', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Çekilebilir Bakiye', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text('₺${netAvailable.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => setS(() => amountC.text = netAvailable.toStringAsFixed(0)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFECFDF5),
                            foregroundColor: const Color(0xFF059669),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Tümünü Çek', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Banka Hesabı / IBAN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBank,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: const [
                          DropdownMenuItem(
                            value: 'Garanti BBVA - TR89 0006 2000 0000 0012 3456 78',
                            child: Text('🏦 Garanti BBVA (TR89...3456 78)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                          DropdownMenuItem(
                            value: 'Ziraat Bankası - TR12 0001 0000 0000 0098 7654 32',
                            child: Text('🏦 Ziraat Bankası (TR12...7654 32)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                          DropdownMenuItem(
                            value: 'İş Bankası - TR45 0006 4000 0000 0055 4433 22',
                            child: Text('🏦 İş Bankası (TR45...4433 22)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setS(() => selectedBank = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Çekilecek Tutar (₺)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountC,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      hintText: 'Örn: 500',
                      prefixText: '₺ ',
                      prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [100, 250, 500, 1000].map((amt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text('₺$amt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onPressed: () => setS(() => amountC.text = amt.toString()),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final val = double.tryParse(amountC.text.trim());
                        if (val == null || val <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen geçerli bir tutar giriniz'), backgroundColor: AppColors.error),
                          );
                          return;
                        }
                        if (val > netAvailable) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Çekilmek istenen tutar mevcut bakiyenizden büyük olamaz!'), backgroundColor: AppColors.error),
                          );
                          return;
                        }

                        setState(() {
                          _withdrawnAmountPreview += val;
                        });
                        Navigator.pop(ctx);

                        showDialog(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            title: Row(
                              children: const [
                                Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
                                SizedBox(width: 10),
                                Text('Para Çekme Talebi Alındı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            content: Text(
                              '₺${val.toStringAsFixed(2)} tutarındaki ödeme talebiniz $selectedBank hesabınıza aktarılmak üzere sıraya alındı. 💸\n\nTransfer 15 dakika içinde tamamlanacaktır.',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      label: const Text('Para Çekme Talebi Oluştur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCompletedOrderDetailModal(Map<String, dynamic> o) {
    final orderNumber = o['orderNumber'] ?? '';
    final marketName = o['market']?['name'] ?? 'Pazar';
    final customerName = '${o['customer']?['firstName'] ?? ''} ${o['customer']?['lastName'] ?? ''}'.trim();
    final courierFee = (o['courierFee'] as num? ?? 0).toDouble();
    final weight = (o['totalWeight'] as num? ?? 0).toDouble();
    final distance = (o['distanceKm'] as num? ?? 0).toDouble();
    final itemsCount = (o['items'] as List?)?.length ?? 0;
    final dateStr = o['deliveredAt'] != null ? o['deliveredAt'].toString().substring(0, 10) : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tamamlanan Teslimat Detayı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      Text('#$orderNumber', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Teslim Edilen Pazar:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text(marketName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Müşteri:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text(customerName.isEmpty ? 'Kullanıcı' : customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Teslim Tarihi:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net Kazancınız:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text('+₺${courierFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          const Icon(Icons.straighten_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(height: 4),
                          Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          const Text('Mesafe', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          const Icon(Icons.scale_rounded, size: 18, color: Color(0xFFD97706)),
                          const SizedBox(height: 4),
                          Text('${weight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          const Text('Ağırlık', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          const Icon(Icons.shopping_basket_rounded, size: 18, color: Color(0xFF0284C7)),
                          const SizedBox(height: 4),
                          Text('$itemsCount Ürün', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          const Text('Kalem', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _data?['summary'];
    final orders = (_data?['orders'] as List?) ?? [];

    final rawAllTimeEarnings = (summary?['allTimeTotalEarnings'] as num? ?? 0).toDouble();
    final currentBalance = (rawAllTimeEarnings - _withdrawnAmountPreview).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Son Siparişlerim ve Kazançlarım', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ÇEKİLEBİLİR BAKİYE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          Text('₺${currentBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _showWithdrawalModal(currentBalance),
                              icon: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                              label: const Text('Para Çek 💸', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Icon(Icons.history_rounded, color: Color(0xFF0F172A), size: 22),
                        const SizedBox(width: 8),
                        const Text('Son Teslimat Detayları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        const Spacer(),
                        Text('${orders.length} Kayıt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (orders.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.inbox_rounded, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 10),
                            Text('Henüz tamamlanmış teslimatınız yok', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                            SizedBox(height: 4),
                            Text('Teslim ettiğiniz siparişler detaylarıyla burada listelenir.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),

                    ...orders.map((o) {
                      final orderNum = o['orderNumber'] ?? '';
                      final courierFee = (o['courierFee'] as num? ?? 0).toDouble();
                      final weight = (o['totalWeight'] as num? ?? 0).toDouble();
                      final distance = (o['distanceKm'] as num? ?? 0).toDouble();
                      final marketName = o['market']?['name'] ?? 'Pazar';
                      final customerName = '${o['customer']?['firstName'] ?? ''} ${o['customer']?['lastName'] ?? ''}'.trim();
                      final itemsCount = (o['items'] as List?)?.length ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _showCompletedOrderDetailModal(o),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(14)),
                                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 24),
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
                                    const Text('Detay ➔', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}

