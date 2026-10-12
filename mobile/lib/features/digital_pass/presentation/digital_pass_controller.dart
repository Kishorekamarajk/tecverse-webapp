import 'package:flutter/foundation.dart';
import '../../../core/networking/api_exceptions.dart';
import '../../authentication/domain/authenticated_user.dart';
import '../domain/digital_event_pass.dart';
import '../domain/digital_pass_repository.dart';

class DigitalPassController extends ChangeNotifier {
  final DigitalPassRepository repository;
  DigitalEventPass? _pass;
  bool _isLoading = false;
  String? _errorMessage;
  bool _requiresSignIn = false;
  bool _canRetry = false;

  DigitalPassController({required this.repository});

  DigitalEventPass? get pass => _pass;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get requiresSignIn => _requiresSignIn;
  bool get canRetry => _canRetry;

  Future<void> loadPass({
    required String token,
    required UserProfile user,
  }) async {
    _pass = null;
    _isLoading = true;
    _errorMessage = null;
    _requiresSignIn = false;
    _canRetry = false;
    notifyListeners();

    try {
      _pass = await repository.getDigitalPass(token: token, user: user);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _requiresSignIn = e is UnauthorizedException;
      _canRetry = e is ConnectionTimeoutException ||
          e is ServerUnavailableException ||
          e is NetworkUnavailableException ||
          e is NetworkException ||
          e is ServerException;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      _errorMessage = message.startsWith('Failed to load Digital Event Pass:')
          ? message
          : 'Failed to load Digital Event Pass: $message';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPassStatus({required String token}) async {
    if (_pass == null) return;
    try {
      final updated = await repository.refreshPassStatus(
        token: token,
        passId: _pass!.passId,
      );
      _pass = updated;
      notifyListeners();
    } catch (_) {}
  }

  void clearPass() {
    _pass = null;
    _errorMessage = null;
    _requiresSignIn = false;
    _canRetry = false;
    _isLoading = false;
    notifyListeners();
  }
}
