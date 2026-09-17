class BreakpointLinks {
  static const host = 'cie-daily-studio.vercel.app';
  static const baseUrl = 'https://$host';

  static String article(String id) => '$baseUrl/article/$id';
  static String list(String id) => '$baseUrl/list/$id';
  static String connect(String code) => '$baseUrl/connect/$code';
  static String profile(String uid) => '$baseUrl/profile/$uid';
}
