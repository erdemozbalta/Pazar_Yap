import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

class AuthState {
  final bool isLoggedIn;
  final String? userRole;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.userRole,
    this.userId,
    this.userName,
    this.userEmail,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userRole,
    String? userId,
    String? userName,
    String? userEmail,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userRole: userRole ?? this.userRole,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      error: error,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  AuthStateNotifier(this._ref) : super(const AuthState()) {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final token = await _storage.read(key: 'access_token');
    final role = await _storage.read(key: 'user_role');
    final userData = await _storage.read(key: 'user_data');

    if (token != null && role != null) {
      Map<String, dynamic>? user;
      if (userData != null) {
        try {
          user = jsonDecode(userData);
        } catch (_) {}
      }

      try {
        final api = _ref.read(apiClientProvider);
        final res = await api.get(ApiConstants.profile);
        if (res.data != null && res.data['user'] != null) {
          user = res.data['user'];
          await _storage.write(key: 'user_data', value: jsonEncode(user));
        }
      } catch (_) {
        await logout();
        return;
      }

      state = AuthState(
        isLoggedIn: true,
        userRole: role,
        userId: user?['id'],
        userName: '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim(),
        userEmail: user?['email'],
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final res = await api.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      await saveTokens(res.data['user'], res.data['user']['role'], res.data['accessToken'], res.data['refreshToken']);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'E-posta veya şifre hatalı');
      return false;
    }
  }

  Future<bool> employeeLogin(String email, String password) async {
    state = state.copyWith(error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final res = await api.post(ApiConstants.employeeLogin, data: {
        'email': email,
        'password': password,
      });
      await saveTokens(res.data['user'], res.data['user']['role'], res.data['accessToken'], res.data['refreshToken']);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Çalışan girişi başarısız');
      return false;
    }
  }

  Future<bool> adminLogin(String email, String password, String pin) async {
    state = state.copyWith(error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final res = await api.post(ApiConstants.adminLogin, data: {
        'email': email,
        'password': password,
        'pin': pin,
      });
      await saveTokens(res.data['user'], res.data['user']['role'], res.data['accessToken'], res.data['refreshToken']);
      return true;
    } catch (e) {
      final serverError = (e as dynamic).response?.data?['error'] as String?;
      state = state.copyWith(error: serverError ?? 'Admin girişi veya PIN hatalı');
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(error: null);
    try {
      final api = _ref.read(apiClientProvider);
      await api.post(ApiConstants.register, data: data);
      return true;
    } catch (e) {
      final serverError = (e as dynamic).response?.data?['error'] as String?;
      state = state.copyWith(error: serverError ?? 'Kayıt işlemi başarısız');
      return false;
    }
  }

  Future<void> saveTokens(Map<String, dynamic> userData, String role, String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'user_role', value: role);
    await _storage.write(key: 'user_data', value: jsonEncode(userData));

    state = AuthState(
      isLoggedIn: true,
      userRole: role,
      userId: userData['id'],
      userName: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
      userEmail: userData['email'],
    );
  }

  Future<void> logout() async {
    state = const AuthState();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  Future<void> updateUser(Map<String, dynamic> userData) async {
    await _storage.write(key: 'user_data', value: jsonEncode(userData));
    state = state.copyWith(
      userName: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
      userEmail: userData['email'],
    );
  }
}

