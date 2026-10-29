import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/cart_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  const PaymentScreen({super.key, required this.orderId});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberC = TextEditingController(text: '4111111111111111');
  final _expMonthC = TextEditingController(text: '12');
  final _expYearC = TextEditingController(text: '2028');
  final _cvcC = TextEditingController(text: '123');
  final _holderC = TextEditingController(text: 'TEST KULLANICI');
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _isPaying = false;

  @override
  void initState() { super.initState(); _loadOrder(); }

  Future<void> _loadOrder() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiConstants.orders}/${widget.orderId}');
      setState(() { _order = res.data; _isLoading = false; });
    } catch (_) { setState(() => _isLoading = false); }
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPaying = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.orderPay, data: {
        'orderId': widget.orderId,
        'cardNumber': _cardNumberC.text.replaceAll(' ', ''),
        'expireMonth': _expMonthC.text,
        'expireYear': _expYearC.text,
        'cvc': _cvcC.text,
        'cardHolderName': _holderC.text,
      });
      ref.read(cartItemCountProvider.notifier).updateCount(0);
      ref.read(cartItemCountProvider.notifier).refreshCartCount();
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success),
              ),
              const SizedBox(height: 16),
              Text('Ödeme Başarılı!', style: AppTypography.headlineMedium),
              const SizedBox(height: 8),
              Text('Siparişiniz başarıyla alındı ve kuryenize iletildi.', textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () { Navigator.pop(context); context.go('/orders'); },
                child: const Text('Siparişlerime Git'),
              )),
            ]),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ödeme başarısız'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/checkout');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(children: [
                        _SummaryRow(label: 'Sipariş No', value: _order?['orderNumber'] ?? ''),
                        _SummaryRow(label: 'Ürün Toplamı', value: '₺${(_order?['subtotal'] as num? ?? 0).toStringAsFixed(2)}'),
                        _SummaryRow(label: 'Kurye Ücreti', value: '₺${(_order?['courierFee'] as num? ?? 0).toStringAsFixed(2)}'),
                        _SummaryRow(label: 'Uygulama Komisyonu (%5)', value: '₺${((_order?['serviceFee'] as num?)?.toDouble() ?? ((_order?['subtotal'] as num? ?? 0) * 0.05)).toStringAsFixed(2)}'),
                        const Divider(height: 16),
                        _SummaryRow(label: 'Toplam', value: '₺${(_order?['totalAmount'] as num? ?? 0).toStringAsFixed(2)}', isBold: true),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Test modu — Kart bilgileri otomatik dolduruldu', style: AppTypography.bodySmall.copyWith(color: AppColors.info))),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    Text('Kart Bilgileri', style: AppTypography.headlineMedium),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _holderC,
                      decoration: const InputDecoration(labelText: 'Kart Üzerindeki İsim', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cardNumberC,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                      decoration: const InputDecoration(labelText: 'Kart Numarası', prefixIcon: Icon(Icons.credit_card)),
                      validator: (v) => v == null || v.length < 16 ? '16 haneli kart numarası' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _expMonthC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ay'), validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _expYearC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Yıl'), validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _cvcC, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'CVC'), validator: (v) => v == null || v.length < 3 ? 'Zorunlu' : null)),
                    ]),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isPaying ? null : _pay,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        icon: _isPaying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.lock_rounded),
                        label: Text(_isPaying ? 'İşleniyor...' : 'Ödemeyi Tamamla — ₺${(_order?['totalAmount'] as num? ?? 0).toStringAsFixed(2)}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  const _SummaryRow({required this.label, required this.value, this.isBold = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: isBold ? AppTypography.titleMedium : AppTypography.bodyMedium),
        Text(value, style: isBold ? AppTypography.priceLarge.copyWith(fontSize: 18) : AppTypography.titleMedium),
      ]),
    );
  }
}

