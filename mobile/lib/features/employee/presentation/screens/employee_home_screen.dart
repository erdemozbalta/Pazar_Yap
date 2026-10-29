import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../shared/providers/auth_provider.dart';

class EmployeeHomeScreen extends ConsumerStatefulWidget {
  const EmployeeHomeScreen({super.key});
  @override
  ConsumerState<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends ConsumerState<EmployeeHomeScreen> {
  List<dynamic> _markets = [];
  bool _isLoading = true;
  bool _isGridView = false;
  static LocationDataResult? _cachedLocation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      if (_cachedLocation != null) {
        await _fetchMarkets(api, _cachedLocation!);
      } else {
        if (mounted) setState(() => _isLoading = true);
      }

      final loc = await LocationService.getCurrentLocation();
      _cachedLocation = loc;
      await _fetchMarkets(api, loc);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMarkets(ApiClient api, LocationDataResult loc) async {
    final res = await api.get(
      ApiConstants.markets,
      queryParameters: {
        'lat': loc.latitude,
        'lng': loc.longitude,
        'radius': 50,
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    final List<dynamic> rawList = res.data ?? [];
    if (mounted) {
      setState(() {
        _markets = rawList.where((m) => m['isActive'] == true).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _onMarketTap(Map<String, dynamic> market) async {
    final distance = (market['distance'] as num?)?.toDouble() ?? 0.0;
    if (distance > 1.0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Bu pazar 1.0 km sınırınızın dışında (${distance.toStringAsFixed(1)} km). Sadece 1km içindeki yakın pazarlarda ürün/fiyat güncellemesi yapabilirsiniz!'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    await context.push('/employee/update/${market['id']}');
    if (mounted) {
      _load();
    }
  }

  Widget _buildEmployeeMarketImage(String? url, bool isWithinDistance) {
    if (url == null || url.trim().isEmpty) {
      return Icon(
        isWithinDistance ? Icons.storefront_rounded : Icons.lock_clock_rounded,
        color: isWithinDistance ? AppColors.primary : const Color(0xFFEF4444),
        size: 26,
      );
    }
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {
        return Icon(
          isWithinDistance ? Icons.storefront_rounded : Icons.lock_clock_rounded,
          color: isWithinDistance ? AppColors.primary : const Color(0xFFEF4444),
          size: 26,
        );
      }
    }
    final formatted = getFormattedImageUrl(url);
    if (formatted != null && formatted.startsWith('http')) {
      return Image.network(
        formatted,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          isWithinDistance ? Icons.storefront_rounded : Icons.lock_clock_rounded,
          color: isWithinDistance ? AppColors.primary : const Color(0xFFEF4444),
          size: 26,
        ),
      );
    }
    return Icon(
      isWithinDistance ? Icons.storefront_rounded : Icons.lock_clock_rounded,
      color: isWithinDistance ? AppColors.primary : const Color(0xFFEF4444),
      size: 26,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Pazar Ürün Yönetimi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48)),
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(authStateProvider.notifier).logout();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF047857), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.badge_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Saha Çalışan Paneli', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                                Text('Yakın Pazarlar (Maks 1.0 km)', style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Fiyat ve stok güncelleyebilmek için pazara 1km\'den daha yakın olmanız gerekmektedir.',
                          style: TextStyle(color: Color(0xFFECFDF5), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Text('Görev Yapabileceğiniz Pazarlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const Spacer(),
                      IconButton(
                        icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: AppColors.primary),
                        tooltip: _isGridView ? 'Liste Görünümü' : 'Izgara Görünümü',
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                      Text('${_markets.length} Pazar', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_markets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Aktif pazar bulunamadı', style: TextStyle(color: Color(0xFF64748B))),
                    )
                  else if (!_isGridView)

                    ..._markets.map((m) {
                      final distance = (m['distance'] as num?)?.toDouble() ?? 0.0;
                      final isWithinDistance = distance <= 1.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _onMarketTap(m),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isWithinDistance ? const Color(0xFFE2E8F0) : const Color(0xFFFCA5A5)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isWithinDistance ? AppColors.primarySurface : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: _buildEmployeeMarketImage(m['imageUrl'] as String?, isWithinDistance),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 2),
                                      Text('${m['district']}, ${m['city']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      const SizedBox(height: 4),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Text('🏪 ${m['stallCount'] ?? 0} Tezgah', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                            const Text(' • ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                            Text('📂 ${m['categoryCount'] ?? 0} Kategori', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isWithinDistance ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isWithinDistance ? '${distance.toStringAsFixed(1)} km 📍' : '🔒 >1.0 km',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isWithinDistance ? AppColors.primary : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                  else

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _markets.length,
                      itemBuilder: (context, idx) {
                        final m = _markets[idx];
                        final distance = (m['distance'] as num?)?.toDouble() ?? 0.0;
                        final isWithinDistance = distance <= 1.0;

                        return InkWell(
                          onTap: () => _onMarketTap(m),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isWithinDistance ? const Color(0xFFE2E8F0) : const Color(0xFFFCA5A5), width: 1.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isWithinDistance ? AppColors.primarySurface : const Color(0xFFFEF2F2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isWithinDistance ? Icons.storefront_rounded : Icons.lock_clock_rounded,
                                    color: isWithinDistance ? AppColors.primary : const Color(0xFFEF4444),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  m['name'] ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '🏪 ${m['stallCount'] ?? 0} Tezgah • 📂 ${m['categoryCount'] ?? 0} Kat.',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isWithinDistance ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isWithinDistance ? '${distance.toStringAsFixed(1)} km 📍' : '🔒 >1.0 km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isWithinDistance ? AppColors.primary : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

