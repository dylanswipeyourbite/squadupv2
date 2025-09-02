import 'package:flutter/foundation.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  LoginViewModel(this._authService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signIn(email: email, password: password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
