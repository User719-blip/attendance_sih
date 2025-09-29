import 'package:attendance_app/services/network_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final networkService = Provider.of<NetworkService>(context, listen: false);
    
    return StreamBuilder<bool>(
      stream: networkService.connectivityStream(),
      initialData: true, // Assume online initially
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          color: isOnline ? Colors.green.shade100 : Colors.orange.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                size: 16,
                color: isOnline ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'Online' : 'Offline Mode',
                style: TextStyle(
                  color: isOnline ? Colors.green.shade800 : Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}