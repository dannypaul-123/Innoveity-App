class ApiConfig {
  const ApiConfig._();
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://crm.innoveity.tech/api',
  );
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);
}
