import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/main.dart';
import 'package:vizualizer/pages/dashboard_page.dart';
import 'package:vizualizer/pages/login_page.dart';
import 'package:vizualizer/providers/auth_provider.dart';

class PipelineApp extends StatelessWidget {
  const PipelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Fusion',
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
