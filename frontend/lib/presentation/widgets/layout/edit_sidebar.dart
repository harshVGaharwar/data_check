// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vizualizer/core/theme/app_theme.dart';
// import 'package:vizualizer/data/models/pipeline_models.dart';
// import 'package:vizualizer/data/models/master_models.dart';
// import 'package:vizualizer/data/models/template_info.dart';
// import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
// import 'package:vizualizer/presentation/providers/auth_provider.dart';
// import 'package:vizualizer/data/services/master_data_service.dart';
// import 'package:vizualizer/presentation/widgets/common/searchable_dropdown.dart';
// import 'package:vizualizer/presentation/widgets/common/shimmer_button.dart';
// import 'package:vizualizer/presentation/widgets/layout/sidebar.dart' show DynamicPaletteItem, JoinPaletteItem;
// import 'package:vizualizer/presentation/widgets/layout/stephighlight.dart';
// class EditSidebar extends StatefulWidget {
//   final Future<void> Function(int templateId, int deptId) onFetchConfig;
//   const EditSidebar({super.key, required this.onFetchConfig});

//   @override
//   State<EditSidebar> createState() => _EditSidebarState();
// }

// class _EditSidebarState extends State<EditSidebar>
//     with TickerProviderStateMixin {
//   Map<String, int> _deptMap = {};
//   bool _deptLoading = true;

//   List<TemplateInfo> _templates = [];
//   bool _templateLoading = false;
//   bool _sourceCountError = false;

//   List<SourceMasterFilterItem> _filteredSourceTypes = [];
//   bool _sourceTypesLoading = false;

//   int? _selectedTemplateId;
//   bool _fetching = false;
//   bool _configLoaded = false;

//   late final AnimationController _deptPulse;
//   late final AnimationController _templatePulse;
//   late final AnimationController _sourceCountPulse;
//   late final Animation<double> _deptAnim;
//   late final Animation<double> _templateAnim;
//   late final Animation<double> _sourceCountAnim;

//   int _lastClearVersion = 0;

//   @override
//   void initState() {
//     super.initState();
//     _deptPulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1000),
//     )..repeat(reverse: true);
//     _templatePulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1000),
//     );
//     _sourceCountPulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 750),
//     );
//     _deptAnim = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _deptPulse, curve: Curves.easeInOut));
//     _templateAnim = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _templatePulse, curve: Curves.easeInOut));
//     _sourceCountAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _sourceCountPulse, curve: Curves.easeInOut),
//     );

//     _loadDepartments();
//   }

//   @override
//   void dispose() {
//     _deptPulse.dispose();
//     _templatePulse.dispose();
//     _sourceCountPulse.dispose();
//     super.dispose();
//   }

//   Future<void> _loadDepartments() async {
//     final auth = context.read<AuthProvider>();
//     if (!auth.initialized) {
//       await Future.doWhile(() async {
//         await Future.delayed(const Duration(milliseconds: 50));
//         return mounted && !context.read<AuthProvider>().initialized;
//       });
//     }
//     if (!mounted) return;
//     final service = context.read<MasterDataService>();
//     final map = await service.getDepartmentMap();
//     if (!mounted) return;
//     setState(() {
//       _deptMap = map;
//       _deptLoading = false;
//     });
//   }

//   Future<void> _onDeptSelected(String deptName, PipelineController ctrl) async {
//     ctrl.setSidebarDept(deptName, deptId: _deptMap[deptName]?.toString() ?? '');
//     _deptPulse.stop();
//     _deptPulse.value = 0;
//     _templatePulse.repeat(reverse: true);
//     setState(() {
//       _templates = [];
//       _templateLoading = true;
//       _selectedTemplateId = null;
//       _filteredSourceTypes = [];
//       _sourceCountError = false;
//       _configLoaded = false;
//     });

//     final deptId = _deptMap[deptName];
//     if (deptId == null) {
//       setState(() => _templateLoading = false);
//       return;
//     }

//     final service = context.read<MasterDataService>();
//     // Only approved+configured templates
//     final templates = await service.getTemplatesByDept(deptId, 14);
//     if (!mounted) return;
//     setState(() {
//       _templates = templates;
//       _templateLoading = false;
//     });
//   }

//   Future<void> _loadFilteredSourceTypes({
//     required String templateId,
//     required String departmentId,
//   }) async {
//     setState(() {
//       _filteredSourceTypes = [];
//       _sourceTypesLoading = true;
//     });
//     final service = context.read<MasterDataService>();
//     final types = await service.getSourceMasterListFilterwise(
//       templateId: templateId,
//       departmentId: departmentId,
//     );
//     if (!mounted) return;
//     setState(() {
//       _filteredSourceTypes = types;
//       _sourceTypesLoading = false;
//     });
//   }

