import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_settings_provider.dart';

class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  bool get isEnglish => languageCode == 'en';

  String get settings => isEnglish ? 'Settings' : 'Ayarlar';
  String get account => isEnglish ? 'ACCOUNT' : 'HESAP';
  String get appearance => isEnglish ? 'APPEARANCE' : 'GÖRÜNÜM';
  String get language => isEnglish ? 'LANGUAGE' : 'DİL';
  String get appSection => isEnglish ? 'APP' : 'UYGULAMA';
  String get editProfile => isEnglish ? 'Edit Profile' : 'Profili Düzenle';
  String get goPremium => isEnglish ? 'Go Premium' : 'Premiuma Geç';
  String get theme => isEnglish ? 'Theme' : 'Tema';
  String get lightTheme => isEnglish ? 'Light' : 'Açık';
  String get blueTheme => isEnglish ? 'Blue' : 'Mavi';
  String get darkTheme => isEnglish ? 'Dark' : 'Koyu';
  String get turkish => 'Türkçe';
  String get english => 'English';
  String get aboutApp => isEnglish ? 'About App' : 'Uygulama Hakkında';
  String get aboutAppDescription => isEnglish
      ? 'LezzetPot helps you discover recipes, save favorites, create your own menus, and share your dishes with the community.\n\nDeveloped with Flutter.'
      : 'LezzetPot; tarif keşfetmenize, favorilerinizi kaydetmenize, kendi menülerinizi oluşturmanıza ve yemeklerinizi toplulukla paylaşmanıza yardımcı olur.\n\nFlutter ile geliştirilmiştir.';
  String get appVersionLabel => 'LezzetPot v1.0.0';
  String get close => isEnglish ? 'Close' : 'Kapat';
  String get logout => isEnglish ? 'Log Out' : 'Çıkış Yap';
  String get cancel => isEnglish ? 'Cancel' : 'İptal';
  String get logoutConfirmTitle => isEnglish ? 'Log Out' : 'Çıkış Yap';
  String get logoutConfirmMessage => isEnglish
      ? 'Are you sure you want to log out?'
      : 'Hesabınızdan çıkış yapmak istediğinize emin misiniz?';
  String get user => isEnglish ? 'User' : 'Kullanıcı';
  String get newBadge => isEnglish ? 'New' : 'Yeni';

  String get recipeBook => isEnglish ? 'My Recipe Book' : 'Tarif Kitabım';
  String get recipeBookSubtitle => isEnglish
      ? 'Create and save your own menus'
      : 'Kendi menülerini oluştur ve kaydet';
  String get myRecipes =>
      isEnglish ? 'My Recipes' : 'Benim Tariflerim';
  String get savedMenus =>
      isEnglish ? 'Saved Menus' : 'Kaydettiklerim';
  String get noMenusYet => isEnglish
      ? 'You have not created a menu yet'
      : 'Henüz menü oluşturmadın';
  String get noSavedMenus => isEnglish
      ? 'You have not saved any menus yet'
      : 'Henüz kaydettiğin menü yok';
  String get createNew => isEnglish ? 'Create New' : 'Yeni Oluştur';
  String get createMenu => isEnglish ? 'Create New Menu' : 'Yeni Menü Oluştur';
  String get menuName => isEnglish ? 'Menu name' : 'Menü adı';
  String get selectIcon => isEnglish ? 'Select Icon' : 'İkon Seç';
  String get searchRecipes =>
      isEnglish ? 'Search recipes' : 'Tarif ara';
  String get recipes => isEnglish ? 'Recipes' : 'Tarifler';
  String get create => isEnglish ? 'Create' : 'Oluştur';
  String get savedBy => isEnglish ? 'Saved by' : 'Kaydeden';
  String dishesCount(int count) =>
      isEnglish ? '$count dishes' : '$count yemek';
  String minutesCount(int minutes) =>
      isEnglish ? '$minutes min' : '$minutes dakika';
  String get recipesLoadError =>
      isEnglish ? 'Could not load recipes' : 'Tarifler yüklenemedi';
  String mealNumber(int index) =>
      isEnglish ? 'Dish $index' : 'Yemek $index';
  String servingsCount(int count) =>
      isEnglish ? '$count people' : '$count kişi';

  String get posts => isEnglish ? 'Posts' : 'Paylaşımlar';
  String get postsSubtitle => isEnglish
      ? 'Delicious shares from the community'
      : 'Topluluktan lezzetli paylaşımlar';
  String get share => isEnglish ? 'Share' : 'Paylaş';
  String get rate => isEnglish ? 'Rate' : 'Puan';
  String get triedIt => isEnglish ? 'Tried it' : 'Denedim';
  String get triedItDone => isEnglish ? 'Tried it ✓' : 'Denedim ✓';
  String get noPostsYet =>
      isEnglish ? 'No posts yet' : 'Henüz paylaşım yok';
  String get beFirstToPost => isEnglish
      ? 'Be the first to share with the community!'
      : 'İlk paylaşımı sen yaparak topluluğu başlat!';
  String get createPost => isEnglish ? 'Create Post' : 'Paylaşım Yap';
  String get offlineMode => isEnglish ? 'Offline Mode' : 'Çevrimdışı Mod';
  String get offlinePostsMessage => isEnglish
      ? 'Internet connection required to view posts'
      : 'Paylaşımları görmek için internet bağlantısı gerekli';
  String get loadError =>
      isEnglish ? 'Error while loading' : 'Yüklenirken hata oluştu';
  String get retry => isEnglish ? 'Retry' : 'Tekrar Dene';
  String get anonymousUser =>
      isEnglish ? 'Anonymous Chef' : 'Anonim Şef';

  String get home => isEnglish ? 'Home' : 'Ana Sayfa';
  String get menus => isEnglish ? 'Menus' : 'Menüler';
  String get profile => isEnglish ? 'Profile' : 'Profil';

  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return isEnglish ? 'Now' : 'Şimdi';
    }
    if (diff.inMinutes < 60) {
      return isEnglish
          ? '${diff.inMinutes} min ago'
          : '${diff.inMinutes} dakika önce';
    }
    if (diff.inHours < 24) {
      return isEnglish
          ? '${diff.inHours} hours ago'
          : '${diff.inHours} saat önce';
    }
    if (diff.inDays < 7) {
      return isEnglish
          ? '${diff.inDays} days ago'
          : '${diff.inDays} gün önce';
    }
    return '${dateTime.day}/${dateTime.month}';
  }
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return AppStrings(settings.languageCode);
});
