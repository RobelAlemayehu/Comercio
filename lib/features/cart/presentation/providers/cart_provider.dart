import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cart_item_model.dart';
import '../../../products/data/models/product_model.dart';

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super([]);

  /// Add item to cart or increment quantity if already present
  void addItem(ProductModel product, {int quantity = 1}) {
    if (quantity <= 0) return;
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final existingItem = state[index];
      final updatedList = List<CartItemModel>.from(state);
      updatedList[index] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      state = updatedList;
    } else {
      state = [
        ...state,
        CartItemModel(product: product, quantity: quantity),
      ];
    }
  }

  /// Remove item completely from cart
  void removeItem(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// Increase quantity of product by 1
  void increaseQuantity(int productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final existingItem = state[index];
      final updatedList = List<CartItemModel>.from(state);
      updatedList[index] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
      state = updatedList;
    }
  }

  /// Decrease quantity of product by 1 (removes item if quantity reaches 0)
  void decreaseQuantity(int productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final existingItem = state[index];
      if (existingItem.quantity > 1) {
        final updatedList = List<CartItemModel>.from(state);
        updatedList[index] = existingItem.copyWith(
          quantity: existingItem.quantity - 1,
        );
        state = updatedList;
      } else {
        removeItem(productId);
      }
    }
  }

  /// Clear/empty all items from cart
  void emptyCart() {
    state = [];
  }
}

// ─── Computed Providers ────────────────────────────────────────────────────────

/// Calculates the subtotal price of all items in cart
final cartSubtotalProvider = Provider<double>((ref) {
  final cartItems = ref.watch(cartNotifierProvider);
  return cartItems.fold<double>(
    0.0,
    (sum, item) => sum + item.totalPrice,
  );
});

/// Standard shipping fee ($10.00, or $0 if cart is empty or over $100)
final cartShippingProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  if (subtotal == 0.0) return 0.0;
  return subtotal >= 100.0 ? 0.0 : 10.0;
});

/// Calculates the total cost (subtotal + shipping)
final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final shipping = ref.watch(cartShippingProvider);
  return subtotal + shipping;
});

/// Calculates total count of individual items (quantities sum)
final cartTotalItemCountProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartNotifierProvider);
  return cartItems.fold<int>(
    0,
    (sum, item) => sum + item.quantity,
  );
});
