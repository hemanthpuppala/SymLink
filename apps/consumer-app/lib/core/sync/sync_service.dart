import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// REAL-TIME SYNC SERVICE - WebSocket-based updates
///
/// IMPORTANT: Auto-refresh should ALWAYS use WebSocket (push-based), NOT polling.
///
/// WHY WebSocket over Polling:
/// - Instant: Updates appear immediately when events occur on the server
/// - Efficient: No wasted requests when nothing has changed
/// - Scalable: Server controls when to push, clients don't hammer the API
/// - Battery-friendly: Mobile devices don't drain battery with constant polling
///
/// HOW TO USE:
/// 1. Initialize the service with baseUrl and token on app startup
/// 2. Listen to the appropriate stream (onNewMessage, onMessagesRead, etc.)
/// 3. In the listener, update your local state or invalidate cache
///
/// NEVER use Timer.periodic or similar polling mechanisms for real-time updates.
/// ALWAYS use this WebSocket service for auto-refresh functionality.
///
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
  final _messagesReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeliveredController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationController = StreamController<Map<String, dynamic>>.broadcast();
  final _refreshController = StreamController<String>.broadcast();

  // Streams for listening
  Stream<Map<String, dynamic>> get onPlantUpdated => _plantUpdatedController.stream;
  Stream<Map<String, dynamic>> get onPlantCreated => _plantCreatedController.stream;
  Stream<String> get onPlantDeleted => _plantDeletedController.stream;
  Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadController.stream;
  Stream<Map<String, dynamic>> get onMessageDelivered => _messageDeliveredController.stream;
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

    _socket?.on('messages:read', (data) {
      print('[SyncService] Messages read: $data');
      _messagesReadController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('message:delivered', (data) {
      print('[SyncService] Message delivered: $data');
      _messageDeliveredController.add(Map<String, dynamic>.from(data));
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
    _messagesReadController.close();
    _messageDeliveredController.close();
    _conversationController.close();
    _refreshController.close();
  }
}
