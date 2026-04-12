import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../providers/supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  SupabaseClient get _supabase {
    if (_client == null) {
      throw Exception('Supabase not configured');
    }
    return _client;
  }

  User? get currentUser {
    if (_client == null) return null;
    return _client.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges {
    if (_client == null) {
      return Stream.value(AuthState(AuthChangeEvent.signedOut, null));
    }
    return _client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: username != null ? {'username': username} : null,
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    if (_client == null) return;
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<UserProfile?> getProfile(String userId) async {
    if (_client == null) return null;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return getProfile(user.id);
  }

  Future<void> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (username != null) updates['username'] = username;
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _supabase.from('profiles').update(updates).eq('id', user.id);
  }

  Future<String> uploadAvatar(String filePath, List<int> bytes) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    final extension = filePath.split('.').lastOrNull?.toLowerCase();
    final normalizedExtension = switch (extension) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
    final contentType = switch (normalizedExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final fileName =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension';

    await _supabase.storage
        .from(SupabaseConfig.avatarsBucket)
        .uploadBinary(
          fileName,
          bytes as dynamic,
          fileOptions: FileOptions(contentType: contentType),
        );

    return _supabase.storage
        .from(SupabaseConfig.avatarsBucket)
        .getPublicUrl(fileName);
  }
}

/// Current user profile provider
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  if (!SupabaseConfig.isConfigured) return null;

  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentProfile();
});
