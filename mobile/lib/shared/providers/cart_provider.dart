import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

final cartItemCountProvider = StateNotifierProvider<CartItemCountNotifier, int>((ref) {
  return CartItemCountNotifier(ref);
});

class CartItemCountNotifier extends StateNotifier<int> {
  final Ref _ref;

  CartItemCountNotifier(this._ref) : super(0) {
    refreshCartCount();
  }

  Future<void> refreshCartCount() async {
    try {
      final api = _ref.read(apiClientProvider);
      final res = await api.get(ApiConstants.cart);
      final items = (res.data?['items'] as List?) ?? [];
      state = items.length;
    } catch (_) {
      state = 0;
    }
  }

  void updateCount(int newCount) {
    state = newCount;
  }
}

