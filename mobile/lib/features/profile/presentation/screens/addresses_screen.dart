import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/location_service.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});
  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiConstants.addresses);
      setState(() {
        if (res.data is List) {
          _addresses = res.data;
        } else if (res.data is Map && res.data['addresses'] != null) {
          _addresses = res.data['addresses'];
        } else if (res.data is Map && res.data['data'] != null) {
          _addresses = res.data['data'];
        } else {
          _addresses = [];
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddressForm([Map<String, dynamic>? existing]) {
    final titleC = TextEditingController(text: existing?['title'] ?? '');
    final addressC = TextEditingController(text: existing?['fullAddress'] ?? '');
    final cityC = TextEditingController(text: existing?['city'] ?? '');
    final districtC = TextEditingController(text: existing?['district'] ?? '');
    final neighborhoodC = TextEditingController(text: existing?['neighborhood'] ?? '');
    double selectedLat = (existing?['latitude'] as num?)?.toDouble() ?? 0.0;
    double selectedLng = (existing?['longitude'] as num?)?.toDouble() ?? 0.0;
    bool isDefault = existing?['isDefault'] ?? false;
    bool isDetectingGps = false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => SafeArea(
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(existing == null ? 'Yeni Adres Ekle' : 'Adresi Düzenle', style: AppTypography.headlineMedium),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16, top: 4),
                        child: ElevatedButton(
                          onPressed: isDetectingGps ? null : () async {
                            setS(() => isDetectingGps = true);
                            try {
                              final loc = await LocationService.getCurrentLocation();
                              setS(() {
                                isDetectingGps = false;
                                titleC.text = loc.title;
                                cityC.text = loc.city;
                                districtC.text = loc.district;
                                neighborhoodC.text = loc.neighborhood;
                                addressC.text = loc.fullAddress;
                                selectedLat = loc.latitude;
                                selectedLng = loc.longitude;
                              });
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('📍 Gerçek GPS Konumunuz Saptandı: ${loc.district}, ${loc.city} (${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            } catch (e) {
                              setS(() => isDetectingGps = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Konum alınamadı: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: AppColors.error),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            foregroundColor: const Color(0xFF2563EB),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isDetectingGps)
                                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)))
                              else
                                const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB), size: 22),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isDetectingGps ? 'Konum Saptanıyor...' : 'Mevcut Konumumu Kullan',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)),
                                    ),
                                    const Text(
                                      'Adresi GPS ile Otomatik Sapta',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3B82F6)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextField(
                        controller: titleC,
                        decoration: const InputDecoration(
                          labelText: 'Adres Başlığı *',
                          hintText: 'Ev, İş, Yazlık...',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cityC,
                              decoration: const InputDecoration(labelText: 'İl *', hintText: 'İstanbul', prefixIcon: Icon(Icons.location_city_rounded)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: districtC,
                              decoration: const InputDecoration(labelText: 'İlçe *', hintText: 'Kadıköy', prefixIcon: Icon(Icons.map_outlined)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: neighborhoodC,
                        decoration: const InputDecoration(
                          labelText: 'Semt / Mahalle *',
                          hintText: 'Caferağa Mah. / Moda',
                          prefixIcon: Icon(Icons.home_work_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressC,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Açık Adres (Sokak, Bina No, Daire No) *',
                          hintText: 'Örn: Moda Cad. Güneş Apt. No:14 D:5',
                          helperText: 'En az 10 karakter girmelisiniz',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Varsayılan Adres Yap', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        value: isDefault,
                        onChanged: (v) => setS(() => isDefault = v),
                        activeThumbColor: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            final title = titleC.text.trim();
                            final fullAddress = addressC.text.trim();
                            final city = cityC.text.trim();
                            final district = districtC.text.trim();
                            final neighborhood = neighborhoodC.text.trim();

                            if (title.isEmpty || city.isEmpty || district.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lütfen Adres Başlığı, İl ve İlçe alanlarını doldurunuz.')),
                              );
                              return;
                            }

                            if (fullAddress.length < 5) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lütfen geçerli ve açıklayıcı bir açık adres giriniz.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            setS(() => isSaving = true);

                            final double lat = selectedLat != 0.0 ? selectedLat : 40.9875;
                            final double lng = selectedLng != 0.0 ? selectedLng : 29.0250;

                            final data = {
                              'title': title,
                              'fullAddress': fullAddress,
                              'city': city,
                              'district': district,
                              'neighborhood': neighborhood.isNotEmpty ? neighborhood : district,
                              'latitude': lat,
                              'longitude': lng,
                              'isDefault': isDefault,
                            };
                            try {
                              final api = ref.read(apiClientProvider);

                              if (existing != null && existing['id'] != null) {
                                await api.put('${ApiConstants.addresses}/${existing['id']}', data: data);
                              } else {
                                await api.post(ApiConstants.addresses, data: data);
                              }

                              if (mounted) {
                                Navigator.pop(ctx);
                                _load();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Adresiniz başarıyla kaydedildi!'),
                                    backgroundColor: AppColors.primary,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              setS(() => isSaving = false);
                              if (mounted) {
                                final err = (e as dynamic).response?.data?['error'] ?? 'Adres kaydı başarısız';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Adres Kaydedilemedi: $err'), backgroundColor: AppColors.error),
                                );
                              }
                            }
                          },
                          child: isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(existing == null ? 'Adresi Kaydet' : 'Adresi Güncelle', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Future<void> _delete(String id) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('${ApiConstants.addresses}/$id');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adreslerim'), actions: [
        IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAddressForm()),
      ]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _addresses.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.location_off_outlined, size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('Kayıtlı adres bulunamadı', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: () => _showAddressForm(), icon: const Icon(Icons.add), label: const Text('Yeni Adres Ekle')),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _addresses.length,
              itemBuilder: (_, i) {
                final a = _addresses[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: a['isDefault'] == true ? AppColors.primary : const Color(0xFFE2E8F0),
                        width: a['isDefault'] == true ? 2 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.location_on_rounded, color: a['isDefault'] == true ? AppColors.primary : AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(
                            child: Text(
                              a['title'] ?? '',
                              style: AppTypography.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (a['isDefault'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(4)),
                              child: Text('Varsayılan', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Text(a['fullAddress'] ?? '', style: AppTypography.bodySmall, maxLines: 2),
                      ])),
                      PopupMenuButton(itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                        const PopupMenuItem(value: 'delete', child: Text('Sil')),
                      ], onSelected: (v) { if (v == 'edit') _showAddressForm(a); else _delete(a['id']); }),
                    ]),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showAddressForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              icon: const Icon(Icons.add_location_alt_rounded, size: 22),
              label: const Text('Yeni Adres Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    );
  }
}

