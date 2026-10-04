# 🎵 مازيكتي (Mazikty) - Modern Arabic Music Streaming Player

تطبيق بث وتشغيل موسيقى عربي متكامل وعصري مبني بأحدث تقنيات **Flutter** و **Dart** و **Riverpod**.
يتميز التطبيق بتصميم داكن فاخر (Dark Luxury Music Player) مع دعم كامل للغة العربية واتجاه اليمين لليسار (RTL)، وهندسة برمجية نظيفة وقابلة للتوسع (Clean Architecture) لربط أي واجهة برمجية (API) لاحقاً بسهولة تامة.

---

## 🌟 المميزات الرئيسية (Core Features)

1. **الصفحة الرئيسية (Home Screen):**
   - شعار وهوية التطبيق: «مازيكتي».
   - شريط بحث سريع في أعلى الشاشة.
   - بانر أبرز مختارات اليوم (Hero Banner) مع تشغيل فوري.
   - قسم أكمل الاستماع (Continue Listening).
   - الأغاني الأكثر استماعاً (Popular Songs).
   - التصنيفات والمقامات الموسيقية (Genres & Maqams).
   - أبرز الفنانين والمبدعين (Featured Artists).
   - أحدث الإصدارات (New Releases).
   - قوائم التشغيل المميزة (Curated Playlists).
   - الأغاني الأخيرة (Recently Played).

2. **محرك البحث الذكي (Search):**
   - بحث فوري يدعم اللغتين العربية والإنجليزية.
   - البحث عن: اسم الأغنية، اسم الفنان، اسم الألبوم، أو المقام الموسيقي.
   - فلاتر تصنيف: (الكل، أغاني، فنانين، ألبومات).
   - عرض غلاف الألبوم، اسم العمل، الفنان، زر التشغيل، الإضافة للمفضلة، وقائمة الخيارات السريعة.

3. **مشغل الموسيقى الاحترافي (Full-Screen Music Player):**
   - تصميم زجاجي عصري مع إضاءة خافتة متدرجة تماشي غلاف الألبوم.
   - تحكم كامل بالصوت: تشغيل / إيقاف مؤقت، الأغنية السابقة، الأغنية التالية.
   - شريط تقدم زمني تفاعلي مع إمكانية التقديم والتأخير (Seeking).
   - وضع الخلط (Shuffle) ووضع التكرار (Repeat One / Repeat All / Repeat Off).
   - زر الإضافة للمفضلة بنقرة واحدة مع اهتزاز تفاعلي.
   - قائمة الانتظار المباشرة (Queue Management) عبر نافذة سفلية قابلة للتحكم.
   - زر التحميل للمشاهدة بدون إنترنت.

4. **المشغل المصغر (Mini Player):**
   - يظهر فوق شريط التنقل السفلي تلقائياً عند تشغيل أي عمل.
   - يعرض الغلاف، عنوان الأغنية، الفنان، شريط تقدم مصغر دقيق، أزرار التشغيل/الإيقاف المؤقت، وزر الإغلاق.
   - التمرير أو النقر يفتح مشغل الموسيقى الكامل بسلاسة فائقة.

5. **المفضلة (Favorites):**
   - إضافة وإزالة الأغاني فورياً.
   - حفظ محلي مستمر عبر `SharedPreferences`.
   - شاشة خاصة بالمفضلة مع إمكانية "تشغيل الكل" بنقرة واحدة.

6. **التحميل والموسيقى دون اتصال (Offline Music & Downloads):**
   - تنزيل الملفات المصرح بها قانونياً فقط إلى مساحة التخزين الآمنة للجهاز.
   - متابعة تقدم التحميل (Download Progress) في الوقت الفعلي.
   - شاشة خاصة بالمحملات تتيح التشغيل دون إنترنت أو حذف الملفات لتوفير المساحة.

7. **إدارة قوائم التشغيل (Playlists Management):**
   - إنشاء قوائم تشغيل مخصصة جديدة.
   - إعادة تسمية القوائم وحذفها.
   - إضافة وحذف الأغاني من وإلى أي قائمة تشغيل.
   - تشغيل القائمة بالكامل أو خلط أغانيها.

8. **التشغيل في الخلفية والتحكم من شاشة القفل (Background Playback):**
   - استخدام `just_audio` و `just_audio_background`.
   - استمرار الصوت عند تصغير التطبيق أو قفل الشاشة.
   - إشعارات تحكم مدمجة بنظامي Android و iOS مع أزرار التحكم والتقديم وصورة الألبوم.

9. **تجربة خالية من الإعلانات تماماً (Ad-Free):**
   - لا توجد إعلانات AdMob أو نوافذ منبثقة أو بنرات تجارية.

10. **الأشرطة والتنقل (4 Main Tabs):**
    - الرئيسية
    - البحث
    - المفضلة
    - المكتبة

