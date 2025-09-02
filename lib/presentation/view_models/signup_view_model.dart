import 'package:flutter/foundation.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';

class SignupViewModel extends ChangeNotifier {
  final AuthService _authService;

  SignupViewModel(this._authService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> signup(String displayName, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signUp(
        displayName: displayName,
        email: email,
        password: password,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
