import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin wrapper around the room-lifecycle REST endpoints. Realtime gameplay
/// itself goes over the socket connection (see [SocketGameDataSource]) — REST
/// is only used for the parts that are naturally request/response: creating
/// a room and checking whether one exists before joining.
class RoomApi {
  final String baseUrl;
  final http.Client _client;

  RoomApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  Future<String> createRoom({required String hostId, required String hostName}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/rooms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'hostId': hostId, 'hostName': hostName}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create room: ${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['roomId'] as String;
  }

  Future<bool> roomExists(String roomId) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/rooms/$roomId'));
    return response.statusCode == 200;
  }
}