---

## 🏛️ البنية المعمارية وهيكل المشروع (Architecture)

تم بناء المشروع باتباع أفضل معايير **Feature-First Clean Architecture**:

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # لوحة الألوان والدرجات الداكنة
│   │   ├── app_typography.dart     # خطوط Google Fonts (Cairo)
│   │   └── app_theme.dart          # تهيئة ThemeData للمظهر الداكن الكامل
│   └── utils/
│       ├── formatters.dart         # تنسيق الوقت والمدد والأرقام
│       └── app_exceptions.dart     # معالجة الأخطاء برسائل عربية ودية
├── data/
│   ├── mock/
│   │   └── sample_music_data.dart  # كتالوج تجريبي غني بالألحان العربية القانونية
│   ├── repositories/
│   │   ├── favorites_repository_impl.dart  # حفظ المفضلة محلياً
│   │   ├── music_repository_impl.dart      # الربط بين الـ API والبيانات
│   │   └── playlist_repository_impl.dart   # حفظ وإدارة قوائم التشغيل
│   └── services/
│       ├── audio_player_service.dart       # مشغل just_audio والإشعارات
│       ├── download_service.dart           # تنزيل الأغاني وحفظها أوفلاين
│       └── music_api_service.dart          # واجهة خدمة الموسيقى
├── domain/
│   ├── models/
│   │   ├── album.dart
│   │   ├── artist.dart
│   │   ├── genre.dart
│   │   ├── playlist.dart
│   │   └── song.dart
│   └── repositories/
│       ├── favorites_repository.dart
│       ├── music_repository.dart
│       └── playlist_repository.dart
├── presentation/
│   ├── providers/                          # Riverpod Providers
│   │   ├── audio_player_provider.dart
│   │   ├── downloads_provider.dart
│   │   ├── favorites_provider.dart
│   │   ├── music_providers.dart
│   │   ├── playlists_provider.dart
│   │   ├── search_provider.dart
│   │   └── service_providers.dart
│   ├── screens/
│   │   ├── artist/
│   │   ├── downloads/
│   │   ├── favorites/
│   │   ├── home/
│   │   ├── library/
│   │   ├── player/
│   │   ├── playlists/
│   │   ├── search/
│   │   └── main_scaffold_screen.dart
│   └── widgets/                            # مكونات UI قابلة لإعادة الاستخدام
│       ├── artist_avatar.dart
│       ├── custom_shimmer.dart
│       ├── empty_state_view.dart
│       ├── error_view.dart
│       ├── mini_player.dart
│       ├── playlist_card.dart
│       ├── section_header.dart
│       ├── song_card.dart
│       └── song_tile.dart
└── main.dart                               # نقطة الانطلاق الرئيسية
```

---

## 🔌 كيفية ربط واجهة برمجية مخصصة (Custom API Integration)

تم عزل مزود الموسيقى بالكامل في طبقة `MusicApiService`. لربط خادمك الخاص، كل ما عليك فعله هو:

1. إنشاء صنف يطبق واجهة `MusicApiService`:
```dart
class RealMusicApiService implements MusicApiService {
  final http.Client client;
  RealMusicApiService({required this.client});

  @override
  Future<List<Song>> fetchRecentlyPlayed() async {
    final response = await client.get(Uri.parse('https://your-api.com/v1/songs/recent'));
    // تحويل JSON إلى نماذج Song
    ...
  }
  // تنفيذ باقي الدوال...
}
```

2. استبدال المزود في `lib/presentation/providers/service_providers.dart`:
```dart
final musicApiServiceProvider = Provider<MusicApiService>((ref) {
  return RealMusicApiService(client: http.Client());
});
```

دون أي تعديل على واجهات المستخدم (UI) أو إدارة الحالة (Riverpod)!

---

## 🚀 التشغيل والتثبيت (Running the Project)

```bash
# تثبيت الحزم والمكتبات
flutter pub get

# فحص كود المشروع
flutter analyze

# تشغيل الاختبارات
flutter test

# تشغيل التطبيق على الهاتف أو المحاكي
flutter run
```

---

## 🔒 الالتزام القانوني بحقوق الملكية الفكرية (Legal Compliance)
- التطبيق لا يقوم بسحب أو قرصنة أي محتوى محمي بحقوق الملكية من YouTube أو Spotify أو Apple Music أو SoundCloud.
- جميع الروابط التجريبية المستخدمة هي مقطوعات مرخصة قانونياً ومتاحة للنطاق العام (Public Domain / Creative Commons) وتعمل عبر بروتوكول HTTPS الآمن.
- وظيفة التحميل تعمل حصراً على المقاطع المأذون بتحميلها رسمياً من المصدر (`isDownloadable == true`).
