import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../data/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  final AuthRepository _repository;

  String _translateError(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('invalid') && lowerMessage.contains('email')) {
      return 'Geçersiz e-posta adresi';
    }
    if (lowerMessage.contains('user already registered') || 
        lowerMessage.contains('already exists')) {
      return 'Bu e-posta adresi zaten kayıtlı';
    }
    if (lowerMessage.contains('invalid login credentials') ||
        lowerMessage.contains('invalid credentials')) {
      return 'E-posta veya şifre hatalı';
    }
    if (lowerMessage.contains('email not confirmed')) {
      return 'E-posta adresinizi doğrulayın';
    }
    if (lowerMessage.contains('password')) {
      if (lowerMessage.contains('weak') || lowerMessage.contains('short')) {
        return 'Şifre çok zayıf, en az 6 karakter olmalı';
      }
      return 'Şifre hatalı';
    }
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return 'Bağlantı hatası, internet bağlantınızı kontrol edin';
    }
    if (lowerMessage.contains('too many requests') || lowerMessage.contains('rate limit')) {
      return 'Çok fazla deneme, lütfen bekleyin';
    }
    
    return message;
  }

  void _init() {
    // Supabase yapılandırılmamışsa demo modda çalış
    if (!SupabaseConfig.isConfigured) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = _repository.currentUser;
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }

      _repository.authStateChanges.listen((event) {
        if (event.session?.user != null) {
          state = AuthState(
            status: AuthStatus.authenticated,
            user: event.session!.user,
          );
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      });
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Supabase yapılandırılmamış',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await _repository.signUp(
        email: email,
        password: password,
        username: username,
      );

      if (response.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Kayıt başarısız oldu',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _translateError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _translateError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Supabase yapılandırılmamış',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await _repository.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Giriş başarısız oldu',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _translateError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _translateError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    if (!SupabaseConfig.isConfigured) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Supabase yapılandırılmamış',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await _repository.signInWithGoogle();

      if (response.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Google ile giriş başarısız oldu',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _translateError(e.toString()),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      await _repository.signOut();
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> resetPassword(String email) async {
    if (!SupabaseConfig.isConfigured) return false;
    
    try {
      await _repository.resetPassword(email);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
