import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/cart_provider.dart';
import '../../../../core/utils/string_utils.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  List<dynamic> _markets = [];
  bool _isLoading = true;
  bool _isGridView = false;
  final _searchC = TextEditingController();

  List<dynamic> _userAddresses = [];
  Map<String, dynamic>? _selectedAddress;

  Widget _buildCustomerMarketImage(String? url, double iconSize) {
    if (url == null || url.trim().isEmpty) {
      return Icon(Icons.storefront_rounded, color: AppColors.primary, size: iconSize);
    }
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {
        return Icon(Icons.storefront_rounded, color: AppColors.primary, size: iconSize);
      }
    }
    final formatted = getFormattedImageUrl(url);
    if (formatted != null && formatted.startsWith('http')) {
      return Image.network(
        formatted,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.storefront_rounded, color: AppColors.primary, size: iconSize),
      );
    }
    return Icon(Icons.storefront_rounded, color: AppColors.primary, size: iconSize);
  }

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
        _userAddresses = addrRes.data;
      } else if (addrRes.data is Map && addrRes.data['addresses'] != null) {
        _userAddresses = addrRes.data['addresses'];
      } else if (addrRes.data is Map && addrRes.data['data'] != null) {
        _userAddresses = addrRes.data['data'];
      }

      if (_userAddresses.isNotEmpty && _selectedAddress == null) {
        _selectedAddress = _userAddresses.firstWhere((a) => a['isDefault'] == true, orElse: () => _userAddresses.first);
      }

      final double lat = (_selectedAddress?['latitude'] as num?)?.toDouble() ?? 40.9875;
      final double lng = (_selectedAddress?['longitude'] as num?)?.toDouble() ?? 29.0250;
      final city = _selectedAddress?['city'] ?? 'İstanbul';
      final district = _selectedAddress?['district'] ?? 'Kadıköy';

      final marketsRes = await api.get(
        ApiConstants.markets,
        queryParameters: {'lat': lat, 'lng': lng, 'city': city, 'district': district, 'radius': 50},
      );
      _markets = marketsRes.data ?? [];

      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddressPickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Teslimat Adresi Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 8),

                  if (_userAddresses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: const [
                          Icon(Icons.location_off_rounded, color: Color(0xFF64748B)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('Kayıtlı adresiniz yok. Lütfen yeni bir adres ekleyin.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._userAddresses.map((addr) {
                      final isSelected = addr['id'] == _selectedAddress?['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedAddress = addr);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppColors.primary : const Color(0xFF94A3B8)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(addr['title'] ?? 'Adres', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      Text(addr['fullAddress'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context.push('/addresses');
                        _loadData();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary, size: 20),
                      label: const Text(
                        'Yeni Adres Ekle',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    final filteredMarkets = _markets.where((m) {
      if (_searchC.text.trim().isEmpty) return true;
      final q = _searchC.text.trim().toLowerCase();
      final name = (m['name'] ?? '').toString().toLowerCase();
      final district = (m['district'] ?? '').toString().toLowerCase();
      return name.contains(q) || district.contains(q);
    }).toList();

    String addressText = 'Adres Seçiniz / Ekle';
    if (_selectedAddress != null) {
      final title = (_selectedAddress!['title'] ?? '').toString().trim();
      final district = (_selectedAddress!['district'] ?? '').toString().trim();
      final city = (_selectedAddress!['city'] ?? '').toString().trim();

      if (title.isNotEmpty) {
        addressText = district.isNotEmpty ? '$title ($district)' : title;
      } else if (district.isNotEmpty && city.isNotEmpty) {
        addressText = '$district, $city';
      } else if (_selectedAddress!['fullAddress'] != null && _selectedAddress!['fullAddress'].toString().trim().isNotEmpty) {
        addressText = _selectedAddress!['fullAddress'].toString().trim();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: InkWell(
          onTap: _showAddressPickerModal,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Teslimat Adresi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            addressText,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF0F172A)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final cartCount = ref.watch(cartItemCountProvider);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A), size: 20),
                    ),
                    onPressed: () => context.go('/cart'),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 20),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş Geldin, ${auth.userName ?? 'Komşu'} 👋',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bugün semt pazarından ne istersiniz? Taze sebze ve meyveler dakikalar içinde kapınızda.',
                        style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_selectedAddress == null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_off_rounded, size: 36, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Semt Pazarlarını Görmek İçin Adres Seçiniz',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Konumunuza en yakın semt pazarlarını ve taze pazar ürünlerini listeleyebilmemiz için lütfen bir teslimat adresi seçin veya yeni bir adres ekleyin.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _showAddressPickerModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                            label: const Text('Adres Ekle veya Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[

                  TextFormField(
                    controller: _searchC,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Pazar veya semt arayın...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                      fillColor: Colors.white,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Text('Yakınınızdaki Semt Pazarları', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.view_list_rounded,
                                color: !_isGridView ? AppColors.primary : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isGridView = false),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.grid_view_rounded,
                                color: _isGridView ? AppColors.primary : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isGridView = true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (filteredMarkets.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_outlined, size: 48, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Yakınınızda Aktif Pazar Bulunmuyor',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bulunduğunuz konuma veya seçili teslimat adresinize yakın aktif pazar bulunmuyor. Yeni bir adres ekleyebilir veya yönetici tarafından bu bölgeye pazar tanımlanmasını bekleyebilirsiniz.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    )
                  else if (!_isGridView)
                    ...filteredMarkets.map(
                      (market) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (market['isActive'] == true) {
                                context.push('/market/${market['id']}');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('⚠️ Bu pazar şu anda kapalıdır. Sipariş vermek için açık pazarları seçebilirsiniz.'),
                                    backgroundColor: AppColors.error,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySurface,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: _buildCustomerMarketImage(market['imageUrl'] as String?, 32),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                market['name'] ?? '',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: (market['isActive'] == true) ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                (market['isActive'] == true) ? 'AÇIK' : 'KAPALI',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: (market['isActive'] == true) ? AppColors.primary : AppColors.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.near_me_rounded, size: 14, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${((market['distance'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)} km',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF94A3B8)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${market['openTime'] ?? '07:00'} - ${market['closeTime'] ?? '18:00'}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: filteredMarkets.length,
                      itemBuilder: (context, i) {
                        final market = filteredMarkets[i];
                        final isOpen = market['isActive'] == true;
                        final distance = (market['distance'] as num?)?.toDouble() ?? 0.0;
                        final imageUrl = market['imageUrl'] as String?;
                        final openTime = market['openTime'] ?? '07:00';
                        final closeTime = market['closeTime'] ?? '18:00';

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (isOpen) {
                                context.push('/market/${market['id']}');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('⚠️ Bu pazar şu anda kapalıdır. Sipariş vermek için açık pazarları seçebilirsiniz.'),
                                    backgroundColor: AppColors.error,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySurface,
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: _buildCustomerMarketImage(imageUrl, 48),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isOpen ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isOpen ? 'AÇIK' : 'KAPALI',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isOpen ? AppColors.primary : AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    market['name'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${market['district'] ?? ''}, ${market['city'] ?? ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '🕒 $openTime - $closeTime',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(Icons.near_me_rounded, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${distance.toStringAsFixed(1)} km',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

