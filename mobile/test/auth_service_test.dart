import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/models/user_model.dart';
import 'package:mobile/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Tests', () {
    test('isLoggedIn returns false when no token saved', () async {
      final isLoggedIn = await AuthService.isLoggedIn();
      expect(isLoggedIn, false);
    });

    test('saveSession persists user and token', () async {
      final user = UserModel(
        id: 'u123',
        name: 'Test Customer',
        email: 'customer@vexa.com',
        role: 'user',
      );

      await AuthService.saveSession(user, 'jwt_secret_token_123');

      final token = await AuthService.getToken();
      final savedUser = await AuthService.getUser();

      expect(token, 'jwt_secret_token_123');
      expect(savedUser, isNotNull);
      expect(savedUser?.name, 'Test Customer');
      expect(savedUser?.email, 'customer@vexa.com');
    });

    test('clearSession removes user token and metadata', () async {
      final user = UserModel(
        id: 'u123',
        name: 'Test Customer',
        email: 'customer@vexa.com',
        role: 'user',
      );

      await AuthService.saveSession(user, 'token_xyz');
      await AuthService.clearSession();

      final token = await AuthService.getToken();
      final savedUser = await AuthService.getUser();

      expect(token, isNull);
      expect(savedUser, isNull);
    });
  });
}
