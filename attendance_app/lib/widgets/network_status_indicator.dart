import 'package:attendance_app/services/network_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class NetworkStatusIndicator extends StatelessWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Provider.of<NetworkService>(context, listen: false).isConnected(),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        
        if (!isOnline) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.wifi_off,
                  size: 16,
                  color: Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  'Offline Mode',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}