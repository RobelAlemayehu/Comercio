import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../data/models/product_model.dart';

class ProductRepository extends BaseRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  Future<Result<List<ProductModel>>> getProducts() async {
    return safeApiCall(() async {
      final response = await _apiClient.get(ApiEndpoints.products);
      if (response is List) {
        return response
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Invalid products list format received from server');
    });
  }

  Future<Result<ProductModel>> getProduct(int id) async {
    return safeApiCall(() async {
      final response = await _apiClient.get(ApiEndpoints.productDetails(id));
      if (response is Map<String, dynamic>) {
        return ProductModel.fromJson(response);
      }
      throw Exception('Invalid product format received from server');
    });
  }

  Future<Result<List<String>>> getCategories() async {
    return safeApiCall(() async {
      final response = await _apiClient.get(ApiEndpoints.categories);
      if (response is List) {
        return response.map((item) => item.toString()).toList();
      }
      throw Exception('Invalid categories list format received from server');
    });
  }
}
