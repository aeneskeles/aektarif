# Supabase Kurulum Rehberi

Bu rehber, TarifUyg uygulaması için Supabase'i nasıl yapılandıracağınızı adım adım açıklar.

## 1. Supabase Hesabı Oluşturma

1. [supabase.com](https://supabase.com) adresine gidin
2. "Start your project" butonuna tıklayın
3. GitHub hesabınızla giriş yapın
4. Yeni bir proje oluşturun:
   - **Project name**: `tarifuyg` (veya istediğiniz bir isim)
   - **Database Password**: Güçlü bir şifre belirleyin (not alın!)
   - **Region**: Size en yakın bölgeyi seçin (örn: Frankfurt)
5. Projenin oluşturulmasını bekleyin (1-2 dakika)

## 2. Veritabanı Tablolarını Oluşturma

1. Supabase Dashboard'da sol menüden **SQL Editor**'a gidin
2. **New Query** butonuna tıklayın
3. `tools/supabase_schema.sql` dosyasının içeriğini kopyalayıp yapıştırın
4. **Run** butonuna tıklayın

### Schema İçeriği

```sql
-- Profiles tablosu (kullanıcı profilleri)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  display_name TEXT NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  posts_count INTEGER DEFAULT 0,
  followers_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Posts tablosu (yemek paylaşımları)
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT NOT NULL,
  recipe_id TEXT,
  ingredients TEXT[] DEFAULT '{}',
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Likes tablosu
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

-- Comments tablosu
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recipes tablosu (opsiyonel - backend tarifler için)
CREATE TABLE recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  prep_time INTEGER,
  cook_time INTEGER,
  servings INTEGER,
  difficulty TEXT CHECK (difficulty IN ('kolay', 'orta', 'zor')),
  category TEXT,
  ingredients JSONB NOT NULL DEFAULT '[]',
  steps JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 3. Row Level Security (RLS) Politikaları

SQL Editor'da aşağıdaki politikaları çalıştırın:

```sql
-- Profiles için RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Yeni kullanıcı kaydında profil oluştur
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'Kullanıcı'),
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || LEFT(NEW.id::text, 8))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Posts için RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Posts are viewable by everyone" ON posts
  FOR SELECT USING (true);

CREATE POLICY "Users can create posts" ON posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own posts" ON posts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts" ON posts
  FOR DELETE USING (auth.uid() = user_id);

-- Likes için RLS
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Likes are viewable by everyone" ON likes
  FOR SELECT USING (true);

CREATE POLICY "Users can like posts" ON likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike posts" ON likes
  FOR DELETE USING (auth.uid() = user_id);

-- Comments için RLS
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments are viewable by everyone" ON comments
  FOR SELECT USING (true);

CREATE POLICY "Users can create comments" ON comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments" ON comments
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments" ON comments
  FOR DELETE USING (auth.uid() = user_id);
```

## 4. Storage Bucket Oluşturma

1. Sol menüden **Storage**'a gidin
2. **New Bucket** butonuna tıklayın
3. Bucket adı: `post-images`
4. **Public bucket** seçeneğini işaretleyin
5. **Create bucket** butonuna tıklayın

### Storage Politikaları

Storage > post-images > Policies'e gidin ve şu politikaları ekleyin:

```sql
-- Herkes görselleri görebilir
CREATE POLICY "Public Access" ON storage.objects
  FOR SELECT USING (bucket_id = 'post-images');

-- Giriş yapmış kullanıcılar görsel yükleyebilir
CREATE POLICY "Authenticated users can upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'post-images' 
    AND auth.role() = 'authenticated'
  );

-- Kullanıcılar kendi görsellerini silebilir
CREATE POLICY "Users can delete own images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'post-images' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
```

## 5. API Anahtarlarını Alma

1. Sol menüden **Project Settings** > **API**'ye gidin
2. Şu değerleri not alın:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## 6. Flutter Uygulamasını Yapılandırma

### Seçenek A: Dart Define ile (Önerilen - Güvenli)

Uygulamayı çalıştırırken:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Seçenek B: Doğrudan Kod İçinde (Sadece Geliştirme)

`lib/core/config/supabase_config.dart` dosyasını düzenleyin:

```dart
class SupabaseConfig {
  // Geliştirme için doğrudan değer atayabilirsiniz
  static const String url = 'https://xxxxx.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
```

⚠️ **Uyarı**: Gerçek anahtarları Git'e commit etmeyin!

### Seçenek C: .env Dosyası ile

1. `flutter_dotenv` paketini ekleyin
2. `.env` dosyası oluşturun (gitignore'a ekleyin!)
3. Değerleri oradan okuyun

## 7. Test Etme

1. Uygulamayı çalıştırın
2. Kayıt olun (email/şifre)
3. Profil sayfasını kontrol edin
4. Bir paylaşım oluşturun
5. Feed'de paylaşımın görünüp görünmediğini kontrol edin

## Sorun Giderme

### "Supabase not configured" hatası
- Dart define değerlerinin doğru geçirildiğinden emin olun
- URL ve Key'in boş olmadığını kontrol edin

### "Permission denied" hatası
- RLS politikalarının doğru ayarlandığından emin olun
- Kullanıcının giriş yapmış olduğundan emin olun

### Görsel yüklenemiyor
- Storage bucket'ın public olduğundan emin olun
- Storage politikalarını kontrol edin

## Faydalı Linkler

- [Supabase Docs](https://supabase.com/docs)
- [Supabase Flutter Client](https://supabase.com/docs/reference/dart/introduction)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
