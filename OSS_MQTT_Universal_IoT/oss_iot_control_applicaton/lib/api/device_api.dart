import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import '../session.dart';

class DeviceApi {
  static final DeviceApi _instance = DeviceApi._internal();
  
  factory DeviceApi() => _instance;
  
  DeviceApi._internal();

  // This will be implemented by your coworker to make actual API calls
  Future<List<Device>> getDevices() async {
    // TODO: Replace with actual API implementation
    // Example of how the API call might look:
    /*
    final sessionToken = SessionManager().sessionToken;
    if (sessionToken == null) {
      throw Exception('No session token available');
    }

    final ip = SessionManager().ip;
    final port = SessionManager().port;
    if (ip == null || port == null) {
      throw Exception('Server information not available');
    }

    final response = await http.get(
      Uri.parse('http://$ip:$port/devices'),
      headers: {
        'Authorization': 'Bearer $sessionToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Device.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load devices: ${response.statusCode}');
    }
    */

    // Temporary mock data
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Device(
        id: 'dev_001',
        name: 'Living Room Light',
        isOnline: true,
        isOn: true,
        type: 'Light',
        location: 'Living Room',
      ),
      Device(
        id: 'dev_002',
        name: 'Kitchen Light',
        isOnline: true,
        isOn: false,
        type: 'Light',
        location: 'Kitchen',
      ),
      Device(
        id: 'dev_003',
        name: 'Bedroom AC',
        isOnline: false,
        isOn: false,
        type: 'Air Conditioner',
        location: 'Bedroom',
      ),
      Device(
        id: 'dev_004',
        name: 'Smart TV',
        isOnline: true,
        isOn: true,
        type: 'Entertainment',
        location: 'Living Room',
      ),
      Device(
        id: 'dev_005',
        name: 'Security Camera',
        isOnline: true,
        isOn: true,
        type: 'Security',
        location: 'Front Door',
      ),
      Device(
        id: 'dev_006',
        name: 'Smart Speaker',
        isOnline: true,
        isOn: false,
        type: 'Audio',
        location: 'Living Room',
      ),
    ];
  }

  // Example of how to implement device control
  Future<void> toggleDevice(String deviceId, bool turnOn) async {
    // TODO: Replace with actual API implementation
    /*
    final sessionToken = SessionManager().sessionToken;
    if (sessionToken == null) {
      throw Exception('No session token available');
    }

    final ip = SessionManager().ip;
    final port = SessionManager().port;
    if (ip == null || port == null) {
      throw Exception('Server information not available');
    }

    final response = await http.post(
      Uri.parse('http://$ip:$port/devices/$deviceId/toggle'),
      headers: {
        'Authorization': 'Bearer $sessionToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'turnOn': turnOn}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle device: ${response.statusCode}');
    }
    */
    
    // Temporary mock implementation
    await Future.delayed(const Duration(milliseconds: 300));
  }
} 