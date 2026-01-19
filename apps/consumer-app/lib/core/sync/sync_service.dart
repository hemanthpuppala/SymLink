import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Global sync service for real-time data updates
class SyncService extends ChangeNotifier {
  static SyncService? _instance;
  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  SyncService._();

  IO.Socket? _socket;
  String? _token;
  String? _baseUrl;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Event controllers for different data types
  final _plantUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _plantCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _plantDeletedController = StreamController<String>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationController = StreamController<Map<String, dynamic>>.broadcast();
  final _refreshController = StreamController<String>.broadcast();

  // Streams for listening
  Stream<Map<String, dynamic>> get onPlantUpdated => _plantUpdatedController.stream;
  Stream<Map<String, dynamic>> get onPlantCreated => _plantCreatedController.stream;
  Stream<String> get onPlantDeleted => _plantDeletedController.stream;
  Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated => _conversationController.stream;
  Stream<String> get onRefresh => _refreshController.stream;

  void initialize(String baseUrl, String token) {
    _baseUrl = baseUrl.replaceAll('/v1', '');
    _token = token;
    _connect();
  }

  void _connect() {
    if (_baseUrl == null || _token == null) return;

    _socket?.disconnect();
    _socket?.dispose();

    final syncUrl = '$_baseUrl/sync';
    print('[SyncService] Connecting to: $syncUrl');

    _socket = IO.io(
      syncUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _socket?.onConnect((_) {
      print('[SyncService] Connected to sync server at $syncUrl');
      _isConnected = true;
      notifyListeners();
    });

    _socket?.onDisconnect((_) {
      print('[SyncService] Disconnected from sync server');
      _isConnected = false;
      notifyListeners();
    });

    _socket?.onConnectError((error) {
      print('[SyncService] Connection error: $error');
    });

    _socket?.onError((error) {
      print('[SyncService] Error: $error');
    });

    // Listen for plant events
    _socket?.on('plant:created', (data) {
      print('[SyncService] Plant created: $data');
      _plantCreatedController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('plant:updated', (data) {
      print('[SyncService] Plant updated: $data');
      _plantUpdatedController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('plant:deleted', (data) {
      print('[SyncService] Plant deleted: $data');
      _plantDeletedController.add(data['id'] as String);
    });

    _socket?.on('plant:verified', (data) {
      print('[SyncService] Plant verified: $data');
      _plantUpdatedController.add(Map<String, dynamic>.from(data));
    });

    // Listen for message events
    _socket?.on('message:new', (data) {
      print('[SyncService] New message: $data');
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('conversation:updated', (data) {
      print('[SyncService] Conversation updated: $data');
      _conversationController.add(Map<String, dynamic>.from(data));
    });

    // Listen for refresh signals
    _socket?.on('data:refresh', (data) {
      print('[SyncService] Refresh signal: $data');
      _refreshController.add(data['type'] as String);
    });
  }

  void updateToken(String token) {
    _token = token;
    _connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  void dispose() {
    disconnect();
    _plantUpdatedController.close();
    _plantCreatedController.close();
    _plantDeletedController.close();
    _messageController.close();
    _conversationController.close();
    _refreshController.close();
  }
}
