abstract class ApiEndpoints {
  static const String baseUrl = 'https://fakestoreapi.com';

  // Authentication
  static const String login = '/auth/login';

  // Products & Categories
  static const String products = '/products';
  static String productDetails(int id) => '/products/$id';
  static const String categories = '/products/categories';
  static String categoryProducts(String category) => '/products/category/$category';

  // Carts
  static const String carts = '/carts';
  static String userCart(int userId) => '/carts/user/$userId';

  // Users & Profiles
  static const String users = '/users';
  static String userProfile(int id) => '/users/$id';
}