//   void _resetAnimations() {
//     for (final c in [_templatePulse, _sourceCountPulse]) {
//       c.stop();
//       c.value = 0;
//     }
//     if (!_deptPulse.isAnimating) _deptPulse.repeat(reverse: true);
//     setState(() {
//       _templates = [];
//       _templateLoading = false;
//       _sourceCountError = false;
//       _filteredSourceTypes = [];
//       _sourceTypesLoading = false;
//       _selectedTemplateId = null;
//       _fetching = false;
//     });
//   }

//   Future<void> _onFetchTapped(PipelineController ctrl) async {
//     final deptId = int.tryParse(ctrl.sidebarDeptId) ?? 0;
//     final templateId = _selectedTemplateId ?? 0;
//     if (deptId == 0 || templateId == 0) return;

//     setState(() => _fetching = true);
//     try {
//       await widget.onFetchConfig(templateId, deptId);
//       if (mounted) setState(() => _configLoaded = true);
//     } finally {
//       if (mounted) setState(() => _fetching = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = context.watch<PipelineController>();

//     if (ctrl.clearVersion != _lastClearVersion) {
//       _lastClearVersion = ctrl.clearVersion;
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) _resetAnimations();
//       });
//     }

//     return Container(
//       width: 220,
//       color: AppColors.surface,
//       child: Consumer<PipelineController>(
//         builder: (context, ctrl, _) {
//           final deptNames = _deptMap.keys.toList();
//           final templateNames = _templates.map((t) => t.templateName).toList();

//           final sourcesLoaded =
//               _filteredSourceTypes.isNotEmpty && !_sourceTypesLoading;
//           final canFetch =
//               ctrl.sidebarDept.isNotEmpty &&
//               ctrl.sidebarTemplate.isNotEmpty &&
//               !_sourceCountError &&
//               ctrl.requiredSourceCount > 0 &&
//               sourcesLoaded &&
//               !_fetching &&
//               !_configLoaded;

//           return Column(
//             children: [
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.all(10),
//                   children: [
//                     const SizedBox(height: 6),

//                     // ── Edit badge ──
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 6,
//                       ),
//                       margin: const EdgeInsets.only(bottom: 10),
//                       decoration: BoxDecoration(
//                         color: AppColors.amber.withValues(alpha: 0.08),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: AppColors.amber.withValues(alpha: 0.25),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(
//                             Icons.edit_note_rounded,
//                             size: 13,
//                             color: AppColors.amber,
//                           ),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               'Edit Configuration',
//                               style: AppTextStyles.fieldLabel.copyWith(
//                                 color: AppColors.amber,
//                                 fontSize: 10.5,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     // ── Department ──
//                     StepHighlight(
//                       animation: _deptAnim,
//                       color: AppColors.blue,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'DEPARTMENTS',
//                             style: AppTextStyles.sectionLabel,
//                           ),
//                           const SizedBox(height: 4),
//                           _deptLoading
//                               ? _loadingField()
//                               : SearchableDropdownField(
//                                   value: ctrl.sidebarDept.isEmpty
//                                       ? null
//                                       : ctrl.sidebarDept,
//                                   hint: '— Select Dept —',
//                                   items: deptNames,
//                                   onChanged: (v) {
//                                     if (v != null) _onDeptSelected(v, ctrl);
//                                   },
//                                 ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),

//                     // ── Template (approved only) ──
//                     StepHighlight(
//                       animation: _templateAnim,
//                       color: AppColors.blue,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               const Text(
//                                 'TEMPLATE',
//                                 style: AppTextStyles.sectionLabel,
//                               ),
//                               const SizedBox(width: 4),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 4,
//                                   vertical: 1,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: AppColors.green.withValues(alpha: 0.1),
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   'Approved',
//                                   style: AppTextStyles.sectionLabel.copyWith(
//                                     color: AppColors.green,
//                                     fontSize: 8,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           _templateLoading
//                               ? _loadingField()
//                               : SearchableDropdownField(
//                                   value:
//                                       templateNames.contains(
//                                         ctrl.sidebarTemplate,
//                                       )
//                                       ? ctrl.sidebarTemplate
//                                       : null,
//                                   hint: ctrl.sidebarDept.isEmpty
//                                       ? '— Select Dept first —'
//                                       : '— Select Template —',
//                                   items: templateNames,
//                                   enabled: ctrl.sidebarDept.isNotEmpty,
//                                   onChanged: (v) {
//                                     if (v == null) return;
//                                     final info = _templates.firstWhere(
//                                       (t) => t.templateName == v,
//                                       orElse: () => TemplateInfo(
//                                         templateId: 0,
//                                         templateName: v,
//                                         department: '',
//                                         frequency: '',
//                                         sourceCount: 0,
//                                         numberOfOutputs: 0,
//                                         normalVolume: 0,
//                                         peakVolume: 0,
//                                         priority: '',
//                                         benefitType: '',
//                                         benefitAmount: 0,
//                                         outputFormats: [],
//                                       ),
//                                     );
//                                     ctrl.setSidebarTemplate(
//                                       v,
//                                       sourceCount: info.sourceCount > 0
//                                           ? info.sourceCount
//                                           : null,
//                                       templateId: info.templateId,
//                                     );
//                                     setState(() {
//                                       _selectedTemplateId = info.templateId;
//                                       _configLoaded = false;
//                                     });

