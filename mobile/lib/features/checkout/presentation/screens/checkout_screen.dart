import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  List<dynamic> _addresses = [];
  String? _selectedAddressId;
  final _notesC = TextEditingController();
  Map<String, dynamic>? _preview;
  bool _isLoading = true;
  bool _isLoadingPreview = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ref.read(apiClientProvider);
      final addrRes = await api.get(ApiConstants.addresses);

      if (addrRes.data is List) {
        _addresses = addrRes.data;
      } else if (addrRes.data is Map && addrRes.data['addresses'] != null) {
        _addresses = addrRes.data['addresses'];
      } else {
        _addresses = [];
      }

      if (_addresses.isNotEmpty) {
        final def = _addresses.firstWhere((a) => a['isDefault'] == true, orElse: () => _addresses.first);
        _selectedAddressId = def['id'];
      }

      setState(() => _isLoading = false);
      await _loadPreview();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPreview() async {
    try {
      setState(() => _isLoadingPreview = true);
      final api = ref.read(apiClientProvider);
      final res = await api.post('/orders/checkout-preview', data: {
        'addressId': _selectedAddressId,
      });
      if (mounted) {
        setState(() {
          _preview = res.data;
          _isLoadingPreview = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _createOrder() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir teslimat adresi seçiniz'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final hasCourier = _preview?['hasAvailableCourier'] == true;
    if (!hasCourier) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şu an bu pazarda aktif kurye bulunmuyor. Ödeme adımına geçilemez.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(ApiConstants.orders, data: {
        'addressId': _selectedAddressId,
        'notes': _notesC.text.isNotEmpty ? _notesC.text : null,
      });
      ref.read(cartItemCountProvider.notifier).updateCount(0);
      ref.read(cartItemCountProvider.notifier).refreshCartCount();
      if (mounted) context.push('/payment/${res.data['order']['id']}');
    } catch (e) {
      if (mounted) {
        final err = (e as dynamic).response?.data?['error'] ?? 'Sipariş oluşturulamadı';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCourier = _preview?['hasAvailableCourier'] == true;
    final courierName = _preview?['courierName'] ?? 'Görevli Kurye';

    final subtotal = (_preview?['subtotal'] as num?)?.toDouble() ?? 0.0;
    final courierFee = (_preview?['courierFee'] as num?)?.toDouble() ?? 0.0;
    final serviceFee = (_preview?['serviceFee'] as num?)?.toDouble() ?? (subtotal * 0.05);
    final totalAmount = (_preview?['totalAmount'] as num?)?.toDouble() ?? (subtotal + courierFee + serviceFee);
    final distanceKm = (_preview?['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final totalWeightKg = (_preview?['totalWeightKg'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Siparişi Onayla', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Text('Teslimat Adresi', style: AppTypography.headlineMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          await context.push('/addresses');
                          _loadData();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adres Ekle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_addresses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off_rounded, color: AppColors.error, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Kayıtlı Adres Bulunamadı', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.error)),
                                SizedBox(height: 2),
                                Text('Sipariş verebilmek için lütfen detaylı teslimat adresi ekleyiniz.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._addresses.map((addr) {
                      final isSelected = addr['id'] == _selectedAddressId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedAddressId = addr['id']);
                            _loadPreview();
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(addr['title'] ?? 'Adres', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 2),
                                      Text(addr['fullAddress'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), maxLines: 2),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: hasCourier ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: hasCourier ? AppColors.primary : const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasCourier ? Icons.directions_run_rounded : Icons.person_off_rounded,
                              color: hasCourier ? AppColors.primary : const Color(0xFFDC2626),
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hasCourier ? 'Aktif Kurye Hazır ($courierName)' : 'Aktif Kurye Bulunmuyor',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: hasCourier ? AppColors.primary : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasCourier
                              ? 'Pazarda görevli kurye hazır. Siparişinizi onaylayarak ödeme adımına geçebilirsiniz.'
                              : 'Şu an bu pazarda sipariş alabilecek aktif kurye bulunmuyor. Sipariş verebilmek için pazarda aktif bir kuryenin göreve çıkması beklenmektedir.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sipariş ve Teslimat Özeti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('📍 Pazar - Adres Mesafesi:', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                            Text('${distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('⚖️ Toplam Ağırlık:', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                            Text('${totalWeightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('🛒 Ürünler Tutarı:', style: TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('₺${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('🚴 Kurye Teslimat Ücreti:', style: TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(
                              hasCourier ? '₺${courierFee.toStringAsFixed(2)}' : 'Kurye Yok',
                              style: TextStyle(fontWeight: FontWeight.w800, color: hasCourier ? AppColors.primary : AppColors.error, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('🛡️ Uygulama Komisyonu (%5):', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700)),
                            Text('₺${serviceFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 14)),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Genel Toplam:', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 16)),
                            Text('₺${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 20)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Sipariş Notu (Opsiyonel)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesC,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ör: Daire zili çalışmıyor, gelince arayınız...',
                      prefixIcon: Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.notes_rounded)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: (_isCreating || !hasCourier || _selectedAddressId == null)
                          ? null
                          : _createOrder,
                      icon: _isCreating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(hasCourier ? Icons.check_circle_rounded : Icons.block_rounded, color: Colors.white),
                      label: Text(
                        _isCreating
                            ? 'Sipariş Hazırlanıyor...'
                            : (hasCourier ? 'Siparişi Tamamla & Ödemeye Geç' : 'Aktif Kurye Bulunmuyor'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasCourier ? AppColors.primary : const Color(0xFF94A3B8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }
}

