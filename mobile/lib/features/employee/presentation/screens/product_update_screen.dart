import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

import '../../../../core/utils/string_utils.dart';

class ProductUpdateScreen extends ConsumerStatefulWidget {
  final String marketId;

  const ProductUpdateScreen({super.key, required this.marketId});

  @override
  ConsumerState<ProductUpdateScreen> createState() => _ProductUpdateScreenState();
}

class _ProductUpdateScreenState extends ConsumerState<ProductUpdateScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _allCategories = [];
  List<dynamic> _allProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiConstants.markets}/${widget.marketId}/products', queryParameters: {'includeEmpty': 'true'});
      final catRes = await api.get('/products/categories');
      final prodRes = await api.get('/products');

      setState(() {
        _categories = res.data ?? [];
        _allCategories = catRes.data ?? [];
        _allProducts = prodRes.data ?? [];
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

  Widget _buildProductImageWidget(String url, {double size = 44}) {
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: size, height: size);
      } catch (_) {
        return Icon(Icons.fastfood_outlined, color: AppColors.primary, size: size * 0.5);
      }
    }
    final formatted = getFormattedImageUrl(url);
    if (formatted != null && formatted.startsWith('http')) {
      return Image.network(
        formatted,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(Icons.fastfood_outlined, color: AppColors.primary, size: size * 0.5),
      );
    }
    return Icon(Icons.fastfood_outlined, color: AppColors.primary, size: size * 0.5);
  }

  void _showAddBaseProductModal([Map<String, dynamic>? existingProduct]) {
    final productNameC = TextEditingController(text: existingProduct?['name'] ?? '');
    String selectedCategoryId = existingProduct?['categoryId'] ?? (_allCategories.isNotEmpty ? _allCategories[0]['id'].toString() : '');
    String? productPhotoStr = existingProduct?['imageUrl'];
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickProductPhoto(ImageSource source) async {
            try {
              final XFile? photo = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1000, maxHeight: 1000);
              if (photo != null) {
                final bytes = await photo.readAsBytes();
                final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                setModalState(() {
                  productPhotoStr = base64Str;
                });
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Fotoğraf seçilemedi: $e'), backgroundColor: AppColors.error),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(existingProduct == null ? Icons.add_shopping_cart_rounded : Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                      const SizedBox(width: 10),
                      Text(existingProduct == null ? 'Pazara Yeni Ürün Ekle' : 'Ürün Bilgilerini Düzenle', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    existingProduct == null
                        ? 'Ürün adı ve kategorisini ekleyin. İsterseniz genel temsil bir fotoğraf yükleyebilirsiniz.'
                        : 'Ürün adını, kategorisini ve genel fotoğrafını güncelleyin.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: productNameC,
                    decoration: const InputDecoration(
                      labelText: 'Ürün Adı *',
                      hintText: 'Örn: Domates, Salatalık, Marul, Salkım Domates',
                      prefixIcon: Icon(Icons.fastfood_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Kategori *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId.isNotEmpty && _allCategories.any((c) => c['id'].toString() == selectedCategoryId)
                        ? selectedCategoryId
                        : (_allCategories.isNotEmpty ? _allCategories[0]['id'].toString() : null),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                    hint: const Text('Kategori Seçiniz'),
                    items: _allCategories.map<DropdownMenuItem<String>>((cat) {
                      final cName = cat['name'].toString();
                      final emoji = _getCategoryEmoji(cName);

                      return DropdownMenuItem<String>(
                        value: cat['id'].toString(),
                        child: Text('$emoji $cName'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategoryId = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Ürün Genel Fotoğrafı (İsteğe Bağlı)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),

                  if (productPhotoStr != null && productPhotoStr!.isNotEmpty) ...[
                    Stack(
                      children: [
                        Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildProductImageWidget(productPhotoStr!, size: 110),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: InkWell(
                            onTap: () => setModalState(() => productPhotoStr = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickProductPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.primary),
                          label: const Text('Fotoğraf Çek', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickProductPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded, size: 18, color: Color(0xFF0284C7)),
                          label: const Text('Galeriden Seç', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: const BorderSide(color: Color(0xFF0284C7)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '📷 İsteğe bağlı: Ürün için genel bir temsil fotoğraf ekleyebilirsiniz (örnek: Domates). Tezgaha özel fotoğraflar tezgah eklerken ayrıca seçilir.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (productNameC.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen ürün adını giriniz')),
                          );
                          return;
                        }

                        try {
                          final api = ref.read(apiClientProvider);
                          final pName = toTurkishTitleCase(productNameC.text.trim());

                          if (existingProduct != null) {
                            await api.put('/products/${existingProduct['id']}', data: {
                              'name': pName,
                              'categoryId': selectedCategoryId,
                              'imageUrl': productPhotoStr,
                            });
                          } else {
                            dynamic targetProduct = _allProducts.firstWhere(
                              (p) => (p['name'] as String).toLowerCase() == pName.toLowerCase() && p['marketId'] == widget.marketId,
                              orElse: () => null,
                            );

                            if (targetProduct == null) {
                              final newProdRes = await api.post('/products', data: {
                                'name': pName,
                                'categoryId': selectedCategoryId,
                                'unit': 'kg',
                                'marketId': widget.marketId,
                                'imageUrl': productPhotoStr,
                              });
                              targetProduct = newProdRes.data['product'];
                            } else {
                              await api.put('/products/${targetProduct['id']}', data: {
                                'name': pName,
                                'categoryId': selectedCategoryId,
                                'imageUrl': productPhotoStr,
                              });
                            }
                          }

                          if (mounted) {
                            Navigator.pop(ctx);
                            _load();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(existingProduct == null
                                    ? '"$pName" ürünü eklendi! Şimdi "+ Satıcı Ekle" butonuna basarak tezgah ekleyebilirsiniz.'
                                    : '"$pName" güncellendi!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            final err = (e as dynamic).response?.data?['error'] ?? 'İşlem başarısız';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                      child: Text(existingProduct == null ? 'Ürünü Pazara Kaydet' : 'Değişiklikleri Kaydet', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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

  void _showAddVendorStallModal(Map<String, dynamic> product, {Map<String, dynamic>? existingVp}) {
    final vendorNameC = TextEditingController(text: existingVp?['vendor']?['name'] ?? '');
    final stallLocationC = TextEditingController(text: existingVp?['stallLocation'] ?? '');
    final priceC = TextEditingController(text: existingVp?['price']?.toString() ?? '');
    String selectedUnit = (existingVp?['unit'] ?? product['unit'] ?? 'kg').toString().toLowerCase();
    if (selectedUnit != 'kg' && selectedUnit != 'adet') {
      selectedUnit = 'kg';
    }
    double qualityRating = (existingVp?['qualityRating'] as num?)?.toDouble() ?? 5.0;
    File? selectedImage;
    String? modalErrorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        existingVp == null ? '"${product['name']}" için Tezgah Ekle' : '"${product['name']}" Tezgahını Düzenle',
                        style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Satıcı adı, ürün satış fiyatı, birim cinsi (kg veya adet) ve konum açıklamasını giriniz.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                if (modalErrorMsg != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            modalErrorMsg!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                TextField(
                  controller: vendorNameC,
                  decoration: const InputDecoration(
                    labelText: 'Satıcı / Tezgah Adı *',
                    hintText: 'Örn: Ahmet Efendi Manavı, Özgür Kardeşler',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: priceC,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Fiyat (₺) *',
                          hintText: 'Örn: 35.0',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedUnit,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Birim *',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'adet', child: Text('adet')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: stallLocationC,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Kuryeye Özel Satıcı Konumu *',
                    hintText: 'Örn: Balıkçılar kapısının yanındaki 14 nolu mavi brandalı tezgah',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tezgah Ürün Fotoğrafı * (Zorunlu)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    if (selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(selectedImage!, width: double.infinity, height: 130, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (existingVp?['photoUrl'] != null && (existingVp!['photoUrl'] as String).trim().isNotEmpty)
                      Stack(
                        children: [
                          Container(
                            height: 130,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildProductImageWidget(existingVp['photoUrl'] as String, size: 130),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                if (image != null) setModalState(() => selectedImage = File(image.path));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('Fotoğrafı Değiştir', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                                if (image != null) setModalState(() => selectedImage = File(image.path));
                              },
                              icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.primary),
                              label: const Text('Fotoğraf Çek', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                if (image != null) setModalState(() => selectedImage = File(image.path));
                              },
                              icon: const Icon(Icons.photo_library_rounded, size: 18, color: AppColors.primary),
                              label: const Text('Galeriden Seç', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    const Text('Ürün Kalite Puanı *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF475569))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primary, size: 22),
                            onPressed: qualityRating > 1.0
                                ? () => setModalState(() => qualityRating = (qualityRating - 0.5).clamp(1.0, 5.0))
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  qualityRating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
                            onPressed: qualityRating < 5.0
                                ? () => setModalState(() => qualityRating = (qualityRating + 0.5).clamp(1.0, 5.0))
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (vendorNameC.text.trim().isEmpty ||
                          stallLocationC.text.trim().isEmpty ||
                          priceC.text.trim().isEmpty) {
                        setModalState(() {
                          modalErrorMsg = '⚠️ Lütfen Satıcı Adı, Konum ve Fiyat alanlarını doldurunuz!';
                        });
                        return;
                      }

                      final bool hasPhoto = selectedImage != null ||
                          (existingVp?['photoUrl'] != null && existingVp!['photoUrl'].toString().isNotEmpty);
                      if (!hasPhoto) {
                        setModalState(() {
                          modalErrorMsg = '⚠️ Lütfen ürün fotoğrafı çekiniz veya galeriden seçiniz! (Fotoğraf zorunludur)';
                        });
                        return;
                      }

                      final priceVal = double.tryParse(priceC.text.trim());
                      if (priceVal == null || priceVal <= 0) {
                        setModalState(() {
                          modalErrorMsg = '⚠️ Lütfen geçerli ve 0\'dan büyük bir fiyat giriniz!';
                        });
                        return;
                      }

                      setModalState(() {
                        modalErrorMsg = null;
                      });

                      try {
                        final api = ref.read(apiClientProvider);

                        final formDataMap = <String, dynamic>{
                          'marketId': widget.marketId,
                          'vendorName': vendorNameC.text.trim(),
                          'stallLocation': stallLocationC.text.trim(),
                          'productId': product['id'],
                          'price': priceVal.toString(),
                          'unit': selectedUnit,
                          'qualityRating': qualityRating.toString(),
                        };

                        if (selectedImage != null) {
                          formDataMap['photo'] = await MultipartFile.fromFile(
                            selectedImage!.path,
                            filename: selectedImage!.path.split('/').last.split('\\').last,
                          );
                        } else if (existingVp?['photoUrl'] != null) {
                          formDataMap['photoUrl'] = existingVp!['photoUrl'];
                        }

                        final formData = FormData.fromMap(formDataMap);

                        if (existingVp != null) {
                          await api.put('/products/vendor-products/${existingVp['id']}', data: formData);
                        } else {
                          await api.post('/products/vendor-products', data: formData);
                        }

                        if (mounted) {
                          Navigator.pop(ctx);
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existingVp == null ? 'Satıcı & Tezgah eklendi! Müşteriler artık bu ürünü görebilir.' : 'Tezgah ve fiyat bilgisi güncellendi.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          final err = (e as dynamic).response?.data?['error'] ?? 'İşlem başarısız';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    child: Text(existingVp == null ? 'Tezgahı Pazara Kaydet' : 'Tezgahı Güncelle', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteVendorProduct(String vpId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tezgahı Sil', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Bu tezgahı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.delete('/products/vendor-products/$vpId');
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tezgah silindi.'), backgroundColor: AppColors.info),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _deleteBaseProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü Sil', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Bu ürünü ve bağlı tüm tezgahları pazardan silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Ürünü Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.delete('/products/$productId');
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün pazardan silindi.'), backgroundColor: AppColors.info),
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pazar Ürün & Stok Yönetimi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/employee/home');
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBaseProductModal(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Pazara Yeni Ürün Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(Icons.add_shopping_cart_rounded, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 20),
                        const Text('Bu Pazarda Henüz Ürün Yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        const SizedBox(height: 8),
                        const Text(
                          'Aşağıdaki butona basarak Domates, Salatalık vb. ürünleri pazara ekleyebilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddBaseProductModal(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('İlk Ürünü Ekle'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _categories.length,
                  itemBuilder: (_, ci) {
                    final cat = _categories[ci];
                    final products = (cat['products'] as List?) ?? [];
                    final cName = cat['name'] ?? '';
                    final emoji = _getCategoryEmoji(cName);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          child: Row(
                            children: [
                              Text('$emoji $cName', style: AppTypography.headlineMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
                                child: Text('${products.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                              ),
                            ],
                          ),
                        ),
                        ...products.map((p) {
                          final vendorProducts = (p['vendorProducts'] as List?) ?? [];
                          final hasStalls = vendorProducts.isNotEmpty;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: hasStalls ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: (p['imageUrl'] != null && (p['imageUrl'] as String).isNotEmpty)
                                            ? _buildProductImageWidget(p['imageUrl'] as String, size: 48)
                                            : Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            toTurkishTitleCase(p['name'] ?? ''),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            hasStalls ? '${vendorProducts.length} aktif tezgah tanımlı' : 'Henüz tezgah tanımlanmadı (Müşterilere gizli ⚠️)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: hasStalls ? const Color(0xFF059669) : const Color(0xFFD97706),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 20),
                                      tooltip: 'Ürünü Düzenle',
                                      onPressed: () => _showAddBaseProductModal(p),
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                      tooltip: 'Ürünü Sil',
                                      onPressed: () => _deleteBaseProduct(p['id']),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                if (vendorProducts.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 4),
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showAddVendorStallModal(p),
                                      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                                      label: const Text(' Satıcı / Tezgah Ekle', style: TextStyle(fontWeight: FontWeight.w800)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                    ),
                                  )
                                else ...[
                                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  const SizedBox(height: 10),
                                  ...vendorProducts.map((vp) {
                                    final vendor = vp['vendor'] ?? {};
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: AppColors.primarySurface,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: (vp['photoUrl'] != null && (vp['photoUrl'] as String).trim().isNotEmpty)
                                                  ? _buildProductImageWidget(vp['photoUrl'] as String, size: 44)
                                                  : const Center(child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20)),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  vendor['name'] ?? 'Pazar Tezgahı',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                                ),
                                                Text(
                                                  '📍 ${vp['stallLocation'] ?? 'Tezgah konumu belirtilmedi'}',
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                ),
                                                Text(
                                                  '⭐ Kalite: ${vp['qualityRating'] ?? 5.0}',
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w700),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₺${vp['price']} / ${p['unit'] ?? 'kg'}',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 6),

                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7), size: 20),
                                            tooltip: 'Tezgahı Düzenle',
                                            onPressed: () => _showAddVendorStallModal(p, existingVp: vp),
                                          ),

                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                            tooltip: 'Tezgahı Sil',
                                            onPressed: () => _deleteVendorProduct(vp['id']),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 4),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _showAddVendorStallModal(p),
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: const Text('Farklı Tezgah Ekle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
    );
  }
}

