abstract class ApiConstants {
  static const String baseUrl = 'https://fakestoreapi.com';

  // Auth endpoints
  static const String login = '/auth/login';

  // Product endpoints
  static const String products = '/products';
  static const String categories = '/products/categories';
  static const String categoryProducts = '/products/category';

  // Cart endpoints
  static const String carts = '/carts';

  // User endpoints
  static const String users = '/users';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
