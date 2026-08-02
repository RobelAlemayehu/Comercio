import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<String>> getCategories();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await _apiClient.get(ApiEndpoints.products);
    if (response is List) {
      return response
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Invalid products list format received from server');
  }

  @override
  Future<List<String>> getCategories() async {
    final response = await _apiClient.get(ApiEndpoints.categories);
    if (response is List) {
      return response.map((item) => item.toString()).toList();
    }
    throw Exception('Invalid categories list format received from server');
  }
}

