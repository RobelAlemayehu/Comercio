
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static const String _authTokenKey    = 'auth_token';
  static const String _userProfileKey  = 'user_profile_data';
  static const String _cartDataKey     = 'cart_items_data';

  Future<bool> saveAuthToken(String token) async => await _prefs.setString(_authTokenKey, token);
  String? getAuthToken()                         => _prefs.getString(_authTokenKey);
  Future<bool> clearAuthToken() async            => await _prefs.remove(_authTokenKey);

  Future<bool> saveCartData(String cartJson) async => await _prefs.setString(_cartDataKey, cartJson);
  String? getCartData()                            => _prefs.getString(_cartDataKey);
  Future<bool> clearCartData() async               => await _prefs.remove(_cartDataKey);

  Future<bool> saveString(String key, String value) async => await _prefs.setString(key, value);
  String? getString(String key)                           => _prefs.getString(key);
  Future<bool> remove(String key) async                   => await _prefs.remove(key);
  Future<bool> clearAll() async                           => await _prefs.clear();

  static String get authTokenKey   => _authTokenKey;
  static String get userProfileKey => _userProfileKey;
  static String get cartDataKey    => _cartDataKey;
}
