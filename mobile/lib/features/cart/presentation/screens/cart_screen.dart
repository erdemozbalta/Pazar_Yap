import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Map<String, dynamic>? _cartData;
  bool _isLoading = true;

  String? getFormattedImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    if (rawUrl.startsWith('/')) {
      return '$baseUrl$rawUrl';
    }
    return '$baseUrl/$rawUrl';
  }

  Widget _buildItemImageWidget(String? photoUrl, String? productImageUrl, {double size = 56}) {
    final url = (photoUrl != null && photoUrl.trim().isNotEmpty) ? photoUrl : productImageUrl;
    if (url == null || url.trim().isEmpty) {
      return Icon(Icons.eco_rounded, size: size * 0.5, color: AppColors.primary);
    }
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: size, height: size);
      } catch (_) {
        return Icon(Icons.eco_rounded, size: size * 0.5, color: AppColors.primary);
      }
    }
    final formatted = getFormattedImageUrl(url);
    if (formatted != null && formatted.startsWith('http')) {
      return Image.network(
        formatted,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(Icons.eco_rounded, size: size * 0.5, color: AppColors.primary),
      );
    }
    return Icon(Icons.eco_rounded, size: size * 0.5, color: AppColors.primary);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiConstants.cart);
      setState(() {
        _cartData = res.data;
        _isLoading = false;
      });
      ref.read(cartItemCountProvider.notifier).refreshCartCount();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQuantity(String itemId, double qty) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('${ApiConstants.cartItems}/$itemId', data: {'quantity': qty});
      _load();
    } catch (_) {}
  }

  Future<void> _removeItem(String itemId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('${ApiConstants.cartItems}/$itemId');
      _load();
    } catch (_) {}
  }

  void _editItemNote(String itemId, String currentNote) {
    final controller = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kurye İçin Ürün Notu', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teslimatı yapacak kuryeniz için ürüne özel not girebilirsiniz (Örn: Domatesler sert ve olgun olsun, salatalıklar küçük boy olsun).',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Örn: Domatesler sert olsun...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(apiClientProvider);
                await api.put('${ApiConstants.cartItems}/$itemId', data: {
                  'note': controller.text.isNotEmpty ? controller.text : null,
                });
                _load();
              } catch (_) {}
            },
            child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = (_cartData?['items'] as List?) ?? [];
    final subtotal = (_cartData?['subtotal'] as num?)?.toDouble() ?? 0;
    final defaultMarket = _cartData?['cart']?['market'];

    final Map<String, List<dynamic>> marketGroupedItems = {};
    for (var item in items) {
      final vp = item['vendorProduct'];
      final marketName = vp?['vendor']?['market']?['name'] ?? defaultMarket?['name'] ?? 'Pazar Ürünleri';
      marketGroupedItems.putIfAbsent(marketName, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).canPop() ? Navigator.of(context).pop() : context.go('/home'),
        ),
        title: const Text('Sepetim', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 20),
                      Text('Sepetiniz boş', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Taze pazar ürünlerini keşfetmeye başlayın', style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF64748B))),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.storefront_rounded),
                        label: const Text('Pazarları Keşfet'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      ...marketGroupedItems.entries.map((entry) {
                        final marketName = entry.key;
                        final groupItems = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        marketName,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                      child: Text('${groupItems.length} Kalem', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              ...groupItems.map((item) {
                                final vp = item['vendorProduct'];
                                final product = vp?['product'];
                                final vendor = vp?['vendor'];
                                final price = (vp?['price'] as num?)?.toDouble() ?? 0;
                                final qty = (item['quantity'] as num?)?.toDouble() ?? 0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                            ),
                                            alignment: Alignment.center,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: _buildItemImageWidget(vp?['photoUrl'], product?['imageUrl'], size: 56),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        product?['name'] ?? '',
                                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                                      onPressed: () => _removeItem(item['id']),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  vendor?['name'] ?? '',
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      '₺${price.toStringAsFixed(2)} / ${product?['unit'] ?? 'kg'}',
                                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(16),
                                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          _MiniStepBtn(
                                                            icon: Icons.remove,
                                                            onTap: () {
                                                              if (qty > 0.5) _updateQuantity(item['id'], qty - 0.5);
                                                            },
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                                            child: Text(qty.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                                          ),
                                                          _MiniStepBtn(
                                                            icon: Icons.add,
                                                            onTap: () => _updateQuantity(item['id'], qty + 0.5),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => _editItemNote(item['id'], item['note'] ?? ''),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: item['note'] != null && (item['note'] as String).isNotEmpty
                                                ? const Color(0xFFFEF3C7)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: item['note'] != null && (item['note'] as String).isNotEmpty
                                                  ? const Color(0xFFF59E0B)
                                                  : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_note_rounded,
                                                size: 16,
                                                color: item['note'] != null && (item['note'] as String).isNotEmpty
                                                    ? const Color(0xFFD97706)
                                                    : const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  item['note'] != null && (item['note'] as String).isNotEmpty
                                                      ? 'Kuryeye Not: ${item['note']}'
                                                      : '+ Kuryeye Ürün Notu Ekle (Örn: Domatesler sert olsun)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: item['note'] != null && (item['note'] as String).isNotEmpty
                                                        ? const Color(0xFF92400E)
                                                        : const Color(0xFF64748B),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text('Sipariş Özeti', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                                  child: Text('${items.length} Kalem Ürün', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),

                            ...items.map((item) {
                              final vp = item['vendorProduct'];
                              final product = vp?['product'];
                              final vendor = vp?['vendor'];
                              final name = product?['name'] ?? 'Ürün';
                              final unit = product?['unit'] ?? 'kg';
                              final vendorName = vendor?['name'] ?? 'Tezgah';
                              final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
                              final price = (vp?['price'] as num?)?.toDouble() ?? 0;
                              final itemTotal = qty * price;
                              final isDemet = unit.toString().toLowerCase().contains('demet');

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$vendorName • ${qty.toStringAsFixed(1)} $unit ${isDemet ? "(Ağırlıksız)" : ""} × ₺${price.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text('₺${itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                  ],
                                ),
                              );
                            }),

                            const Divider(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Ürünler Ara Toplamı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                Text('₺${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Hizmet Bedeli (%5)', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                Text('₺${(subtotal * 0.05).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                              ],
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () => context.push('/checkout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text('Siparişi Onayla & Devam Et', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _MiniStepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniStepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: const Color(0xFF0F172A)),
      ),
    );
  }
}

