class SupabaseConfig {
  SupabaseConfig._();

  // Development credentials - hardcoded for easy development
  // In production, use --dart-define or secure storage
  static const String _devUrl = 'https://fmseurmcrvexpxyypvuh.supabase.co';
  static const String _devAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZtc2V1cm1jcnZleHB4eXlwdnVoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1MzkxMDUsImV4cCI6MjA4ODExNTEwNX0.5EIlXkI3nXa3DSHKqEU6ir3Qh2MA-ld47W2keOX0gOg';

  // Check for environment variable first, then use dev values
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => _envUrl.isNotEmpty ? _envUrl : _devUrl;
  static String get anonKey => _envAnonKey.isNotEmpty ? _envAnonKey : _devAnonKey;

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  // Storage bucket names (must match Supabase bucket names exactly)
  static const postImagesBucket = 'post-images';
  static const avatarsBucket = 'avatars';

  // API endpoints for ML inference
  static const inferenceApiUrl = String.fromEnvironment(
    'INFERENCE_API_URL',
    defaultValue: 'http://localhost:8000',
  );
}
