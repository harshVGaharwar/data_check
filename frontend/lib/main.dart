import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/template_service.dart';
import 'services/pipeline_service.dart';
import 'services/master_data_service.dart';
import 'providers/auth_provider.dart';
import 'providers/template_provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

/// Global key used by ApiService to show snackbars without a BuildContext.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final storageService = StorageService();

  // Wire up the global message callback so offline/error toasts work on every
  // page, including the login screen (where no BuildContext is available yet).
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
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<StorageService>.value(value: storageService),
        Provider<AuthService>(create: (_) => AuthService(apiService)),
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

class PipelineApp extends StatelessWidget {
  const PipelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HDFC Data Orchestration',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'DM Sans',
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.initialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (auth.isLoggedIn) {
            return const DashboardPage();
          }
          return const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