//                                     final deptId = _deptMap[ctrl.sidebarDept];
//                                     if (deptId != null && info.templateId > 0) {
//                                       _loadFilteredSourceTypes(
//                                         templateId: info.templateId.toString(),
//                                         departmentId: deptId.toString(),
//                                       );
//                                     }

//                                     _templatePulse.stop();
//                                     _templatePulse.value = 0;

//                                     if (info.sourceCount == 0) {
//                                       setState(() => _sourceCountError = true);
//                                       _sourceCountPulse.repeat(reverse: true);
//                                     } else {
//                                       setState(() => _sourceCountError = false);
//                                       _sourceCountPulse.repeat(reverse: true);
//                                       Timer(
//                                         const Duration(milliseconds: 1000),
//                                         () {
//                                           if (!mounted) return;
//                                           _sourceCountPulse.stop();
//                                           _sourceCountPulse.value = 0;
//                                         },
//                                       );
//                                     }
//                                   },
//                                 ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),

//                     // ── Source Count ──
//                     StepHighlight(
//                       animation: _sourceCountAnim,
//                       color: _sourceCountError
//                           ? const Color(0xFFE53935)
//                           : AppColors.blue,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'SOURCE COUNT',
//                             style: AppTextStyles.sectionLabel,
//                           ),
//                           const SizedBox(height: 4),
//                           _buildRequiredSourcesBox(ctrl),
//                         ],
//                       ),
//                     ),

//                     if (ctrl.requiredSourceCount > 0) ...[
//                       const SizedBox(height: 10),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(
//                             color: AppColors.green.withValues(alpha: 0.3),
//                           ),
//                           color: AppColors.green.withValues(alpha: 0.06),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const Text(
//                               'Required Sources',
//                               style: TextStyle(
//                                 color: AppColors.text,
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                             Text(
//                               '${ctrl.requiredSourceCount}',
//                               style: const TextStyle(
//                                 color: AppColors.green,
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 13,
//                                 fontFamily: 'monospace',
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],

//                     const SizedBox(height: 12),

//                     // ── Source Type ──
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'SOURCE TYPE',
//                           style: AppTextStyles.sectionLabel,
//                         ),
//                         const SizedBox(height: 6),
//                         Builder(
//                           builder: (_) {
//                             if (_sourceTypesLoading) return _loadingField();
//                             if (_filteredSourceTypes.isEmpty) {
//                               return const Text(
//                                 'Select template to load sources',
//                                 style: TextStyle(
//                                   color: AppColors.textMuted,
//                                   fontSize: 11,
//                                 ),
//                               );
//                             }
//                             final canAdd =
//                                 _configLoaded &&
//                                 ctrl.canAddSource &&
//                                 ctrl.requiredSourceCount > 0;
//                             return Column(
//                               children: _filteredSourceTypes
//                                   .map(
//                                     (st) => DynamicPaletteItem(
//                                       sourceItem: st,
//                                       enabled: canAdd,
//                                     ),
//                                   )
//                                   .toList(),
//                             );
//                           },
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 12),

//                     // ── Operations ──
//                     const Text('OPERATIONS', style: AppTextStyles.sectionLabel),
//                     const SizedBox(height: 6),

//                     JoinPaletteItem(ctrl: ctrl),

//                     const SizedBox(height: 16),

