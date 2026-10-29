import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiConstants.notifications);
      setState(() { _notifications = res.data['notifications'] ?? []; _isLoading = false; });
    } catch (_) { setState(() => _isLoading = false); }
  }

  Future<void> _markAllRead() async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('${ApiConstants.notifications}/read-all');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler'), actions: [
        if (_notifications.isNotEmpty) TextButton(onPressed: _markAllRead, child: const Text('Tümünü Oku')),
      ]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _notifications.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('Bildirim yok', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (_, i) {
                final n = _notifications[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: n['isRead'] == true ? AppColors.surface : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(n['isRead'] == true ? Icons.notifications_outlined : Icons.notifications_active_rounded, color: n['isRead'] == true ? AppColors.textHint : AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n['title'] ?? '', style: AppTypography.titleMedium),
                      const SizedBox(height: 4),
                      Text(n['message'] ?? '', style: AppTypography.bodySmall),
                    ])),
                  ]),
                );
              },
            ),
    );
  }
}

