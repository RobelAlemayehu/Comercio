import '../../../../core/repositories/base_repository.dart';
import '../../data/models/product_model.dart';

abstract class ProductRepository {
  Future<Result<List<ProductModel>>> getProducts();
  Future<Result<ProductModel>> getProduct(int id);
  Future<Result<List<String>>> getCategories();
}