//                     // ── Load Configuration button ──
//                     if (_fetching)
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(vertical: 11),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(8),
//                           color: AppColors.blue.withValues(alpha: 0.12),
//                           border: Border.all(
//                             color: AppColors.blue.withValues(alpha: 0.3),
//                           ),
//                         ),
//                         child: const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             SizedBox(
//                               width: 13,
//                               height: 13,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: AppColors.blue,
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                             Text(
//                               'Loading…',
//                               style: TextStyle(
//                                 color: AppColors.blue,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ],
//                         ),
//                       )
//                     else
//                       SizedBox(
//                         width: double.infinity,
//                         child: ShimmerButton(
//                           label: 'Load Configuration',
//                           icon: Icons.cloud_download_outlined,
//                           color: AppColors.blue,
//                           animating: canFetch,
//                           onTap: canFetch ? () => _onFetchTapped(ctrl) : null,
//                         ),
//                       ),

//                     const SizedBox(height: 12),
//                     const Text(
//                       'INSTRUCTIONS',
//                       style: AppTextStyles.sectionLabel,
//                     ),
//                     const SizedBox(height: 4),
//                     const Text(
//                       '1. Select Dept → Approved Template\n2. Verify source count & types\n3. Tap Load Configuration\n4. Edit nodes, then re-submit',
//                       style: TextStyle(
//                         color: AppColors.textDim,
//                         fontSize: 10.5,
//                         height: 1.6,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildRequiredSourcesBox(PipelineController ctrl) {
//     if (ctrl.sidebarTemplate.isNotEmpty && ctrl.requiredSourceCount == 0) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(7),
//           border: Border.all(
//             color: const Color(0xFFE53935).withValues(alpha: 0.4),
//           ),
//           color: const Color(0xFFE53935).withValues(alpha: 0.05),
//         ),
//         child: const Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(Icons.error_outline, color: Color(0xFFE53935), size: 14),
//             SizedBox(width: 6),
//             Expanded(
//               child: Text(
//                 'Source count not configured for this template',
//                 style: TextStyle(
//                   color: Color(0xFFE53935),
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                   height: 1.4,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(7),
//         border: Border.all(color: AppColors.border2),
//         color: AppColors.surface2,
//       ),
//       child: ctrl.requiredSourceCount > 0
//           ? Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   '${ctrl.requiredSourceCount}',
//                   style: const TextStyle(
//                     color: AppColors.amber,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Container(
//                   width: 16,
//                   height: 16,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: AppColors.green.withValues(alpha: 0.15),
//                     border: Border.all(
//                       color: AppColors.green.withValues(alpha: 0.5),
//                     ),
//                   ),
//                   child: const Icon(
//                     Icons.check_rounded,
//                     color: AppColors.green,
//                     size: 10,
//                   ),
//                 ),
//               ],
//             )
//           : const Text(
//               'Select template first',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: AppColors.textMuted,
//                 fontWeight: FontWeight.w700,
//                 fontSize: 13,
//               ),
//             ),
//     );
//   }

//   Widget _loadingField() {
//     return Container(
//       height: 34,
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(7),
//         border: Border.all(color: AppColors.border2),
//         color: AppColors.surface2,
//       ),
//       child: const Row(
//         children: [
//           SizedBox(
//             width: 12,
//             height: 12,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               color: AppColors.textDim,
//             ),
//           ),
//           SizedBox(width: 8),
//           Text(
//             'Loading...',
//             style: TextStyle(fontSize: 11, color: AppColors.textMuted),
//           ),
//         ],
//       ),
//     );
//   }
// }

// EDIT SIDEBAR

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/master_models.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';
import 'package:vizualizer/data/models/template_info.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
import 'package:vizualizer/presentation/providers/auth_provider.dart';
import 'package:vizualizer/data/services/master_data_service.dart';
import 'package:vizualizer/presentation/widgets/common/searchable_dropdown.dart';
import 'package:vizualizer/presentation/widgets/layout/sidebar.dart'
    show DynamicPaletteItem, JoinPaletteItem;
import 'package:vizualizer/presentation/widgets/layout/stephighlight.dart';
import 'package:vizualizer/presentation/widgets/layout/template_config_badget.dart';
import 'package:vizualizer/presentation/widgets/layout/output_key_selector.dart';

class EditSidebar extends StatefulWidget {
  const EditSidebar({super.key});

  @override
  State<EditSidebar> createState() => _EditSidebarState();
}

class _EditSidebarState extends State<EditSidebar>
    with TickerProviderStateMixin {
  Map<String, int> _deptMap = {};
  bool _deptLoading = true;

  List<TemplateInfo> _templates = [];
  bool _templateLoading = false;
  bool _sourceCountError = false;

  List<SourceMasterFilterItem> _filteredSourceTypes = [];
  bool _sourceTypesLoading = false;

  /// Full per-key canvas configs from the API jsonData list.
  /// Populated in _onTemplateSelected; used in _onOutputKeySelected to load
  /// the correct pipeline config when a dynamic key is selected.
  List<Map<String, dynamic>> _jsonDataList = [];

  late final AnimationController _deptPulse;
  late final AnimationController _templatePulse;
  late final AnimationController _sourceCountPulse;
  late final AnimationController _sourceTypePulse;
  late final Animation<double> _deptAnim;
  late final Animation<double> _templateAnim;
  late final Animation<double> _sourceCountAnim;
  late final Animation<double> _sourceTypeAnim;

  int _lastClearVersion = 0;
  int _lastCanvasVersion = 0;

  @override
  void initState() {
    super.initState();
    _deptPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _templatePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _sourceCountPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _sourceTypePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _deptAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _deptPulse, curve: Curves.easeInOut));
    _templateAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _templatePulse, curve: Curves.easeInOut));
    _sourceCountAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sourceCountPulse, curve: Curves.easeInOut),
    );
    _sourceTypeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sourceTypePulse, curve: Curves.easeInOut),
    );

    _loadDepartments();
  }

  @override
  void dispose() {
    _deptPulse.dispose();
    _templatePulse.dispose();
    _sourceCountPulse.dispose();
    _sourceTypePulse.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    final auth = context.read<AuthProvider>();
    if (!auth.initialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return mounted && !context.read<AuthProvider>().initialized;
      });
    }
    if (!mounted) return;
    final service = context.read<MasterDataService>();
    final map = await service.getDepartmentMap();
    if (!mounted) return;
    setState(() {
      _deptMap = map;
      _deptLoading = false;
    });
  }

  Future<void> _onDeptSelected(String deptName, PipelineController ctrl) async {
    if (ctrl.nodes.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.06),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.red.withValues(alpha: 0.14),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            size: 26,
                            color: AppColors.red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Change Department?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amberDim,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.amber.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: AppColors.amber,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Unsaved canvas work will be lost',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Switching department will discard all nodes, joins, and output mappings on the current canvas.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textDim,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 4,
                                  color: AppColors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WHAT WILL BE CLEARED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _clearItem('Source body & file settings'),
                              const SizedBox(height: 6),
                              _clearItem('Join conditions & mappings'),
                              const SizedBox(height: 6),
                              _clearItem('Output selection & field mappings'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(false),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.text,
                                  side: const BorderSide(
                                    color: AppColors.border2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(true),
                                icon: const Icon(
                                  Icons.delete_sweep_rounded,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Clear Canvas',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      ctrl.clearCanvas();
      _resetAnimations();
    }

    ctrl.setSidebarDept(deptName, deptId: _deptMap[deptName]?.toString() ?? '');
    _deptPulse.stop();
    _deptPulse.value = 0;
    _templatePulse.repeat(reverse: true);
    setState(() {
      _templates = [];
      _templateLoading = true;
      _filteredSourceTypes = [];
      _sourceCountError = false;
    });

    final deptId = _deptMap[deptName];
    if (deptId == null) {
      setState(() => _templateLoading = false);
      return;
    }

    final service = context.read<MasterDataService>();
    final templates = await service.getTemplatesDynamic(deptId, 1);
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _templateLoading = false;
    });

    if (templates.isEmpty) {
      _templatePulse.stop();
      _templatePulse.value = 0;
      _sourceCountPulse.stop();
      _sourceCountPulse.value = 0;
      _sourceTypePulse.stop();
      _sourceTypePulse.value = 0;
    }
  }

  Future<void> _loadFilteredSourceTypes({
    required String templateId,
    required String departmentId,
  }) async {
    setState(() {
      _filteredSourceTypes = [];
      _sourceTypesLoading = true;
    });
    final service = context.read<MasterDataService>();
    final types = await service.getSourceMasterListFilterwise(
      templateId: templateId,
      departmentId: departmentId,
    );
    if (!mounted) return;
    setState(() {
      _filteredSourceTypes = types;
      _sourceTypesLoading = false;
    });
  }

  Widget _clearItem(String text) => Row(
    children: [
      const Icon(Icons.close_rounded, size: 14, color: AppColors.red),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.text,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Future<void> _onTemplateSelected(String v, PipelineController ctrl) async {
    if (ctrl.nodes.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.06),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.red.withValues(alpha: 0.14),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            size: 26,
                            color: AppColors.red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Change Template?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amberDim,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.amber.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: AppColors.amber,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Unsaved canvas work will be lost',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Switching template will discard all nodes, joins, and output mappings on the current canvas.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textDim,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 4,
                                  color: AppColors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WHAT WILL BE CLEARED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _clearItem('Source body & file settings'),
                              const SizedBox(height: 6),
                              _clearItem('Join conditions & mappings'),
                              const SizedBox(height: 6),
                              _clearItem('Output selection & field mappings'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(false),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.text,
                                  side: const BorderSide(
                                    color: AppColors.border2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(true),
                                icon: const Icon(
                                  Icons.delete_sweep_rounded,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Clear Canvas',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      ctrl.clearCanvas();
      _sourceCountPulse.stop();
      _sourceCountPulse.value = 0;
      _sourceTypePulse.stop();
      _sourceTypePulse.value = 0;
      setState(() {
        _filteredSourceTypes = [];
        _sourceCountError = false;
      });
    }

    if (!mounted) return;

    final info = _templates.firstWhere(
      (t) => t.templateName == v,
      orElse: () => TemplateInfo(
        templateId: 0,
        templateName: v,
        department: null,
        frequency: '',
        sourceCount: 0,
        numberOfOutputs: 0,
        normalVolume: 0,
        peakVolume: 0,
        priority: 0,
        benefitType: 0,
        benefitAmount: 0,
        outputFormats: [],
        dynamicTemplates: [],
        templateType: '',
      ),
    );
    final dynEntry0 = info.dynamicTemplates.isNotEmpty
        ? info.dynamicTemplates[0]
        : null;
    final dynSourceCount =
        int.tryParse(dynEntry0?.sourceCount ?? '') ?? 0;
    ctrl.setSidebarTemplate(
      v,
      sourceCount: dynSourceCount > 0
          ? dynSourceCount
          : (info.sourceCount > 0 ? info.sourceCount : null),
      templateId: info.templateId,
      templateType: info.templateType,
      outputFormats: info.outputFormats,
      numberOfOutputs: info.numberOfOutputs,
      dynamicTemplates: info.dynamicTemplates.map((e) => e.toJson()).toList(),
      frequency: info.frequency,
    );

    _templatePulse.stop();
    _templatePulse.value = 0;

    // Store all per-key configs for use in _onOutputKeySelected
    _jsonDataList = info.editConfig?.jsonDataList ?? [];
    ctrl.setEditJsonDataKeyCount(_jsonDataList.length);

    // Load canvas configuration from embedded jsonData
    debugPrint(
      '[EditSidebar] jsonData=${info.editConfig?.jsonData == null ? "NULL" : "keys=${info.editConfig!.jsonData!.keys.toList()}"}, jsonDataList.length=${_jsonDataList.length}',
    );
    if (info.editConfig?.jsonData?.isNotEmpty == true) {
      context.read<PipelineController>().loadConfiguration(info.editConfig!.jsonData!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No configuration data found for this template.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final isDynUni =
        (info.templateType == '3' ||
            info.templateType.toLowerCase().contains('dynamic')) &&
        info.outputFormats.any((f) => f.toLowerCase().contains('unimailing'));

    if (isDynUni) {
      if (ctrl.selectedOutputKey.isNotEmpty) {
        _onOutputKeySelected(ctrl.selectedOutputKey, ctrl);
      } else {
        setState(() {
          _sourceCountError = false;
          _filteredSourceTypes = [];
        });
        _sourceCountPulse.stop();
        _sourceCountPulse.value = 0;
        _sourceTypePulse.stop();
        _sourceTypePulse.value = 0;
      }
    } else {
      final deptId = _deptMap[ctrl.sidebarDept];
      if (deptId != null && info.templateId > 0) {
        _loadFilteredSourceTypes(
          templateId: info.templateId.toString(),
          departmentId: deptId.toString(),
        ).then((_) {
          if (!mounted) return;
          if (info.sourceCount == 0) {
            setState(() => _sourceCountError = true);
            _sourceCountPulse.repeat(reverse: true);
          } else {
            setState(() => _sourceCountError = false);
            _sourceCountPulse.repeat(reverse: true);
            Timer(const Duration(milliseconds: 1000), () {
              if (!mounted) return;
              _sourceCountPulse.stop();
              _sourceCountPulse.value = 0;
              _sourceTypePulse.repeat(reverse: true);
            });
          }
        });
      } else {
        if (info.sourceCount == 0) {
          setState(() => _sourceCountError = true);
          _sourceCountPulse.repeat(reverse: true);
        } else {
          setState(() => _sourceCountError = false);
          _sourceCountPulse.repeat(reverse: true);
          Timer(const Duration(milliseconds: 1000), () {
            if (!mounted) return;
            _sourceCountPulse.stop();
            _sourceCountPulse.value = 0;
          });
        }
      }
    }
  }

  void _onOutputKeySelected(String key, PipelineController ctrl) {
    final entry = ctrl.getDynamicTemplateForOutputKey(key);
    if (entry == null) return;

    final rawList = entry['sourceMasterList'] as List?;
    final sources =
        rawList
            ?.whereType<Map<String, dynamic>>()
            .map(SourceMasterFilterItem.fromJson)
            .toList() ??
        [];

    final sourceCount =
        int.tryParse(entry['sourceCount']?.toString() ?? '') ?? 0;
    ctrl.setOutputKeySourceCount(sourceCount);
    setState(() {
      _filteredSourceTypes = sources;
      _sourceCountError = false;
    });

    // Load per-key canvas config and pre-fill the output form for unsaved keys.
    if (!ctrl.savedOutputKeyConfigs.containsKey(key) && _jsonDataList.isNotEmpty) {
      final keys = ctrl.dynamicUniMailingOutputKeys;
      final keyIdx = keys.indexOf(key);
      if (keyIdx >= 0 && keyIdx < _jsonDataList.length) {
        if (_jsonDataList.length > 1) {
          // For multi-key templates, load the per-key canvas config.
          // Single-key: already loaded by _onTemplateSelected, skip re-load.
          ctrl.loadConfiguration(_jsonDataList[keyIdx]);
        }
        // Synthesize savedOutputKeyConfig so the output node form is pre-filled.
        ctrl.synthesizeEditKeyConfig(key, _jsonDataList[keyIdx]);
      }
    }

    if (ctrl.savedOutputKeyConfigs.containsKey(key)) return;

    _sourceCountPulse.repeat(reverse: true);
    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _sourceCountPulse.stop();
      _sourceCountPulse.value = 0;
      if (sources.isNotEmpty) _sourceTypePulse.repeat(reverse: true);
    });
  }

  void _resetAnimations() {
    for (final c in [_templatePulse, _sourceCountPulse, _sourceTypePulse]) {
      c.stop();
      c.value = 0;
    }
    if (!_deptPulse.isAnimating) _deptPulse.repeat(reverse: true);
    setState(() {
      _templates = [];
      _templateLoading = false;
      _sourceCountError = false;
      _filteredSourceTypes = [];
      _sourceTypesLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PipelineController>();

    if (ctrl.clearVersion != _lastClearVersion) {
      _lastClearVersion = ctrl.clearVersion;
      _lastCanvasVersion = ctrl.canvasVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetAnimations();
      });
    } else if (ctrl.canvasVersion != _lastCanvasVersion) {
      _lastCanvasVersion = ctrl.canvasVersion;
      // Skip in edit mode: _onOutputKeySelected is called directly by OutputKeySelector.onChanged.
      // Calling it again from here would re-invoke loadConfiguration → canvasVersion++ → infinite loop.
      final isDynUniCanvasChange =
          ctrl.isDynamicUniMailing &&
          ctrl.selectedOutputKey.isNotEmpty &&
          ctrl.templateMode != TemplateMode.edit;
      if (isDynUniCanvasChange) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (ctrl.savedOutputKeyConfigs.containsKey(ctrl.selectedOutputKey)) {
            for (final c in [
              _deptPulse,
              _templatePulse,
              _sourceCountPulse,
              _sourceTypePulse,
            ]) {
              c.stop();
              c.value = 0;
            }
          }
          _onOutputKeySelected(ctrl.selectedOutputKey, ctrl);
        });
      }
    }

    return Container(
      width: 220,
      color: AppColors.surface,
      child: Consumer<PipelineController>(
        builder: (context, ctrl, _) {
          final deptNames = _deptMap.keys.toList();
          final templateNames = _templates.map((t) => t.templateName).toList();

          final canAdd = ctrl.canAddSource && ctrl.requiredSourceCount > 0;

          // Sync source type pulse with canvas count
          if (ctrl.sidebarTemplate.isNotEmpty && ctrl.requiredSourceCount > 0) {
            final filled = ctrl.sourceNodesOnCanvas >= ctrl.requiredSourceCount;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (filled && _sourceTypePulse.isAnimating) {
                _sourceTypePulse.stop();
                _sourceTypePulse.value = 0;
              } else if (!filled && !_sourceTypePulse.isAnimating) {
                _sourceTypePulse.repeat(reverse: true);
              }
            });
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    const SizedBox(height: 6),

                    // ── Edit badge ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            size: 13,
                            color: AppColors.amber,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Edit Configuration',
                              style: AppTextStyles.fieldLabel.copyWith(
                                color: AppColors.amber,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Department ──
                    StepHighlight(
                      animation: _deptAnim,
                      color: AppColors.blue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DEPARTMENTS',
                            style: AppTextStyles.sectionLabel,
                          ),
                          const SizedBox(height: 4),
                          _deptLoading
                              ? _loadingField()
                              : SearchableDropdownField(
                                  value: ctrl.sidebarDept.isEmpty
                                      ? null
                                      : ctrl.sidebarDept,
                                  hint: '— Select Dept —',
                                  items: deptNames,
                                  onChanged: (v) {
                                    if (v != null) _onDeptSelected(v, ctrl);
                                  },
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Template (approved only) ──
                    StepHighlight(
                      animation: _templateAnim,
                      color: AppColors.blue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'TEMPLATE',
                                style: AppTextStyles.sectionLabel,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _templateLoading
                              ? _loadingField()
                              : SearchableDropdownField(
                                  value:
                                      templateNames.contains(
                                        ctrl.sidebarTemplate,
                                      )
                                      ? ctrl.sidebarTemplate
                                      : null,
                                  hint: ctrl.sidebarDept.isEmpty
                                      ? '— Select Dept first —'
                                      : '— Select Template —',
                                  items: templateNames,
                                  enabled: ctrl.sidebarDept.isNotEmpty,
                                  onChanged: (v) {
                                    if (v != null) _onTemplateSelected(v, ctrl);
                                  },
                                ),
                        ],
                      ),
                    ),

                    // ── Template type + output format badge ──
                    if (ctrl.sidebarTemplate.isNotEmpty &&
                        ctrl.templateType.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      TemplateConfigBadge(
                        templateType: ctrl.templateType,
                        outputFormats: ctrl.outputFormats,
                      ),
                    ],

                    // ── Output Key selector (Dynamic + UniMailing) ──
                    if (ctrl.sidebarTemplate.isNotEmpty &&
                        ctrl.isDynamicUniMailing) ...[
                      const SizedBox(height: 8),
                      OutputKeySelector(
                        ctrl: ctrl,
                        onOutputKeySelected: _onOutputKeySelected,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // ── Source Count ──
                    StepHighlight(
                      animation: _sourceCountAnim,
                      color: _sourceCountError
                          ? const Color(0xFFE53935)
                          : AppColors.blue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SOURCE COUNT',
                            style: AppTextStyles.sectionLabel,
                          ),
                          const SizedBox(height: 4),
                          _buildRequiredSourcesBox(ctrl),
                        ],
                      ),
                    ),

                    // ── Live sources-added counter ──
                    if (ctrl.requiredSourceCount > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                ctrl.sourceNodesOnCanvas >=
                                    ctrl.requiredSourceCount
                                ? AppColors.green.withValues(alpha: 0.3)
                                : AppColors.amber.withValues(alpha: 0.3),
                          ),
                          color:
                              ctrl.sourceNodesOnCanvas >=
                                  ctrl.requiredSourceCount
                              ? AppColors.green.withValues(alpha: 0.06)
                              : AppColors.amber.withValues(alpha: 0.06),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sources Added',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${ctrl.sourceNodesOnCanvas} / ${ctrl.requiredSourceCount}',
                              style: TextStyle(
                                color:
                                    ctrl.sourceNodesOnCanvas >=
                                        ctrl.requiredSourceCount
                                    ? AppColors.green
                                    : AppColors.amber,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ── Source Type ──
                    StepHighlight(
                      animation: _sourceTypeAnim,
                      color: AppColors.blue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SOURCE TYPE',
                            style: AppTextStyles.sectionLabel,
                          ),
                          const SizedBox(height: 6),
                          Builder(
                            builder: (_) {
                              if (_sourceTypesLoading) return _loadingField();
                              if (_filteredSourceTypes.isEmpty) {
                                return const Text(
                                  'Select template to load sources',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                );
                              }
                              final showManualFirstHint =
                                  ctrl.requiresManualFirst &&
                                  !ctrl.hasManualSource &&
                                  ctrl.sidebarTemplate.isNotEmpty;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showManualFirstHint) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: AppColors.amber.withValues(
                                          alpha: 0.08,
                                        ),
                                        border: Border.all(
                                          color: AppColors.amber.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 12,
                                            color: AppColors.amber,
                                          ),
                                          SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              'Drag Manual source first',
                                              style: TextStyle(
                                                color: AppColors.amber,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  ..._filteredSourceTypes.map(
                                    (st) => DynamicPaletteItem(
                                      sourceItem: st,
                                      enabled:
                                          canAdd &&
                                          ctrl.isAllowedSourceType(
                                            st.sourceType!,
                                          ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text('OPERATIONS', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 6),
                    JoinPaletteItem(ctrl: ctrl),

                    const SizedBox(height: 12),
                    const Text(
                      'INSTRUCTIONS',
                      style: AppTextStyles.sectionLabel,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '1. Select Dept → Template\n2. Canvas loads automatically\n3. Edit nodes as needed\n4. Re-submit when done',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 10.5,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequiredSourcesBox(PipelineController ctrl) {
    final isDynUni = ctrl.isDynamicUniMailing;
    if (ctrl.sidebarTemplate.isNotEmpty &&
        ctrl.requiredSourceCount == 0 &&
        !isDynUni) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: const Color(0xFFE53935).withValues(alpha: 0.4),
          ),
          color: const Color(0xFFE53935).withValues(alpha: 0.05),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: Color(0xFFE53935), size: 14),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Source count not configured for this template',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border2),
        color: AppColors.surface2,
      ),
      child: ctrl.requiredSourceCount > 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${ctrl.requiredSourceCount}',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.green.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.green,
                    size: 10,
                  ),
                ),
              ],
            )
          : const Text(
              'Select template first',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
    );
  }

  Widget _loadingField() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border2),
        color: AppColors.surface2,
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textDim,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Loading...',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
