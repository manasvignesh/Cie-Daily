class AppLanguage {
  final String id;
  final String code;
  final String name;
  final String nativeLabel;
  final bool isSource;

  const AppLanguage({
    required this.id,
    required this.code,
    required this.name,
    required this.nativeLabel,
    this.isSource = false,
  });
}

class SupportedLanguages {
  static const List<AppLanguage> all = [
    AppLanguage(id: 'en', code: 'en-IN', name: 'English', nativeLabel: 'English', isSource: true),
    AppLanguage(id: 'hi', code: 'hi-IN', name: 'Hindi', nativeLabel: 'हिन्दी'),
    AppLanguage(id: 'te', code: 'te-IN', name: 'Telugu', nativeLabel: 'తెలుగు'),
    AppLanguage(id: 'ta', code: 'ta-IN', name: 'Tamil', nativeLabel: 'தமிழ்'),
    AppLanguage(id: 'kn', code: 'kn-IN', name: 'Kannada', nativeLabel: 'ಕನ್ನಡ'),
    AppLanguage(id: 'ml', code: 'ml-IN', name: 'Malayalam', nativeLabel: 'മലയാളം'),
    AppLanguage(id: 'bn', code: 'bn-IN', name: 'Bengali', nativeLabel: 'বাংলা'),
    AppLanguage(id: 'mr', code: 'mr-IN', name: 'Marathi', nativeLabel: 'मराठी'),
    AppLanguage(id: 'gu', code: 'gu-IN', name: 'Gujarati', nativeLabel: 'ગુજરાતી'),
    AppLanguage(id: 'pa', code: 'pa-IN', name: 'Punjabi', nativeLabel: 'ਪੰਜਾਬੀ'),
    AppLanguage(id: 'od', code: 'od-IN', name: 'Odia', nativeLabel: 'ଓଡ଼ିଆ'),
  ];

  static final Map<String, AppLanguage> _map = {
    for (final l in all) l.id: l,
  };

  static AppLanguage? get(String id) => _map[id];

  static String getNativeLabel(String id) => _map[id]?.nativeLabel ?? id;

  static String getName(String id) => _map[id]?.name ?? id;
}
