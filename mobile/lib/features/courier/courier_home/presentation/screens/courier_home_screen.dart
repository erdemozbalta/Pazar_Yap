import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../shared/providers/auth_provider.dart';

import '../../../../../core/services/location_service.dart';
import '../../../../../core/utils/string_utils.dart';

class CourierHomeScreen extends ConsumerStatefulWidget {
  const CourierHomeScreen({super.key});

  @override
  ConsumerState<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends ConsumerState<CourierHomeScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _activeOrder;
  List<dynamic> _markets = [];
  bool _isLoading = true;

  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load(force: true);
  }

  Future<void> _load({bool force = false}) async {
    if (!force && _lastLoadTime != null && DateTime.now().difference(_lastLoadTime!).inMilliseconds < 500) {
      return;
    }
    _lastLoadTime = DateTime.now();
    if (force && mounted) {
      setState(() {
        _activeOrder = null;
      });
    }
    try {
      LocationDataResult? loc;
      try {
        loc = await LocationService.getCurrentLocation();
      } catch (_) {}
      final api = ref.read(apiClientProvider);
      final queryParams = <String, dynamic>{
        'radius': 50,
        '_t': DateTime.now().millisecondsSinceEpoch,
      };
      if (loc != null) {
        queryParams['lat'] = loc.latitude;
        queryParams['lng'] = loc.longitude;
      }
      final [profileRes, marketsRes, activeOrderRes] = await Future.wait([
        api.get(ApiConstants.courierProfile),
        api.get(ApiConstants.markets, queryParameters: queryParams),
        api.get('/couriers/active-order'),
      ]);

      final List<dynamic> loadedMarkets = marketsRes.data ?? [];
      final activeMarkets = loadedMarkets.where((m) => m['isActive'] == true).toList();

      final rawActive = activeOrderRes.data;
      final activeStatus = rawActive?['status'] as String?;
      final isOngoing = rawActive != null &&
          activeStatus != 'DELIVERED' &&
          activeStatus != 'CANCELLED';

      if (mounted) {
        setState(() {
          _profile = profileRes.data;
          _markets = activeMarkets;
          _activeOrder = isOngoing ? rawActive : null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAvailability(bool val) async {
    final selectedMarketId = _profile?['selectedMarketId'];

    if (val) {
      if (selectedMarketId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müsait olmak için önce aşağıdan bir pazar seçiniz!'), backgroundColor: AppColors.warning),
        );
        return;
      }

      dynamic selectedM = _markets.firstWhere((m) => m['id'] == selectedMarketId, orElse: () => null);
      final dist = (selectedM?['distance'] as num?)?.toDouble() ?? 0.0;
      if (dist > 3.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seçili pazar 3.0 km mesafeden uzak (${dist.toStringAsFixed(1)} km). Müsait olamazsınız!'), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    setState(() {
      if (_profile == null) {
        _profile = {'isAvailable': val, 'selectedMarketId': val ? selectedMarketId : null};
      } else {
        _profile!['isAvailable'] = val;
        if (!val) {
          _profile!['selectedMarketId'] = null;
          _profile!['selectedMarket'] = null;
        }
      }
    });

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.put(ApiConstants.courierAvailability, data: {
        'isAvailable': val,
        'selectedMarketId': val ? selectedMarketId : null,
      });
      if (mounted) {
        setState(() {
          _profile = res.data?['profile'] ?? _profile;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(val ? 'Müsait durumdasınız.' : 'Müsaitlik kapatıldı.'),
            backgroundColor: val ? AppColors.success : AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final err = (e as dynamic).response?.data?['error'] ?? 'Durum değiştirilemedi';
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.error),
        );
      }
      _load();
    }
  }

  DateTime? _lastMarketSelectTime;

  Future<void> _selectMarket(Map<String, dynamic> market) async {
    if (_lastMarketSelectTime != null) {
      final elapsed = DateTime.now().difference(_lastMarketSelectTime!).inSeconds;
      if (elapsed < 30) {
        final remaining = 30 - elapsed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏳ Pazar değiştirmek için lütfen $remaining saniye bekleyiniz.'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final distance = (market['distance'] as num?)?.toDouble() ?? 0.0;

    if (distance > 3.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu pazar 3.0 km sınırının dışında (${distance.toStringAsFixed(1)} km). Sadece 3km içindeki pazarları seçebilirsiniz!'), backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.put(ApiConstants.courierAvailability, data: {
        'isAvailable': false,
        'selectedMarketId': market['id'],
      });

      if (mounted) {
        _lastMarketSelectTime = DateTime.now();
        setState(() {
          _profile = res.data?['profile'] ?? _profile;
          _profile?['selectedMarketId'] = market['id'];
          _profile?['selectedMarket'] = market;
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görev pazarı "${market['name']}" seçildi! Şimdi müsaitliği açabilirsiniz. 🏬'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pazar seçilirken hata oluştu'), backgroundColor: AppColors.error),
        );
        _load();
      }
    }
  }

  Future<void> _quickOrderAction(String orderId, String action) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('${ApiConstants.orders}/$orderId/$action');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        if (action == 'deliver' || action == 'delivered') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Sipariş başarıyla teslim edildi! Tebrikler!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İşlem başarılı'), backgroundColor: AppColors.success),
          );
        }
        _load();
      }
    } catch (e) {
      if (mounted) {
        final err = (e as dynamic).response?.data?['error'] ?? 'İşlem gerçekleştirilemedi';
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildCourierMarketImage(String? url, bool isWithin3km) {
    if (url == null || url.trim().isEmpty) {
      return Icon(Icons.storefront_rounded, color: isWithin3km ? AppColors.primary : const Color(0xFF94A3B8), size: 24);
    }
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {
        return Icon(Icons.storefront_rounded, color: isWithin3km ? AppColors.primary : const Color(0xFF94A3B8), size: 24);
      }
    }
    final formatted = getFormattedImageUrl(url);
    if (formatted != null && formatted.startsWith('http')) {
      return Image.network(
        formatted,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.storefront_rounded, color: isWithin3km ? AppColors.primary : const Color(0xFF94A3B8), size: 24),
      );
    }
    return Icon(Icons.storefront_rounded, color: isWithin3km ? AppColors.primary : const Color(0xFF94A3B8), size: 24);
  }

  @override
  Widget build(BuildContext context) {
    final selectedMarketId = _profile?['selectedMarketId'];
    final isAvailable = _profile?['isAvailable'] == true && selectedMarketId != null;
    final selectedMarket = _profile?['selectedMarket'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kurye Paneli', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 85),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if (_activeOrder != null &&
                        _activeOrder!['status'] != 'DELIVERED' &&
                        _activeOrder!['status'] != 'CANCELLED') ...[
                      _buildActiveOrderDashboard(context, _activeOrder!),
                    ] else ...[

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: isAvailable
                              ? AppColors.heroGradient
                              : LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade700]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (isAvailable ? AppColors.primary : Colors.grey).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isAvailable ? 'MÜSAİTSİNİZ ✅' : 'KAPALI (Müsait Değil)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAvailable ? 'Sipariş almaya hazırsınız' : 'Aşağıdan pazar seçip durumu açın',
                                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isAvailable,
                              onChanged: _toggleAvailability,
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppColors.primarySurface,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (selectedMarket != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primary),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Seçili Görev Pazarı', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                    Text(selectedMarket['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _ActionCard(icon: Icons.list_alt_rounded, label: 'Siparişler', color: AppColors.info, onTap: () => context.push('/courier/orders'))),
                              const SizedBox(width: 10),
                              Expanded(child: _ActionCard(icon: Icons.monetization_on_rounded, label: 'Kazançlar', color: AppColors.success, onTap: () => context.push('/courier/earnings'))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _ActionCard(icon: Icons.history_rounded, label: 'Son Siparişlerim', color: const Color(0xFF8B5CF6), onTap: () => context.push('/courier/earnings'))),
                              const SizedBox(width: 10),
                              Expanded(child: _ActionCard(icon: Icons.tune_rounded, label: 'Ücretlendirme', color: AppColors.secondary, onTap: () => context.push('/courier/pricing'))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: const [
                          Text('Yakındaki Pazarlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          Spacer(),
                          Text('Max 3 km Sınırı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ..._markets.map((m) {
                        final isSelected = m['id'] == _profile?['selectedMarketId'];
                        final distance = (m['distance'] as num?)?.toDouble() ?? 0.0;
                        final isWithin3km = distance <= 3.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => _selectMarket(m),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFECFDF5) : (isWithin3km ? Colors.white : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isWithin3km ? AppColors.primarySurface : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: _buildCourierMarketImage(m['imageUrl'] as String?, isWithin3km),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m['name'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isWithin3km ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))),
                                        Text('${m['district']}, ${m['city']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isWithin3km ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${distance.toStringAsFixed(1)} km ${isWithin3km ? '' : '(>3km)'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isWithin3km ? AppColors.primary : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActiveOrderDashboard(BuildContext context, Map<String, dynamic> order) {
    final orderNumber = (order['orderNumber'] ?? '').toString();
    final status = (order['status'] ?? '').toString();
    final marketName = order['market']?['name'] ?? 'Pazar';
    final customer = order['customer'];
    final customerName = '${customer?['firstName'] ?? ''} ${customer?['lastName'] ?? ''}'.trim();
    final customerPhone = customer?['phone'] ?? '';
    final address = order['address'];
    final addressTitle = address?['title'] ?? 'Teslimat Adresi';
    final fullAddress = address?['fullAddress'] ?? '';
    final courierFee = (order['courierFee'] as num?)?.toDouble() ?? 0.0;
    final distanceKm = (order['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final totalWeight = (order['totalWeight'] as num?)?.toDouble() ?? 0.0;
    final items = (order['items'] as List?) ?? [];
    final collectedCount = items.where((i) => i['isCollected'] == true).length;

    String statusText = 'Kurye Atandı';
    int stepIndex = 0;
    if (status == 'SHOPPING_IN_PROGRESS') {
      statusText = 'Pazardan Ürünler Toplanıyor 🛒';
      stepIndex = 1;
    } else if (status == 'ON_THE_WAY') {
      statusText = 'Müşteriye Teslimat İçin Yolda 🚀';
      stepIndex = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.35),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.directions_run_rounded, color: Color(0xFFF87171), size: 16),
                        SizedBox(width: 6),
                        Text('AKTİF TESLİMAT GÖREVİ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFF87171))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '₺${courierFee.toStringAsFixed(2)} Kazanç',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Sipariş #${orderNumber.length > 8 ? orderNumber.substring(0, 8) : orderNumber}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  _buildProgressStep(title: '1. Atandı', isDone: stepIndex >= 0, isActive: stepIndex == 0),
                  _buildStepConnector(isDone: stepIndex >= 1),
                  _buildProgressStep(title: '2. Toplanıyor', isDone: stepIndex >= 1, isActive: stepIndex == 1),
                  _buildStepConnector(isDone: stepIndex >= 2),
                  _buildProgressStep(title: '3. Yolda', isDone: stepIndex >= 2, isActive: stepIndex == 2),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Görev Pazarı', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        Text(marketName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        if (customerPhone.isNotEmpty)
                          Text(customerPhone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                        const SizedBox(height: 4),
                        Text(
                          '$addressTitle: $fullAddress',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricChip(icon: Icons.straighten_rounded, label: 'Mesafe', value: '${distanceKm.toStringAsFixed(1)} km'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricChip(icon: Icons.scale_rounded, label: 'Ağırlık', value: '${totalWeight.toStringAsFixed(1)} kg'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricChip(icon: Icons.shopping_basket_rounded, label: 'Ürün', value: '${items.length} Kalem'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Toplanacak Ürünler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: collectedCount == items.length ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$collectedCount / ${items.length} Toplandı',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: collectedCount == items.length ? const Color(0xFF166534) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.take(4).map((it) {
                final vp = it['vendorProduct'];
                final prodName = vp?['product']?['name'] ?? '';
                final unit = vp?['product']?['unit'] ?? 'kg';
                final qty = (it['quantity'] as num?)?.toDouble() ?? 0.0;
                final stallLoc = vp?['stallLocation'] ?? 'Tezgah Belirtilmemiş';
                final isCollected = it['isCollected'] == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        isCollected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isCollected ? AppColors.primary : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$prodName (${qty.toStringAsFixed(1)} $unit)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                decoration: isCollected ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text('📍 $stallLoc', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (items.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+ ${items.length - 4} ürün daha var...', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (status == 'ON_THE_WAY')
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _quickOrderAction(order['id'], 'deliver'),
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                    label: const Text('Teslim Ettim ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final orderId = order['id'];
                    context.go('/courier/order/$orderId');
                  },
                  icon: const Icon(Icons.list_alt_rounded, size: 20),
                  label: const Text('Detaylar'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                final orderId = order['id'];
                context.go('/courier/order/$orderId');
              },
              icon: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 24),
              label: const Text('Siparişi Yönet & Ürünleri Topla ➔', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildProgressStep({required String title, required bool isDone, required bool isActive}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? const Color(0xFF10B981) : (isActive ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isDone || isActive ? FontWeight.w800 : FontWeight.w500,
              color: isDone || isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isDone}) {
    return Container(
      width: 24,
      height: 3,
      color: isDone ? const Color(0xFF10B981) : const Color(0xFF334155),
      margin: const EdgeInsets.only(bottom: 18),
    );
  }

  Widget _buildMetricChip({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

