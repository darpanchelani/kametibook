import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
  });

  final UserModel? user;
  final bool isLoading;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = AuthState(
      user: UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: 'Kameti User',
        phone: phone.trim(),
        city: 'Pakistan',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> signup({
    required String fullName,
    required String phone,
    required String password,
    required String city,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = AuthState(
      user: UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: fullName.trim(),
        phone: phone.trim(),
        city: city.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }

  void logout() {
    state = state.copyWith(clearUser: true);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
