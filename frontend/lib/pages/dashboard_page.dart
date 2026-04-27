import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import 'welcome_page.dart';
import 'template_creation_page.dart';
import 'template_configuration_page.dart';
import 'configuration_upload_page.dart';
import 'source_configuration_page.dart';
import 'manual_upload_page.dart';
import 'checker_page.dart';
import 'report_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  final _titles = const [
    'Home',
    'Template Creation',
    'Template Configuration',
    // 'Configuration Upload',
    'Source Configuration',
    'Manual Upload',
    'Checker',
    'Reports',
  ];

  final _icons = const [
    Icons.home_outlined,
    Icons.add_circle_outline,
    Icons.settings_applications_outlined,
    // Icons.cloud_upload_outlined,
    Icons.storage_rounded,
    Icons.upload_file_rounded,
    Icons.fact_check_outlined,
    Icons.bar_chart_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      WelcomePage(onNavigate: (i) => _navigate(i)),
      const TemplateCreationPage(),
      const TemplateConfigurationPage(),
      // const ConfigurationUploadPage(),
      const SourceConfigurationPage(),
      const ManualUploadPage(),
      const CheckerPage(),
      const ReportPage(),
    ];
    _restorePageIndex();
  }

  void _navigate(int index) {
    setState(() => _selectedIndex = index);
    context.read<StorageService>().savePageIndex(index);
  }

  Future<void> _restorePageIndex() async {
    final storage = context.read<StorageService>();
    final index = await storage.loadPageIndex();
    if (mounted && index != _selectedIndex && index < _pages.length) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/HDFC_Bank_Logo.svg.png',
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Text(
            //       _titles[_selectedIndex],
            //       style: const TextStyle(
            //         fontSize: 15,
            //         fontWeight: FontWeight.w700,
            //         color: AppColors.text,
            //       ),
            //     ),
            //     const Text(
            //       'HDFC Data Orchestration',
            //       style: TextStyle(fontSize: 10, color: AppColors.textDim),
            //     ),
            //   ],
            // ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.notifications_outlined, size: 20),
          //   onPressed: () {},
          // ),
          const SizedBox(width: 4),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.user?.user;
              final name = user?.name ?? '';
              final empCode = user?.employeeCode ?? '';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          empCode,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF004C8F).withValues(alpha: 0.1),
                        border: Border.all(
                          color: const Color(0xFF004C8F).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF004C8F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Logout',
                      child: InkWell(
                        onTap: () async {
                          final nav = Navigator.of(context);
                          await context.read<AuthProvider>().logout();
                          nav.pushReplacementNamed('/login');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.red.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF004C8F), Color(0xFF0066CC)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/HDFC_Bank_Logo.svg.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Data Fusion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Data Configuration Platform',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _titles.length; i++) _drawerItem(i),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _drawerItem(int index) {
    final selected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: selected
            ? const Color(0xFF004C8F).withValues(alpha: 0.08)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          _icons[index],
          size: 20,
          color: selected ? const Color(0xFF004C8F) : AppColors.textDim,
        ),
        title: Text(
          _titles[index],
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF004C8F) : AppColors.text,
          ),
        ),
        trailing: selected
            ? Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: const Color(0xFF004C8F),
                ),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          _navigate(index);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
