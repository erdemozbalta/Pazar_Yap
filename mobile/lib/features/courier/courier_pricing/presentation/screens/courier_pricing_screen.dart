import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';

class CourierPricingScreen extends ConsumerStatefulWidget {
  const CourierPricingScreen({super.key});

  @override
  ConsumerState<CourierPricingScreen> createState() => _CourierPricingScreenState();
}

class _CourierPricingScreenState extends ConsumerState<CourierPricingScreen> {
  final _baseFeeC = TextEditingController();
  List<Map<String, dynamic>> _distanceTiers = [];
  List<Map<String, dynamic>> _weightTiers = [];
  bool _isLoading = true;
  bool _isSavingBase = false;
  bool _isSavingDistance = false;
  bool _isSavingWeight = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiConstants.courierProfile);
      final data = res.data;
      _baseFeeC.text = (data['baseFee'] as num? ?? 25.0).toString();

      _distanceTiers = ((data['distanceTiers'] as List?) ?? []).map<Map<String, dynamic>>((t) => {
        'min': TextEditingController(text: t['minKm'].toString()),
        'max': TextEditingController(text: t['maxKm'].toString()),
        'pct': TextEditingController(text: t['percentageIncrease'].toString()),
        'type': t['increaseType'] ?? 'PERCENTAGE',
      }).toList();

      if (_distanceTiers.isEmpty) {
        _distanceTiers = [
          {'min': TextEditingController(text: '3'), 'max': TextEditingController(text: '5'), 'pct': TextEditingController(text: '10'), 'type': 'PERCENTAGE'},
          {'min': TextEditingController(text: '5'), 'max': TextEditingController(text: '10'), 'pct': TextEditingController(text: '25'), 'type': 'PERCENTAGE'},
        ];
      }

      _weightTiers = ((data['weightTiers'] as List?) ?? []).map<Map<String, dynamic>>((t) => {
        'min': TextEditingController(text: t['minKg'].toString()),
        'max': TextEditingController(text: t['maxKg'].toString()),
        'pct': TextEditingController(text: t['percentageIncrease'].toString()),
        'type': t['increaseType'] ?? 'PERCENTAGE',
      }).toList();

      if (_weightTiers.isEmpty) {
        _weightTiers = [
          {'min': TextEditingController(text: '5'), 'max': TextEditingController(text: '10'), 'pct': TextEditingController(text: '15'), 'type': 'PERCENTAGE'},
          {'min': TextEditingController(text: '10'), 'max': TextEditingController(text: '20'), 'pct': TextEditingController(text: '30'), 'type': 'PERCENTAGE'},
        ];
      }

      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _addDistanceTier() {
    double lastMax = 3.0;
    if (_distanceTiers.isNotEmpty) {
      lastMax = double.tryParse(_distanceTiers.last['min']!.text) ?? 3.0;
      final maxVal = double.tryParse(_distanceTiers.last['max']!.text);
      if (maxVal != null && maxVal > lastMax) lastMax = maxVal;
    }
    double nextMax = lastMax + 3.0;

    setState(() {
      _distanceTiers.add({
        'min': TextEditingController(text: lastMax.toStringAsFixed(0)),
        'max': TextEditingController(text: nextMax.toStringAsFixed(0)),
        'pct': TextEditingController(text: '10'),
        'type': 'PERCENTAGE',
      });
    });
  }

  void _addWeightTier() {
    double lastMax = 5.0;
    if (_weightTiers.isNotEmpty) {
      lastMax = double.tryParse(_weightTiers.last['min']!.text) ?? 5.0;
      final maxVal = double.tryParse(_weightTiers.last['max']!.text);
      if (maxVal != null && maxVal > lastMax) lastMax = maxVal;
    }
    double nextMax = lastMax + 5.0;

    setState(() {
      _weightTiers.add({
        'min': TextEditingController(text: lastMax.toStringAsFixed(0)),
        'max': TextEditingController(text: nextMax.toStringAsFixed(0)),
        'pct': TextEditingController(text: '15'),
        'type': 'PERCENTAGE',
      });
    });
  }

  Future<void> _saveSection(String section) async {
    setState(() {
      if (section == 'base' || section == 'all') _isSavingBase = true;
      if (section == 'distance' || section == 'all') _isSavingDistance = true;
      if (section == 'weight' || section == 'all') _isSavingWeight = true;
    });

    try {
      final api = ref.read(apiClientProvider);
      await api.put(ApiConstants.courierPricing, data: {
        'baseFee': double.tryParse(_baseFeeC.text) ?? 100.0,
        'distanceTiers': _distanceTiers.asMap().entries.map((e) => {
          'minKm': double.tryParse(e.value['min']!.text) ?? 0,
          'maxKm': double.tryParse(e.value['max']!.text) ?? 0,
          'percentageIncrease': double.tryParse(e.value['pct']!.text) ?? 0,
          'increaseType': e.value['type'] ?? 'PERCENTAGE',
          'sortOrder': e.key,
        }).toList(),
        'weightTiers': _weightTiers.asMap().entries.map((e) => {
          'minKg': double.tryParse(e.value['min']!.text) ?? 0,
          'maxKg': double.tryParse(e.value['max']!.text) ?? 0,
          'percentageIncrease': double.tryParse(e.value['pct']!.text) ?? 0,
          'increaseType': e.value['type'] ?? 'PERCENTAGE',
          'sortOrder': e.key,
        }).toList(),
      });

      if (mounted) {
        String msg = 'Ücretlendirme ayarları kaydedildi ✅';
        if (section == 'base') msg = 'Taban teslimat ücreti kaydedildi ✅';
        if (section == 'distance') msg = 'Mesafe kademeleri kaydedildi ✅';
        if (section == 'weight') msg = 'Ağırlık kademeleri kaydedildi ✅';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        final err = (e as dynamic).response?.data?['error'] ?? 'Kaydetme hatası oluştu';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Hata: $err', style: const TextStyle(fontWeight: FontWeight.w700)),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (section == 'base' || section == 'all') _isSavingBase = false;
          if (section == 'distance' || section == 'all') _isSavingDistance = false;
          if (section == 'weight' || section == 'all') _isSavingWeight = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ücretlendirme Ayarları', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text('Ücretlendirme Kuralları', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• 0 - 3 km Mesafe ve 0 - 5 kg Paket Ağırlığı standart Temel Teslimat Ücretine tabidir (Ek ücret eklenmez).\n'
                          '• 3 km üzerindeki mesafeler için Mesafe Ek Ücreti, 5 kg üzerindeki paketler için Ağırlık Ek Ücreti uygulanır.\n'
                          '• Ek ücret artış türünü % (Yüzde) veya ₺ (Sabit TL) olarak belirleyebilirsiniz.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildCardSection(
                    title: '1. Taban Teslimat Ücreti',
                    subtitle: '0 - 3 km ve 0 - 5 kg arası temel teslimat ücretinizdir (₺)',
                    onSave: () => _saveSection('base'),
                    isSaving: _isSavingBase,
                    child: TextFormField(
                      controller: _baseFeeC,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary),
                        suffixText: '₺',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildCardSection(
                    title: '2. Mesafe Kademeleri',
                    subtitle: '3 km üzerindeki mesafeler için % zam veya ₺ ek ücret',
                    onSave: () => _saveSection('distance'),
                    isSaving: _isSavingDistance,
                    onAdd: _addDistanceTier,
                    child: Column(
                      children: [
                        ..._distanceTiers.asMap().entries.map((e) {
                          return _TierRow(
                            index: e.key,
                            minC: e.value['min']!,
                            maxC: e.value['max']!,
                            pctC: e.value['pct']!,
                            type: e.value['type'] ?? 'PERCENTAGE',
                            unitLabel: 'km',
                            onTypeChanged: (newType) => setState(() => _distanceTiers[e.key]['type'] = newType),
                            onRemove: () => setState(() => _distanceTiers.removeAt(e.key)),
                          );
                        }),
                        if (_distanceTiers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Henüz kademe yok. Elemek için "+" butonuna basın.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildCardSection(
                    title: '3. Paket Ağırlık Kademeleri',
                    subtitle: 'Ağır pazar poşetleri için % zam veya ₺ ek taşıma primi',
                    onSave: () => _saveSection('weight'),
                    isSaving: _isSavingWeight,
                    onAdd: _addWeightTier,
                    child: Column(
                      children: [
                        ..._weightTiers.asMap().entries.map((e) {
                          return _TierRow(
                            index: e.key,
                            minC: e.value['min']!,
                            maxC: e.value['max']!,
                            pctC: e.value['pct']!,
                            type: e.value['type'] ?? 'PERCENTAGE',
                            unitLabel: 'kg',
                            onTypeChanged: (newType) => setState(() => _weightTiers[e.key]['type'] = newType),
                            onRemove: () => setState(() => _weightTiers.removeAt(e.key)),
                          );
                        }),
                        if (_weightTiers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Henüz ağırlık kademesi yok. Elemek için "+" butonuna basın.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: (_isSavingBase || _isSavingDistance || _isSavingWeight) ? null : () => _saveSection('all'),
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text('Tüm Ayarları Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required String subtitle,
    required Widget child,
    required VoidCallback onSave,
    required bool isSaving,
    VoidCallback? onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (onAdd != null)
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 26),
                  onPressed: onAdd,
                  tooltip: 'Yeni Kademe Ekle',
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded, size: 18),
              label: Text(isSaving ? 'Kaydediliyor...' : 'Bu Bölümü Kaydet', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final int index;
  final TextEditingController minC, maxC, pctC;
  final String type;
  final String unitLabel;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onRemove;

  const _TierRow({
    required this.index,
    required this.minC,
    required this.maxC,
    required this.pctC,
    required this.type,
    required this.unitLabel,
    required this.onTypeChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isPercentage = type == 'PERCENTAGE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min $unitLabel',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: maxC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max $unitLabel',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: pctC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isPercentage ? '% Zam' : '₺ Ek Ücret',
                    suffixText: isPercentage ? '%' : '₺',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                onPressed: onRemove,
                tooltip: 'Kademeyi Sil',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Zam Tipi: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'PERCENTAGE', label: Text('% Yüzde'), icon: Icon(Icons.percent_rounded, size: 14)),
                  ButtonSegment(value: 'FIXED_TL', label: Text('₺ Sabit TL'), icon: Icon(Icons.attach_money_rounded, size: 14)),
                ],
                selected: {type},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) onTypeChanged(set.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

