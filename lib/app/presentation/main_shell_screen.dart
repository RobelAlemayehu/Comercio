import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import '../router/app_router.dart';

class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/cart')) {
      return 3;
    }
    if (location.startsWith('/profile')) {
      return 4;
    }
    if (location.startsWith('/categories')) {
      return 1;
    }
    if (location.startsWith('/search')) {
      return 2;
    }
    return 0; // Home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.home);
        break;
      case 2:
        context.go(AppRoutes.home);
        break;
      case 3:
        context.go(AppRoutes.cart);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final cartCount = ref.watch(cartTotalItemCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Categories',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text(
                  '$cartCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.secondary,
                textColor: AppColors.primaryDark,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text(
                  '$cartCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.secondary,
                textColor: AppColors.primaryDark,
                child: const Icon(Icons.shopping_cart_rounded),
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
