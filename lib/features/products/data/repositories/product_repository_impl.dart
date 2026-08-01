import '../../../../core/repositories/base_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl extends BaseRepository implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<ProductModel>>> getProducts() async {
    return safeApiCall(() => _remoteDataSource.getProducts());
  }
}
