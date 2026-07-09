import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/login_response.dart';
import 'package:vizualizer/presentation/pages/pipeline/edit_template_configuration_page.dart';
import 'package:vizualizer/presentation/pages/pipeline/template_creation_list_page.dart';
import 'package:vizualizer/presentation/pages/report/new_report_page.dart';
import 'package:vizualizer/presentation/pages/reviewer/reviewer_page.dart';

import 'package:vizualizer/presentation/providers/auth_provider.dart';
import 'package:vizualizer/data/services/storage_service.dart';

import 'package:vizualizer/presentation/pages/auth/welcome_page.dart';
import 'package:vizualizer/presentation/pages/pipeline/template_creation_page.dart';
import 'package:vizualizer/presentation/pages/pipeline/template_configuration_page.dart';
import 'package:vizualizer/presentation/pages/source/source_configuration_page.dart';
import 'package:vizualizer/presentation/pages/source/manual_upload_page.dart';
import 'package:vizualizer/presentation/pages/checker/checker_module_page.dart';

class DMenuItem {
  final String name;
  final IconData icon;
  final Widget page;

  const DMenuItem(this.name, this.icon, this.page);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // late List<String> _titles;
  // late List<IconData> _icons;
  // late List<Widget> _pages;
  List<String> _titles = [];
  List<IconData> _icons = [];
  List<Widget> _pages = [];

  late List<DMenuItem> masterMenu;

  bool isCollapsed = false;

  @override
  void initState() {
    super.initState();

    /// ✅ Build menu here (NOT in initializer)
    masterMenu = [
      DMenuItem(
        'Home',
        Icons.home_outlined,
        WelcomePage(onNavigate: _navigate),
      ),
      DMenuItem(
        'Template Creation',
        Icons.add_circle_outline,
        TemplateCreationPage(onClose: () => _navigate(0)),
      ),
      DMenuItem(
        'Template Configuration',
        Icons.settings_applications_outlined,
        TemplateConfigurationPage(),
      ),
      DMenuItem(
        'Edit Configuration',
        Icons.edit,
        EditTemplateConfigurationPage(),
      ),
      DMenuItem(
        'Source Configuration',
        Icons.storage_rounded,
        SourceConfigurationPage(),
      ),
      DMenuItem('Manual Upload', Icons.upload_file_rounded, ManualUploadPage()),
      DMenuItem(
        'Checker Module',
        Icons.rule_folder_outlined,
        CheckerModulePage(),
      ),
      DMenuItem('Data Fusion Output', Icons.bar_chart_rounded, NewReportPage()),
      DMenuItem('Reviewer Module', Icons.rule_folder_outlined, ReviewerPage()),
      // DMenuItem('Template Creation List', Icons.rule_folder_outlined,
      //     TemplateCreationListPage()),
      // DMenuItem(
      //   'Job Execution Log',
      //   Icons.play_circle_outline_rounded,F
      //   JobExecutionPage(),
      // ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();

      if (auth.initialized) {
        _setupMenus();
        _restorePageIndex();
      } else {
        void listener() {
          if (auth.initialized) {
            auth.removeListener(listener);
            if (mounted) {
              _setupMenus();
              _restorePageIndex();
            }
          }
        }

        auth.addListener(listener);
      }
    });
  }

  /// ✅ Filter menus by permissions
  void _setupMenus() {
    final user = context.read<AuthProvider>().user?.user;

    final filtered = masterMenu.where((menu) {
      if (menu.name == "Home") return true;
      if (menu.name == "Data Fusion Output") return true;

      if (menu.name == "Edit Configuration") return true;

      // if (menu.name == "Template Creation List") return true;
      // if (menu.name == 'Reviewer Module') return true;
      // if (menu.name == "Job Execution Log") return true;

      final found = user?.menuList.firstWhere(
        (m) => m.menuName == menu.name,
        orElse: () =>
            MenuPermission(id: 0, menuName: "", profileId: "", isActive: "N"),
      );

      return found?.isEnabled ?? false;
    }).toList();

    setState(() {
      _titles = filtered.map((m) => m.name).toList();
      _icons = filtered.map((m) => m.icon).toList();
      _pages = filtered.map((m) => m.page).toList();
    });
  }

  /// ✅ Safe navigation handler
  void _navigate(int index) {
    if (!mounted) return;
    if (index < 0 || index >= _pages.length) return;

    setState(() => _selectedIndex = index);
    context.read<StorageService>().savePageIndex(index);
  }

  /// ✅ Restore last selected tab
  Future<void> _restorePageIndex() async {
    final storage = context.read<StorageService>();
    final index = await storage.loadPageIndex();

    if (mounted && index < _pages.length) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),

            // ✅ Sidebar collapse icon
            Tooltip(
              message: isCollapsed ? "Open Menu" : "Close Menu",
              child: InkWell(
                onTap: () => setState(() => isCollapsed = !isCollapsed),
                child: Icon(
                  isCollapsed ? Icons.menu_open : Icons.menu,
                  size: 22,
                  color: AppColors.text,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // ✅ Page Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Fusion',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Data Configuration Platform',
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              ],
            ),
            SizedBox(width: 20),
            Image.asset('assets/images/HDFC_Bank_Logo.svg.png', height: 36),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
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
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF004CBF).withOpacity(0.1),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF004CBF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () async {
                        final nav = Navigator.of(context);
                        await context.read<AuthProvider>().logout();
                        nav.pushReplacementNamed('/login');
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: Colors.red,
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
      // body: _pages.isEmpty ? const SizedBox.shrink() : _pages[_selectedIndex],
      body: _pages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                _buildSideMenu(),
                Expanded(
                  child: Column(
                    children: [Expanded(child: _pages[_selectedIndex])],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSideMenu() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isCollapsed ? 70 : 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          // _buildMenuHeader(),
          // const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [for (int i = 0; i < _titles.length; i++) _menuItem(i)],
            ),
          ),
          // _buildCollapseButton(),
        ],
      ),
    );
  }

  Widget _menuItem(int index) {
    final selected = _selectedIndex == index;

    return InkWell(
      onTap: () => _navigate(index),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF004CBF).withOpacity(0.08) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              _icons[index],
              size: 20,
              color: selected ? const Color(0xFF004CBF) : AppColors.textDim,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _titles[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? const Color(0xFF004CBF) : AppColors.text,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
                colors: [Color(0xFF004CBF), Color(0xFF0066CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/HDFC_Bank_Logo.svg.png', height: 36),
                const SizedBox(height: 12),
                const Text(
                  'Data Fusion',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Data Configuration Platform',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (int i = 0; i < _titles.length; i++) _drawerItem(i),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(int index) {
    final selected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF004CBF).withValues(alpha: 0.08)
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          _icons[index],
          size: 20,
          color: selected ? const Color(0xFF004CBF) : AppColors.textDim,
        ),
        title: Text(
          _titles[index],
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF004CBF) : AppColors.text,
          ),
        ),
        trailing: selected
            ? Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF004CBF),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        onTap: () {
          _navigate(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
