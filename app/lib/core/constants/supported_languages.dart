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
    AppLanguage(
        id: 'en',
        code: 'en-IN',
        name: 'English',
        nativeLabel: 'English',
        isSource: true),
    AppLanguage(id: 'hi', code: 'hi-IN', name: 'Hindi', nativeLabel: 'हिन्दी'),
    AppLanguage(id: 'te', code: 'te-IN', name: 'Telugu', nativeLabel: 'తెలుగు'),
  ];

  static final Map<String, AppLanguage> _map = {
    for (final l in all) l.id: l,
  };

  static AppLanguage? get(String id) => _map[id];

  static String getNativeLabel(String id) => _map[id]?.nativeLabel ?? id;

  static String getName(String id) => _map[id]?.name ?? id;
}
