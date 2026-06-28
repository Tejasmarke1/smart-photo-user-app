import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? accessToken;
  final String? refreshToken;
  final String? userName;
  final String? userEmail;

  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.accessToken,
    this.refreshToken,
    this.userName,
    this.userEmail,
  });

  factory AuthState.initial() => AuthState(isAuthenticated: false, isLoading: true);
  factory AuthState.unauthenticated() => AuthState(isAuthenticated: false, isLoading: false);
  factory AuthState.authenticated({
    required String accessToken,
    required String refreshToken,
    String? userName,
    String? userEmail,
  }) => AuthState(
    isAuthenticated: true,
    isLoading: false,
    accessToken: accessToken,
    refreshToken: refreshToken,
    userName: userName,
    userEmail: userEmail,
  );

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? accessToken,
    String? refreshToken,
    String? userName,
    String? userEmail,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  AuthNotifier() : super(AuthState.initial()) {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    try {
      final access = await _storage.read(key: 'access_token');
      final refresh = await _storage.read(key: 'refresh_token');
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      final email = prefs.getString('user_email');

      if (access != null && refresh != null) {
        state = AuthState.authenticated(
          accessToken: access,
          refreshToken: refresh,
          userName: name,
          userEmail: email,
        );
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String accessToken, String refreshToken, {String? name, String? email}) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString('user_name', name);
    if (email != null) await prefs.setString('user_email', email);

    state = AuthState.authenticated(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userName: name,
      userEmail: email,
    );
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString('user_name', name);
    if (email != null) await prefs.setString('user_email', email);

    state = state.copyWith(
      userName: name ?? state.userName,
      userEmail: email ?? state.userEmail,
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
