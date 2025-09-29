class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'Server error occurred'});
}

class CacheException implements Exception {
  final String message;
  CacheException({this.message = 'Cache error occurred'});
}

class AuthException implements Exception {
  final String message;
  AuthException({this.message = 'Authentication failed'});
}


// Additional exception class for network errors
class NetworkException implements Exception {
  final String message;
  NetworkException({this.message = 'Network error occurred'});
}