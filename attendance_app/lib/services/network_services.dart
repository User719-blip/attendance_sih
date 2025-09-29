import '../core/networks/network_connection.dart';

class NetworkService {
  final NetworkInfo _networkInfo;
  
  NetworkService(this._networkInfo);
  
  /// Check if device is connected to network
  Future<bool> isConnected() async {
    return await _networkInfo.isConnected;
  }
  
  /// Get stream of network connectivity changes
  Stream<bool> connectivityStream() {
    return _networkInfo.connectionChanges;
  }
}