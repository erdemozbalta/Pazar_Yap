import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final role = auth.userRole;

    final cartCount = ref.watch(cartItemCountProvider);

    List<Widget> navItems = [];

    if (role == 'ADMIN') {
      navItems = [
        _PillNavItem(
          icon: Icons.dashboard_rounded,
          label: 'Panel',
          path: '/admin',
          isSelected: _isSelected(context, '/admin'),
        ),
        _PillNavItem(
          icon: Icons.storefront_rounded,
          label: 'Pazarlar',
          path: '/admin/markets',
          isSelected: _isSelected(context, '/admin/markets'),
        ),
        _PillNavItem(
          icon: Icons.person_rounded,
          label: 'Hesabım',
          path: '/profile',
          isSelected: _isSelected(context, '/profile'),
        ),
      ];
    } else if (role == 'EMPLOYEE') {
      navItems = [
        _PillNavItem(
          icon: Icons.storefront_rounded,
          label: 'Pazarlarım',
          path: '/employee',
          isSelected: _isSelected(context, '/employee'),
        ),
        _PillNavItem(
          icon: Icons.person_rounded,
          label: 'Hesabım',
          path: '/profile',
          isSelected: _isSelected(context, '/profile'),
        ),
      ];
    } else if (role == 'COURIER') {
      navItems = [
        _PillNavItem(
          icon: Icons.directions_run_rounded,
          label: 'Görevler',
          path: '/courier',
          isSelected: _isSelected(context, '/courier'),
        ),
        _PillNavItem(
          icon: Icons.receipt_long_rounded,
          label: 'Siparişler',
          path: '/courier/orders',
          isSelected: _isSelected(context, '/courier/orders'),
        ),
        _PillNavItem(
          icon: Icons.person_rounded,
          label: 'Hesabım',
          path: '/profile',
          isSelected: _isSelected(context, '/profile'),
        ),
      ];
    } else {

      navItems = [
        _PillNavItem(
          icon: Icons.storefront_rounded,
          label: 'Pazarlar',
          path: '/home',
          isSelected: _isSelected(context, '/home'),
        ),
        _PillNavItem(
          icon: Icons.shopping_cart_rounded,
          label: 'Sepet',
          path: '/cart',
          isSelected: _isSelected(context, '/cart'),
          badgeCount: cartCount,
        ),
        _PillNavItem(
          icon: Icons.receipt_long_rounded,
          label: 'Siparişler',
          path: '/orders',
          isSelected: _isSelected(context, '/orders'),
        ),
        _PillNavItem(
          icon: Icons.person_rounded,
          label: 'Hesabım',
          path: '/profile',
          isSelected: _isSelected(context, '/profile'),
        ),
      ];
    }

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: navItems,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSelected(BuildContext context, String path) {
    final location = GoRouterState.of(context).matchedLocation;
    return location == path;
  }
}

class _PillNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isSelected;
  final int badgeCount;

  const _PillNavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isSelected,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(path),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      alignment: Alignment.center,
                      child: Text(
                        '$badgeCount',
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

