import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/config/api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiConfig Tests', () {
    test('Default base URL ends with /api', () async {
      await ApiConfig.init();
      expect(ApiConfig.baseUrl, contains('/api'));
    });

    test('Custom base URL overrides default endpoint structure', () async {
      const customUrl = 'http://192.168.1.100:5000/api';
      await ApiConfig.setCustomBaseUrl(customUrl);

      expect(ApiConfig.baseUrl, customUrl);
      expect(ApiConfig.loginUrl, '$customUrl/users/login');
      expect(ApiConfig.registerUrl, '$customUrl/users/register');
      expect(ApiConfig.forgotPasswordUrl, '$customUrl/users/forgot-password');
      expect(ApiConfig.itemsUrl, '$customUrl/items');
    });
  });
}
