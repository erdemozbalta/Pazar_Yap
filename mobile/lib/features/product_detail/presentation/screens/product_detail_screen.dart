import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/cart_provider.dart';
import '../../../../core/utils/string_utils.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String marketId;

  const ProductDetailScreen({super.key, required this.productId, required this.marketId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  final Map<String, double> _vendorQuantities = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiConstants.products}/${widget.productId}', queryParameters: {'marketId': widget.marketId});
      setState(() {
        _product = res.data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addVendorToCart(String vendorProductId, double qty) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.cartItems, data: {
        'marketId': widget.marketId,
        'vendorProductId': vendorProductId,
        'quantity': qty,
      });
      if (mounted) {
        ref.read(cartItemCountProvider.notifier).refreshCartCount();
        final messenger = ScaffoldMessenger.of(context);
        final router = GoRouter.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            dismissDirection: DismissDirection.horizontal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: InkWell(
              onTap: () {
                messenger.clearSnackBars();
                router.go('/cart');
              },
              child: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ürün sepetinize eklendi 🛒',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                    ),
                  ),
                  Text('Sepete Git ›', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          messenger.clearSnackBars();
        });
      }
    } catch (e) {
      final res = (e as dynamic).response;
      if (res != null && res.statusCode == 409 && res.data?['marketIdMismatch'] == true) {
        final existingName = res.data['existingMarketName'] ?? 'Başka Pazar';
        _showClearCartDialog(existingName, vendorProductId, qty);
        return;
      }

      if (mounted) {
        final err = res?.data?['error'] ?? 'Sepete eklenirken hata oluştu';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.error, duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  void _showClearCartDialog(String existingMarketName, String vendorProductId, double qty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Farklı Pazar Uyarısı', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Sepetinizde şu anda "$existingMarketName" ürünleri bulunuyor. Aynı anda sadece tek bir pazardan sipariş verilebilir.\n\nMevcut sepetinizi temizleyip bu pazardan devam etmek ister misiniz?',
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
                await api.post(ApiConstants.cartItems, data: {
                  'marketId': widget.marketId,
                  'vendorProductId': vendorProductId,
                  'quantity': qty,
                  'clearExistingCart': true,
                });
                if (mounted) {
                  await ref.read(cartItemCountProvider.notifier).refreshCartCount();
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                      dismissDirection: DismissDirection.horizontal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      content: InkWell(
                        onTap: () {
                          messenger.clearSnackBars();
                          router.go('/cart');
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Sepet temizlendi ve yeni ürün eklendi 🛒',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                              ),
                            ),
                            Text('Sepete Git ›', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                          ],
                        ),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  Future.delayed(const Duration(seconds: 2), () {
                    messenger.clearSnackBars();
                  });
                }
              } catch (e) {
                if (mounted) {
                  final err = (e as dynamic).response?.data?['error'] ?? 'Sepet temizlenirken hata oluştu';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Sepeti Temizle ve Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showImageZoomDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white, size: 64),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Text(
                '🔍 Büyütmek için iki parmağınızla yakınlaştırabilirsiniz',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendors = (_product?['vendorProducts'] as List?) ?? [];
    final unit = _product?['unit'] ?? 'kg';
    final String? rawHeroUrl = _product?['imageUrl'] as String?;
    final heroImgUrl = getFormattedImageUrl(rawHeroUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(toTurkishTitleCase(_product?['name'] ?? 'Ürün Detayı'), style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(24),
                            image: heroImgUrl != null
                                ? DecorationImage(image: NetworkImage(heroImgUrl), fit: BoxFit.cover)
                                : null,
                          ),
                          child: heroImgUrl == null
                              ? const Icon(Icons.eco_rounded, size: 52, color: AppColors.primary)
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text(toTurkishTitleCase(_product?['name'] ?? ''), style: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Birim: $unit', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Satıcı Tezgahları', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),

                  ...vendors.map((vp) {
                    final vpId = vp['id'] as String;
                    final price = (vp['price'] as num).toDouble();
                    final qty = _vendorQuantities[vpId] ?? 1.0;
                    final String? rawVpUrl = (vp['photoUrl'] ?? _product?['imageUrl']) as String?;
                    final vpImgUrl = getFormattedImageUrl(rawVpUrl);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: vpImgUrl != null ? () => _showImageZoomDialog(context, vpImgUrl, '${vp['vendor']?['name'] ?? "Tezgah"} - ${toTurkishTitleCase(_product?["name"] ?? "")}') : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(14),
                                    image: vpImgUrl != null
                                        ? DecorationImage(image: NetworkImage(vpImgUrl), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: vpImgUrl == null
                                      ? const Icon(Icons.store_rounded, color: AppColors.primary, size: 24)
                                      : Align(
                                          alignment: Alignment.bottomRight,
                                          child: Container(
                                            margin: const EdgeInsets.all(2),
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                            child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 12),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vp['vendor']?['name'] ?? 'Pazar Tezgahı',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₺${price.toStringAsFixed(2)} / ${vp['unit'] ?? unit}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '⭐ ${(vp['qualityRating'] as num?)?.toDouble() ?? 5.0}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Row(
                                children: [
                                  _QuantityBtn(
                                    icon: Icons.remove,
                                    onTap: () {
                                      final current = _vendorQuantities[vpId] ?? 1.0;
                                      if (current > 0.5) {
                                        setState(() => _vendorQuantities[vpId] = current - 0.5);
                                      }
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${qty.toStringAsFixed(1)} $unit',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  _QuantityBtn(
                                    icon: Icons.add,
                                    onTap: () {
                                      final current = _vendorQuantities[vpId] ?? 1.0;
                                      setState(() => _vendorQuantities[vpId] = current + 0.5);
                                    },
                                  ),
                                ],
                              ),

                              ElevatedButton.icon(
                                onPressed: () => _addVendorToCart(vpId, qty),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                                label: Text(
                                  'Ekle • ₺${(price * qty).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _QuantityBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
      ),
    );
  }
}

