import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/cart_provider.dart';
import '../../../../core/utils/string_utils.dart';

class MarketDetailScreen extends ConsumerStatefulWidget {
  final String marketId;

  const MarketDetailScreen({super.key, required this.marketId});

  @override
  ConsumerState<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends ConsumerState<MarketDetailScreen> {
  Map<String, dynamic>? _market;
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _selectedCategoryName = 'Tümü';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final [marketRes, productsRes] = await Future.wait([
        api.get('${ApiConstants.markets}/${widget.marketId}'),
        api.get('${ApiConstants.markets}/${widget.marketId}/products'),
      ]);
      setState(() {
        _market = marketRes.data;
        _categories = productsRes.data ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _getCategoryEmoji(String name) {
    final cName = name.toLowerCase();
    if (cName.contains('meyve')) return '🍎';
    if (cName.contains('sebze')) return '🥦';
    if (cName.contains('unlu') || cName.contains('ekmek') || cName.contains('fırın')) return '🥖';
    if (cName.contains('peynir') || cName.contains('süt') || cName.contains('şarküteri')) return '🧀';
    if (cName.contains('zeytin')) return '🫒';
    if (cName.contains('reçel') || cName.contains('bal') || cName.contains('kahvaltı')) return '🍯';
    if (cName.contains('kuruyemiş') || cName.contains('yemiş') || cName.contains('fıstık')) return '🥜';
    if (cName.contains('bakliyat') || cName.contains('baklagil') || cName.contains('tahıl')) return '🫘';
    if (cName.contains('baharat') || cName.contains('tuz')) return '🌶️';
    if (cName.contains('et') || cName.contains('tavuk') || cName.contains('kasap')) return '🥩';
    if (cName.contains('balık') || cName.contains('deniz')) return '🐟';
    if (cName.contains('yeşillik') || cName.contains('ot')) return '🌿';
    return '🛒';
  }

  Widget _buildMarketHeaderImage(String? url) {
    if (url == null || url.trim().isEmpty) {
      return const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28);
    }
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {
        return const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28);
      }
    }
    final formatted = getFormattedImageUrl(url);
    if (formatted != null && formatted.startsWith('http')) {
      return Image.network(
        formatted,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28),
      );
    }
    return const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28);
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

    List<dynamic> allProducts = [];
    for (var cat in _categories) {
      if (_selectedCategoryName == 'Tümü' || (cat['name'] as String).toLowerCase() == _selectedCategoryName.toLowerCase()) {
        final prods = (cat['products'] as List?) ?? [];
        final validProds = prods.where((p) => (p['vendorProducts'] as List?)?.isNotEmpty == true).toList();
        allProducts.addAll(validProds);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_market?['name'] ?? 'Pazar Detayı', style: const TextStyle(fontWeight: FontWeight.w700)),
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
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final cartCount = ref.watch(cartItemCountProvider);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.go('/cart'),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildMarketHeaderImage(_market?['imageUrl'] as String?),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _market?['name'] ?? '',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'AÇIK',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Kategoriler', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                      const Spacer(),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.view_list_rounded, color: !_isGridView ? AppColors.primary : const Color(0xFF94A3B8), size: 18),
                              onPressed: () => setState(() => _isGridView = false),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.grid_view_rounded, color: _isGridView ? AppColors.primary : const Color(0xFF94A3B8), size: 18),
                              onPressed: () => setState(() => _isGridView = true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 38,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCatChip('Tümü', '🛒'),
                      ..._categories.map((c) => _buildCatChip(c['name'] ?? '', _getCategoryEmoji(c['name'] ?? ''))),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: allProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.shopping_basket_outlined, size: 48, color: Color(0xFF94A3B8)),
                              SizedBox(height: 10),
                              Text('Bu kategoride henüz ürün yok', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                            ],
                          ),
                        )
                      : !_isGridView
                          ? ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: allProducts.length,
                              itemBuilder: (context, i) {
                                final prod = allProducts[i];
                                final vendors = (prod['vendorProducts'] as List?) ?? [];
                                final String? rawUrl = prod['imageUrl'] as String?;
                                final formattedImgUrl = getFormattedImageUrl(rawUrl);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [

                                      Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(16),
                                          image: formattedImgUrl != null
                                              ? DecorationImage(image: NetworkImage(formattedImgUrl), fit: BoxFit.cover)
                                              : null,
                                        ),
                                        child: formattedImgUrl == null
                                            ? const Icon(Icons.eco_rounded, color: AppColors.primary, size: 32)
                                            : null,
                                      ),
                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              toTurkishTitleCase(prod['name'] ?? ''),
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.storefront_rounded, size: 14, color: AppColors.primary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${vendors.length} Satıcı Tezgahı',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      ElevatedButton(
                                        onPressed: () => context.push(
                                          '/product/${prod['id']}?marketId=${widget.marketId}',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primarySurface,
                                          foregroundColor: AppColors.primary,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: const Text('Tezgahları Gör ›', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: allProducts.length,
                              itemBuilder: (context, i) {
                                final prod = allProducts[i];
                                final vendors = (prod['vendorProducts'] as List?) ?? [];
                                final String? rawUrl = prod['imageUrl'] as String?;
                                final formattedImgUrl = getFormattedImageUrl(rawUrl);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.push(
                                      '/product/${prod['id']}?marketId=${widget.marketId}',
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: formattedImgUrl != null
                                                ? () => _showImageZoomDialog(context, formattedImgUrl, toTurkishTitleCase(prod['name'] ?? 'Ürün Görseli'))
                                                : null,
                                            borderRadius: BorderRadius.circular(14),
                                            child: Container(
                                              width: double.infinity,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(14),
                                                image: formattedImgUrl != null
                                                    ? DecorationImage(image: NetworkImage(formattedImgUrl), fit: BoxFit.cover)
                                                    : null,
                                              ),
                                              child: formattedImgUrl == null
                                                  ? const Icon(Icons.eco_rounded, color: AppColors.primary, size: 36)
                                                  : Align(
                                                      alignment: Alignment.bottomRight,
                                                      child: Container(
                                                        margin: const EdgeInsets.all(3),
                                                        padding: const EdgeInsets.all(2),
                                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                                        child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 12),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            toTurkishTitleCase(prod['name'] ?? ''),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.storefront_rounded, size: 12, color: AppColors.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${vendors.length} Tezgah',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildCatChip(String name, String icon) {
    final isSelected = _selectedCategoryName.toLowerCase() == name.toLowerCase();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Text(icon, style: const TextStyle(fontSize: 13)),
        label: Text(name),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF0F172A),
        ),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => setState(() => _selectedCategoryName = name),
      ),
    );
  }
}

