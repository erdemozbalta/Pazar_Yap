import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/utils/string_utils.dart';

class MarketManagementScreen extends ConsumerStatefulWidget {
  const MarketManagementScreen({super.key});
  @override
  ConsumerState<MarketManagementScreen> createState() => _MarketManagementScreenState();
}

class _MarketManagementScreenState extends ConsumerState<MarketManagementScreen> {
  List<dynamic> _markets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiConstants.markets, queryParameters: {'all': 'true'});
      setState(() {
        _markets = res.data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMarket(String id, String name) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.patch('/markets/$id/toggle');
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? '$name güncellendi'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pazar durumu değiştirilemedi'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showMarketForm([Map<String, dynamic>? existing]) {
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final cityC = TextEditingController(text: existing?['city'] ?? '');
    final districtC = TextEditingController(text: existing?['district'] ?? '');
    final neighborhoodC = TextEditingController(text: existing?['neighborhood'] ?? '');
    final openC = TextEditingController(text: existing?['openTime'] ?? '07:00');
    final closeC = TextEditingController(text: existing?['closeTime'] ?? '18:00');
    final imageC = TextEditingController(text: existing?['imageUrl'] ?? '');
    String? currentImageStr = existing?['imageUrl'];
    final ImagePicker picker = ImagePicker();
    final latC = TextEditingController(text: (existing?['latitude'] as num?)?.toString() ?? '');
    final lngC = TextEditingController(text: (existing?['longitude'] as num?)?.toString() ?? '');
    bool isLocating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          Future<void> detectGpsLocation() async {
            setS(() => isLocating = true);
            try {
              final loc = await LocationService.getCurrentLocation();
              setS(() {
                cityC.text = loc.city;
                districtC.text = loc.district;
                neighborhoodC.text = loc.neighborhood;
                latC.text = loc.latitude.toString();
                lngC.text = loc.longitude.toString();
                isLocating = false;
              });
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('📍 Pazar konumu saptandı: ${loc.district}, ${loc.city} (${loc.latitude}, ${loc.longitude})'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            } catch (e) {
              setS(() => isLocating = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Konum saptanamadı: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: AppColors.error),
                );
              }
            }
          }

          Future<void> pickMarketPhoto(ImageSource source) async {
            try {
              final XFile? photo = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1000, maxHeight: 1000);
              if (photo != null) {
                final bytes = await photo.readAsBytes();
                final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                setS(() {
                  currentImageStr = base64Str;
                  imageC.text = base64Str;
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

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(existing == null ? 'Yeni Pazar Ekle' : 'Pazarı Düzenle', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isLocating ? null : detectGpsLocation,
                        icon: isLocating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                        label: Text(
                          isLocating ? 'GPS Konumu Alınıyor...' : '📍 Konumu Otomatik Sapta',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Pazar Adı *', hintText: 'Örn: Kadıköy Salı Pazarı')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: cityC, decoration: const InputDecoration(labelText: 'İl *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: districtC, decoration: const InputDecoration(labelText: 'İlçe *', hintText: 'Kadıköy'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: neighborhoodC, decoration: const InputDecoration(labelText: 'Semt / Mahalle *', hintText: 'Rasimpaşa')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latC,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                            ],
                            decoration: const InputDecoration(labelText: 'Enlem (Latitude) *', hintText: '40.9875'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lngC,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                            ],
                            decoration: const InputDecoration(labelText: 'Boylam (Longitude) *', hintText: '29.0250'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: openC, decoration: const InputDecoration(labelText: 'Açılış saati'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: closeC, decoration: const InputDecoration(labelText: 'Kapanış saati'))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text('Pazar Fotoğrafı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: (currentImageStr != null && currentImageStr!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildMarketImageWidget(currentImageStr!),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 18),
                                        onPressed: () => setS(() {
                                          currentImageStr = null;
                                          imageC.clear();
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo_outlined, size: 36, color: Color(0xFF94A3B8)),
                                SizedBox(height: 6),
                                Text('Fotoğraf çekin veya galeriden seçin', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                              ],
                            ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickMarketPhoto(ImageSource.camera),
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
                            onPressed: () => pickMarketPhoto(ImageSource.gallery),
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

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameC.text.trim().isEmpty || districtC.text.trim().isEmpty || neighborhoodC.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lütfen gerekli tüm alanları doldurunuz (*)')),
                            );
                            return;
                          }
                          try {
                            final api = ref.read(apiClientProvider);
                            final data = {
                              'name': nameC.text.trim(),
                              'city': cityC.text.trim(),
                              'district': districtC.text.trim(),
                              'neighborhood': neighborhoodC.text.trim(),
                              'latitude': double.tryParse(latC.text.trim()) ?? 40.9875,
                              'longitude': double.tryParse(lngC.text.trim()) ?? 29.0250,
                              'openTime': openC.text.trim(),
                              'closeTime': closeC.text.trim(),
                              'imageUrl': imageC.text.trim().isEmpty ? null : imageC.text.trim(),
                              'operatingDays': '["Pazartesi", "Çarşamba", "Cuma"]',
                            };
                            if (existing != null) {
                              await api.put('${ApiConstants.markets}/${existing['id']}', data: data);
                            } else {
                              await api.post(ApiConstants.markets, data: data);
                            }
                            if (mounted) {
                              Navigator.pop(ctx);
                              _load();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(existing == null ? 'Yeni pazar başarıyla eklendi!' : 'Pazar güncellendi!'),
                                  backgroundColor: AppColors.primary,
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
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(existing == null ? 'Pazarı Oluştur' : 'Değişiklikleri Kaydet', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarketImageWidget(String? url) {
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
      return Image.network(formatted, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28));
    }
    return const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pazar Yönetimi', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
            onPressed: () => _showMarketForm(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMarketForm(),
        backgroundColor: const Color(0xFF10B981),
        elevation: 3,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white, size: 22),
        label: const Text(
          'Yeni Pazar Ekle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _markets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded, size: 48, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Henüz Pazar Yeri Bulunmuyor',
                          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sistemde henüz kayıtlı pazar yeri bulunmuyor. Aşağıdaki yeşil butona tıklayarak hemen yeni pazar ekleyebilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showMarketForm(),
                          icon: const Icon(Icons.add_business_rounded, color: Colors.white, size: 20),
                          label: const Text('Yeni Pazar Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                  itemCount: _markets.length,
                  itemBuilder: (_, i) {
                    final m = _markets[i];
                    final imageUrl = m['imageUrl'] as String?;
                    final isActive = m['isActive'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? const Color(0xFFE2E8F0) : const Color(0xFFFCA5A5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
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
                              child: _buildMarketImageWidget(imageUrl),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(m['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isActive ? 'AÇIK' : 'KAPALI',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isActive ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${m['district']}, ${m['city']}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: isActive,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) => _toggleMarket(m['id'], m['name'] ?? 'Pazar'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                                onPressed: () => _showMarketForm(m),
                                tooltip: 'Pazarı Düzenle',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                                onPressed: () => _deleteMarket(m['id'], m['name'] ?? 'Pazar'),
                                tooltip: 'Pazarı Sil',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _deleteMarket(String marketId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pazarı Sil', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('$name pazarını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              try {
                final api = ref.read(apiClientProvider);
                await api.delete('${ApiConstants.markets}/$marketId');
                if (mounted) {
                  Navigator.pop(ctx);
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pazar silindi ✅'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  final err = (e as dynamic).response?.data?['error'] ?? 'Pazar silinemedi';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Tamam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

