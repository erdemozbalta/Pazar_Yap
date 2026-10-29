import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/verification_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/home/presentation/screens/customer_home_screen.dart';
import '../features/market_detail/presentation/screens/market_detail_screen.dart';
import '../features/product_detail/presentation/screens/product_detail_screen.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/checkout/presentation/screens/checkout_screen.dart';
import '../features/checkout/presentation/screens/payment_screen.dart';
import '../features/orders/presentation/screens/orders_screen.dart';
import '../features/orders/presentation/screens/order_detail_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/addresses_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/courier/courier_home/presentation/screens/courier_home_screen.dart';
import '../features/courier/courier_orders/presentation/screens/courier_orders_screen.dart';
import '../features/courier/courier_orders/presentation/screens/courier_order_detail_screen.dart';
import '../features/courier/courier_pricing/presentation/screens/courier_pricing_screen.dart';
import '../features/courier/courier_earnings/presentation/screens/courier_earnings_screen.dart';
import '../features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/user_management/presentation/screens/user_management_screen.dart';
import '../features/admin/market_management/presentation/screens/market_management_screen.dart';
import '../features/admin/employee_management/presentation/screens/employee_management_screen.dart';
import '../features/employee/presentation/screens/employee_home_screen.dart';
import '../features/employee/presentation/screens/product_update_screen.dart';
import '../shared/widgets/main_shell.dart';
import '../shared/providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/role-selection' ||
          state.matchedLocation.startsWith('/forgot-password');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) {
        switch (authState.userRole) {
          case 'COURIER':
            return '/courier';
          case 'ADMIN':
            return '/admin';
          case 'EMPLOYEE':
            return '/employee';
          default:
            return '/home';
        }
      }
      return null;
    },
    routes: [

      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, state) => RegisterScreen(role: state.uri.queryParameters['role'] ?? 'CUSTOMER')),
      GoRoute(path: '/role-selection', builder: (_, __) => const RoleSelectionScreen()),
      GoRoute(path: '/verification', builder: (_, state) => VerificationScreen(
        target: state.uri.queryParameters['target'] ?? '',
        channel: state.uri.queryParameters['channel'] ?? 'sms',
      )),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const CustomerHomeScreen()),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

          GoRoute(path: '/market/:id', builder: (_, state) => MarketDetailScreen(marketId: state.pathParameters['id']!)),
          GoRoute(path: '/product/:id', builder: (_, state) => ProductDetailScreen(
            productId: state.pathParameters['id']!,
            marketId: state.uri.queryParameters['marketId'] ?? '',
          )),

          GoRoute(path: '/courier', builder: (_, __) => const CourierHomeScreen()),
          GoRoute(path: '/courier/orders', builder: (_, __) => const CourierOrdersScreen()),

          GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/users', builder: (_, __) => const UserManagementScreen()),
          GoRoute(path: '/admin/markets', builder: (_, __) => const MarketManagementScreen()),
          GoRoute(path: '/admin/employees', builder: (_, __) => const EmployeeManagementScreen()),

          GoRoute(path: '/employee', builder: (_, __) => const EmployeeHomeScreen()),

          GoRoute(path: '/order/:id', builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
          GoRoute(path: '/courier/order/:id', builder: (_, state) => CourierOrderDetailScreen(orderId: state.pathParameters['id']!)),
          GoRoute(path: '/courier/pricing', builder: (_, __) => const CourierPricingScreen()),
          GoRoute(path: '/courier/earnings', builder: (_, __) => const CourierEarningsScreen()),
          GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
        ],
      ),
      GoRoute(path: '/payment/:orderId', builder: (_, state) => PaymentScreen(orderId: state.pathParameters['orderId']!)),
      GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/employee/update/:marketId', builder: (_, state) => ProductUpdateScreen(marketId: state.pathParameters['marketId']!)),
    ],
  );
});

