class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://arabic-sentiment-back.vercel.app',
  );

  static const bool allowDelete =
      bool.fromEnvironment('ALLOW_DELETE', defaultValue: true);
}
