
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'products.dart';
import 'storage.dart';
import 'theme.dart';
import 'widgets.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;

  const CartItemModel({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  CartItemModel copyWith({ProductModel? product, int? quantity}) {
    return CartItemModel(product: product ?? this.product, quantity: quantity ?? this.quantity);
  }

  Map<String, dynamic> toJson() => {'product': product.toJson(), 'quantity': quantity};

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

final cartNotifierProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  return CartNotifier(storageService);
});

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  final LocalStorageService _storageService;

  CartNotifier(this._storageService) : super([]) { _loadCart(); }

  void _loadCart() {
    try {
      final cartJson = _storageService.getCartData();
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cartJson);
        state = list.map((item) => CartItemModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) { state = []; }
  }

  Future<void> _saveCart() async {
    try {
      final jsonList = state.map((item) => item.toJson()).toList();
      await _storageService.saveCartData(jsonEncode(jsonList));
    } catch (_) {}
  }

  void addItem(ProductModel product, {int quantity = 1}) {
    if (quantity <= 0) return;
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final updatedList = List<CartItemModel>.from(state);
      updatedList[index] = state[index].copyWith(quantity: state[index].quantity + quantity);
      state = updatedList;
    } else {
      state = [...state, CartItemModel(product: product, quantity: quantity)];
    }
    _saveCart();
  }

  void removeItem(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
    _saveCart();
  }

  void increaseQuantity(int productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final updatedList = List<CartItemModel>.from(state);
      updatedList[index] = state[index].copyWith(quantity: state[index].quantity + 1);
      state = updatedList;
      _saveCart();
    }
  }

  void decreaseQuantity(int productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (state[index].quantity > 1) {
        final updatedList = List<CartItemModel>.from(state);
        updatedList[index] = state[index].copyWith(quantity: state[index].quantity - 1);
        state = updatedList;
        _saveCart();
      } else {
        removeItem(productId);
      }
    }
  }

  void emptyCart() {
    state = [];
    _storageService.clearCartData();
  }
}

final cartSubtotalProvider = Provider<double>((ref) {
  final cartItems = ref.watch(cartNotifierProvider);
  return cartItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
});

final cartShippingProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  if (subtotal == 0.0) return 0.0;
  return subtotal >= 100.0 ? 0.0 : 10.0;
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartSubtotalProvider) + ref.watch(cartShippingProvider);
});

final cartTotalItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider).fold<int>(0, (sum, item) => sum + item.quantity);
});

class CartItemCard extends ConsumerWidget {
  final CartItemModel cartItem;
  const CartItemCard({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = cartItem.product;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 75, height: 75,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : AppColors.backgroundLight,
              borderRadius: AppRadius.borderMd,
            ),
            child: CachedNetworkImage(
              imageUrl: product.image,
              fit: BoxFit.contain,
              placeholder: (context, url) => const ShimmerBox(width: double.infinity, height: double.infinity),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, size: 24, color: AppColors.textSecondaryLight),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove item',
                      onPressed: () => ref.read(cartNotifierProvider.notifier).removeItem(product.id),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.secondaryLight : AppColors.primary)),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QtyIconButton(icon: Icons.remove_rounded,
                              onTap: () => ref.read(cartNotifierProvider.notifier).decreaseQuantity(product.id), isDark: isDark),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('${cartItem.quantity}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                          ),
                          _QtyIconButton(icon: Icons.add_rounded,
                              onTap: () => ref.read(cartNotifierProvider.notifier).increaseQuantity(product.id), isDark: isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _QtyIconButton({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderSm,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 16, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      ),
    );
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  void _showEmptyCartConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Empty Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              ref.read(cartNotifierProvider.notifier).emptyCart();
              Navigator.pop(dialogContext);
            },
            child: const Text('Empty Cart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartNotifierProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final shipping = ref.watch(cartShippingProvider);
    final total = ref.watch(cartTotalProvider);
    final totalItemCount = ref.watch(cartTotalItemCountProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: 'Empty Cart',
              onPressed: () => _showEmptyCartConfirmation(context, ref),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyStateWidget(
                  title: 'Your Cart is Empty',
                  message: 'Explore our catalog and add your favorite items.',
                  icon: Icons.shopping_cart_outlined,
                  action: AppButton(
                    text: 'Start Shopping',
                    variant: AppButtonVariant.primary,
                    width: 180,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: (index * 50).clamp(0, 300)),
                        child: CartItemCard(key: ValueKey(item.product.id), cartItem: item),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal ($totalItemCount ${totalItemCount == 1 ? "item" : "items"})',
                                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            Text('\$${subtotal.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shipping', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            Text(shipping == 0.0 ? 'FREE' : '\$${shipping.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                    color: shipping == 0.0 ? AppColors.success : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                            Text('\$${total.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.secondaryLight : AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.primaryDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              ref.read(cartNotifierProvider.notifier).emptyCart();
                              AppSnackbar.success(context, 'Order placed successfully! 🎉');
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('Proceed to Checkout'),
                                SizedBox(width: AppSpacing.xs),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
