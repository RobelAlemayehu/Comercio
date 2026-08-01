import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
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
}
