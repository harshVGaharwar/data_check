import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/app.dart';
import 'package:vizualizer/data/services/api_service.dart';
import 'package:vizualizer/data/services/auth_service.dart';
import 'package:vizualizer/data/services/storage_service.dart';
import 'package:vizualizer/data/services/template_service.dart';
import 'package:vizualizer/data/services/pipeline_service.dart';
import 'package:vizualizer/data/services/master_data_service.dart';
import 'package:vizualizer/presentation/providers/auth_provider.dart';
import 'package:vizualizer/presentation/providers/template_provider.dart';

/// Global key used by ApiService to show snackbars without a BuildContext.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final storageService = StorageService();
  final authService = AuthService(apiService);

  // Wire up the global message callback and token-refresh function.
  // The refreshFn reads the stored refresh token and calls the backend to get
  // a new access token — used by the 401 interceptor in ApiService.
  apiService.configure(
    
    showMessage: (msg) {

      scaffoldMessengerKey.currentState
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
    },
    refreshFn: () async {
      final session = await storageService.loadSession();
      if (session == null || session.refreshToken.isEmpty) return null;
      return authService.refreshToken(
        token: session.refreshToken,
        userId: session.user.employeeCode,
        storage: storageService,
      );
    },
    logoutFn: () async {
      apiService.setToken(null);
      await storageService.clearSession();
    },
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<StorageService>.value(value: storageService),
        Provider<AuthService>.value(value: authService),
        Provider<TemplateService>(create: (_) => TemplateService(apiService)),
        Provider<PipelineService>(create: (_) => PipelineService(apiService)),
        Provider<MasterDataService>(
          create: (_) => MasterDataService(apiService),
        ),
        ChangeNotifierProxyProvider2<AuthService, StorageService, AuthProvider>(
          create: (ctx) =>
              AuthProvider(ctx.read<AuthService>(), ctx.read<StorageService>()),
          update: (_, authService, storage, prev) =>
              prev ?? AuthProvider(authService, storage),
        ),
        ChangeNotifierProxyProvider<TemplateService, TemplateProvider>(
          create: (ctx) => TemplateProvider(ctx.read<TemplateService>()),
          update: (_, templateService, prev) =>
              prev ?? TemplateProvider(templateService),
        ),
      ],
      child: const PipelineApp(),
    ),
  );
}
