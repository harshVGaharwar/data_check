import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/presentation/providers/auth_provider.dart';
import 'package:vizualizer/data/services/storage_service.dart';
import 'package:vizualizer/presentation/pages/auth/welcome_page.dart';
import 'package:vizualizer/presentation/pages/pipeline/template_creation_page.dart';
import 'package:vizualizer/presentation/pages/pipeline/template_creation_list_page.dart';
import 'package:vizualizer/presentation/pages/pipeline/template_configuration_page.dart';
import 'package:vizualizer/presentation/pages/pipeline/template_configuration_list_page.dart';
import 'package:vizualizer/presentation/pages/source/configuration_upload_page.dart';
import 'package:vizualizer/presentation/pages/source/source_configuration_page.dart';
import 'package:vizualizer/presentation/pages/source/manual_upload_page.dart';
// import 'package:vizualizer/presentation/pages/checker/checker_page.dart';
import 'package:vizualizer/presentation/pages/checker/checker_module_page.dart';
import 'package:vizualizer/presentation/pages/report/report_page.dart';
import 'package:vizualizer/presentation/pages/job/job_execution_page.dart';
import 'package:vizualizer/presentation/pages/pipeline/edit_template_configuration_page.dart';

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
    // 'Template Creation List',
    'Template Configuration',
    // // 'Template Configuration List',
    // 'Edit Configuration',
    // 'Configuration Upload',
    'Source Configuration',
    'Manual Upload',
    // 'Manual Upload Checker',
    'Checker Module',
    'Reports',
    'Job Execution',
  ];

  final _icons = const [
    Icons.home_outlined,
    Icons.add_circle_outline,
    // Icons.layers_rounded,
    Icons.settings_applications_outlined,
    // Icons.account_tree_rounded,
    // Icons.edit_note_rounded,
    // Icons.cloud_upload_outlined,
    Icons.storage_rounded,
    Icons.upload_file_rounded,
    // Icons.fact_check_outlined,
    Icons.rule_folder_outlined,
    Icons.bar_chart_rounded,
    Icons.play_circle_outline_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      WelcomePage(onNavigate: (i) => _navigate(i)),
      TemplateCreationPage(onClose: () => _navigate(0)),
      // const TemplateCreationListPage(),
      const TemplateConfigurationPage(),
      // const TemplateConfigurationListPage(),
      // const EditTemplateConfigurationPage(),
      // const ConfigurationUploadPage(),
      const SourceConfigurationPage(),
      const ManualUploadPage(),
      // const CheckerPage(),
      const CheckerModulePage(),
      const ReportPage(),
      const JobExecutionPage(),
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

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vizualizer/core/theme/app_theme.dart';
// import 'package:vizualizer/data/models/login_response.dart';
// import 'package:vizualizer/presentation/pages/pipeline/edit_template_configuration_page.dart';
// import 'package:vizualizer/presentation/providers/auth_provider.dart';
// import 'package:vizualizer/data/services/storage_service.dart';

// import 'package:vizualizer/presentation/pages/auth/welcome_page.dart';
// import 'package:vizualizer/presentation/pages/pipeline/template_creation_page.dart';
// import 'package:vizualizer/presentation/pages/pipeline/template_configuration_page.dart';
// import 'package:vizualizer/presentation/pages/source/source_configuration_page.dart';
// import 'package:vizualizer/presentation/pages/source/manual_upload_page.dart';
// import 'package:vizualizer/presentation/pages/checker/checker_module_page.dart';
// import 'package:vizualizer/presentation/pages/report/report_page.dart';
// import 'package:vizualizer/presentation/pages/job/job_execution_page.dart';

// class DMenuItem {
//   final String name;
//   final IconData icon;
//   final Widget page;

//   const DMenuItem(this.name, this.icon, this.page);
// }

// class DashboardPage extends StatefulWidget {
//   const DashboardPage({super.key});

//   @override
//   State<DashboardPage> createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   int _selectedIndex = 0;

//   List<String> _titles = [];
//   List<IconData> _icons = [];
//   List<Widget> _pages = [];

//   /// ✅ MASTER MENU LIST
//   final List<DMenuItem> masterMenu = [
//     DMenuItem('Home', Icons.home_outlined, WelcomePage(onNavigate: (i) {})),
//     DMenuItem(
//       'Template Creation',
//       Icons.add_circle_outline,
//       TemplateCreationPage(),
//     ),
//     DMenuItem(
//       'Template Configuration',
//       Icons.settings_applications_outlined,
//       TemplateConfigurationPage(),
//     ),
//     DMenuItem(
//       'Edit Configuration',
//       Icons.edit,
//       EditTemplateConfigurationPage(),
//     ),
//     DMenuItem(
//       'Source Configuration',
//       Icons.storage_rounded,
//       SourceConfigurationPage(),
//     ),
//     DMenuItem('Manual Upload', Icons.upload_file_rounded, ManualUploadPage()),
//     DMenuItem(
//       'Checker Module',
//       Icons.rule_folder_outlined,
//       CheckerModulePage(),
//     ),
//     DMenuItem('Reports', Icons.bar_chart_rounded, ReportPage()),
//     DMenuItem(
//       'Job Execution',
//       Icons.play_circle_outline_rounded,
//       JobExecutionPage(),
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final auth = context.read<AuthProvider>();
//       if (auth.initialized) {
//         _setupMenus();
//         _restorePageIndex();
//       } else {
//         // Auth is still restoring session — listen and retry once ready
//         void listener() {
//           if (auth.initialized) {
//             auth.removeListener(listener);
//             if (mounted) {
//               _setupMenus();
//               _restorePageIndex();
//             }
//           }
//         }
//         auth.addListener(listener);
//       }
//     });
//   }

//   /// ✅ Filter Menus based on user.menuList + isActive
//   void _setupMenus() {
//     final user = context.read<AuthProvider>().user?.user;

//     final filtered = masterMenu.where((menu) {
//       if (menu.name == "Home") return true;
//       if (menu.name == "Reports") return true;

//       final found = user?.menuList.firstWhere(
//         (m) => m.menuName == menu.name,
//         orElse: () =>
//             MenuPermission(id: 0, menuName: "", profileId: "", isActive: "N"),
//       );

//       return found?.isEnabled ?? false;
//     }).toList();

//     setState(() {
//       _titles = filtered.map((m) => m.name).toList();
//       _icons = filtered.map((m) => m.icon).toList();
//       _pages = filtered.map((m) => m.page).toList();
//     });
//   }

//   void _navigate(int index) {
//     setState(() => _selectedIndex = index);
//     context.read<StorageService>().savePageIndex(index);
//   }

//   Future<void> _restorePageIndex() async {
//     final storage = context.read<StorageService>();
//     final index = await storage.loadPageIndex();
//     if (mounted && index < _pages.length) {
//       setState(() => _selectedIndex = index);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.bg,
//       appBar: AppBar(
//         backgroundColor: AppColors.surface,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         iconTheme: const IconThemeData(color: AppColors.text),
//         title: LayoutBuilder(
//           builder: (context, constraints) {
//             final isMobile = constraints.maxWidth < 600;

//             return Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (!isMobile)
//                   Image.asset(
//                     'assets/images/HDFC_Bank_Logo.svg.png',
//                     height: 36,
//                     fit: BoxFit.contain,
//                   ), // Image.asset
//                 if (!isMobile) const SizedBox(width: 10),
//                 if (isMobile && _titles.isNotEmpty)
//                   Text(
//                     _titles[_selectedIndex],
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.text,
//                     ), // TextStyle
//                   ), // Text
//               ],
//             ); // Row
//           },
//         ), // LayoutBuilder
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(height: 1, color: AppColors.border),
//         ), // PreferredSize
//         actions: [
//           const SizedBox(width: 4),
//           Consumer<AuthProvider>(
//             builder: (context, auth, _) {
//               final user = auth.user?.user;
//               final name = user?.name ?? '';
//               final empCode = user?.employeeCode ?? '';
//               final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

//               return Padding(
//                 padding: const EdgeInsets.only(right: 12),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           name,
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.text,
//                           ), // TextStyle
//                         ), // Text
//                         Text(
//                           empCode,
//                           style: const TextStyle(
//                             fontSize: 10,
//                             color: AppColors.textDim,
//                           ), // TextStyle
//                         ), // Text
//                       ],
//                     ), // Column
//                     const SizedBox(width: 8),
//                     CircleAvatar(
//                       radius: 16,
//                       backgroundColor: const Color(
//                         0xFF004CBF,
//                       ).withValues(alpha: 0.1),
//                       child: Text(
//                         initial,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF004CBF),
//                         ), // TextStyle
//                       ), // Text
//                     ), // CircleAvatar
//                     const SizedBox(width: 10),
//                     InkWell(
//                       onTap: () async {
//                         final nav = Navigator.of(context);
//                         await context.read<AuthProvider>().logout();
//                         nav.pushReplacementNamed('/login');
//                       },
//                       borderRadius: BorderRadius.circular(8),
//                       child: Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: Colors.red.withValues(alpha: 0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ), // BoxDecoration
//                         child: const Icon(
//                           Icons.logout_rounded,
//                           size: 16,
//                           color: Colors.red,
//                         ), // Icon
//                       ), // Container
//                     ), // InkWell
//                   ],
//                 ),
//               ); // Padding
//             },
//           ), // Consumer
//         ],
//       ), // AppBar
//       drawer: _buildDrawer(),
//       body: _pages.isEmpty
//           ? const SizedBox.shrink()
//           : _pages[_selectedIndex],
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       backgroundColor: AppColors.surface,
//       child: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [Color(0xFF004CBF), Color(0xFF0066CC)],
//               ), // LinearGradient
//             ), // BoxDecoration
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Image.asset(
//                   'assets/images/HDFC_Bank_Logo.svg.png',
//                   height: 36,
//                 ), // Image.asset
//                 const SizedBox(height: 12),
//                 const Text(
//                   'Data Fusion',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                   ), // TextStyle
//                 ), // Text
//                 const SizedBox(height: 2),
//                 const Text(
//                   'Data Configuration Platform',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 12,
//                   ), // TextStyle
//                 ), // Text
//               ],
//             ), // Column
//           ), // Container
//           const SizedBox(height: 8),
//           Expanded(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   for (int i = 0; i < _titles.length; i++) _drawerItem(i),
//                   const SizedBox(height: 8),
//                 ],
//               ), // Column
//             ), // SingleChildScrollView
//           ), // Expanded
//         ],
//       ), // Column
//     ); // Drawer
//   }

//   Widget _drawerItem(int index) {
//     final selected = _selectedIndex == index;

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: selected
//             ? const Color(0xFF004CBF).withValues(alpha: 0.08)
//             : Colors.transparent,
//         borderRadius: BorderRadius.circular(10),
//       ), // BoxDecoration
//       child: ListTile(
//         leading: Icon(
//           _icons[index],
//           size: 20,
//           color: selected ? const Color(0xFF004CBF) : AppColors.textDim,
//         ), // Icon
//         title: Text(
//           _titles[index],
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
//             color: selected ? const Color(0xFF004CBF) : AppColors.text,
//           ), // TextStyle
//         ), // Text
//         trailing: selected
//             ? Container(
//                 width: 4,
//                 height: 20,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF004CBF),
//                   borderRadius: BorderRadius.circular(2),
//                 ), // BoxDecoration
//               ) // Container
//             : null,
//         onTap: () {
//           _navigate(index);
//           Navigator.pop(context);
//         },
//       ), // ListTile
//     ); // Container
//   }
// }
