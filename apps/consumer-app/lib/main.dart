import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/api/api_client.dart';
import 'core/storage/secure_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlowGridConsumerApp());
}

class FlowGridConsumerApp extends StatefulWidget {
  const FlowGridConsumerApp({super.key});

  @override
  State<FlowGridConsumerApp> createState() => _FlowGridConsumerAppState();
}

class _FlowGridConsumerAppState extends State<FlowGridConsumerApp> {
  late final SecureStorage _secureStorage;
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _secureStorage = SecureStorage();
    _apiClient = ApiClient(storage: _secureStorage);
    // Set storage for router auth checks
    AppRouter.setStorage(_secureStorage);
    // Auto-redirect to login on auth failure
    _apiClient.onAuthFailure = () {
      AppRouter.router.go('/login');
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SecureStorage>.value(value: _secureStorage),
        RepositoryProvider<ApiClient>.value(value: _apiClient),
      ],
      child: MaterialApp.router(
        title: 'FlowGrid',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
