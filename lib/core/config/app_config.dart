abstract final class AppConfig {
  static const newsApiKey = String.fromEnvironment('NEWS_API_KEY');
  static const newsCountry = String.fromEnvironment(
    'NEWS_COUNTRY',
    defaultValue: 'us',
  );
  static const searchSortBy = String.fromEnvironment(
    'NEWS_SEARCH_SORT',
    defaultValue: 'publishedAt',
  );
  static const newsApiBaseUrl = 'https://newsapi.org';
  static const pageSize = 20;
}
