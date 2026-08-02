import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import 'product_list_provider.dart';

/// Derives a single product from the already-cached list — no extra network
/// call needed.  Falls back to null if the list hasn't loaded yet or the id
/// is unknown.
final productDetailProvider =
    Provider.family<AsyncValue<ProductModel?>, int>((ref, id) {
  final listAsync = ref.watch(productListProvider);
  return listAsync.whenData(
    (products) => products.cast<ProductModel?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        ),
  );
});
