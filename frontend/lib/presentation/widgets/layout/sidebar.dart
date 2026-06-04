import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/master_models.dart';
import 'package:vizualizer/data/models/template_info.dart';
import 'package:vizualizer/data/services/master_data_service.dart';
import 'package:vizualizer/presentation/widgets/common/searchable_dropdown.dart';
import 'package:vizualizer/presentation/widgets/layout/template_config_badget.dart';
import 'package:vizualizer/presentation/providers/auth_provider.dart';
import 'package:vizualizer/presentation/widgets/layout/stephighlight.dart';
import 'package:vizualizer/presentation/widgets/layout/output_key_selector.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';

part 'sidebar_widgets.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with TickerProviderStateMixin {
  // dept name → dept id
  Map<String, int> _deptMap = {};
  bool _deptLoading = true;

  List<TemplateInfo> _templates = [];
  bool _templateLoading = false;
  bool _sourceCountError =
      false; // true when template has no sourceCount configured

  List<SourceMasterFilterItem> _filteredSourceTypes = [];
  bool _sourceTypesLoading = false;

  late final AnimationController _deptPulse;
  late final AnimationController _templatePulse;
  late final AnimationController _sourceCountPulse;
  late final AnimationController _sourceTypePulse;
  late final Animation<double> _deptAnim;
  late final Animation<double> _templateAnim;
  late final Animation<double> _sourceCountAnim;
  late final Animation<double> _sourceTypeAnim;

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
    // Wait for auth to finish restoring the session so the token is set before
    // the API call goes out (matters on page reload).
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
    // If canvas has unsaved work, confirm before clearing
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
                  // ── Top banner ──
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

                  // ── Body ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Warning box
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
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: AppColors.amber,
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
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

                        // What will be cleared
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
                              _sidebarClearItem('Source body & file settings'),
                              const SizedBox(height: 6),
                              _sidebarClearItem('Join conditions & mappings'),
                              const SizedBox(height: 6),
                              _sidebarClearItem(
                                'Output selection & field mappings',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Buttons
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
    // Dept done → stop dept pulse, start template pulse
    _deptPulse.stop();
    _deptPulse.value = 0;
    _templatePulse.repeat(reverse: true);
    setState(() {
      _templates = [];
      _templateLoading = true;
    });

    final deptId = _deptMap[deptName];
    if (deptId == null) {
      setState(() => _templateLoading = false);
      return;
    }

    final service = context.read<MasterDataService>();
    final templates = await service.getTemplatesDynamic(deptId, 2);
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _templateLoading = false;
    });
  }

  Future<void> _onTemplateSelected(String v, PipelineController ctrl) async {
    // If canvas has unsaved work, confirm before clearing
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
                  // ── Top banner ──
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

                  // ── Body ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Warning box
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
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: AppColors.amber,
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
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

                        // What will be cleared
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
                              _sidebarClearItem('Source body & file settings'),
                              const SizedBox(height: 6),
                              _sidebarClearItem('Join conditions & mappings'),
                              const SizedBox(height: 6),
                              _sidebarClearItem(
                                'Output selection & field mappings',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Buttons
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
        department: '',
        frequency: '',
        sourceCount: 0,
        numberOfOutputs: 0,
        normalVolume: 0,
        peakVolume: 0,
        priority: '',
        benefitType: '',
        benefitAmount: 0,
        outputFormats: [],
      ),
    );
    final dynEntry0 = info.dynamicTemplates.isNotEmpty
        ? info.dynamicTemplates[0]
        : null;
    final dynSourceCount =
        int.tryParse(dynEntry0?['sourceCount']?.toString() ?? '') ?? 0;
    ctrl.setSidebarTemplate(
      v,
      sourceCount: dynSourceCount > 0
          ? dynSourceCount
          : (info.sourceCount > 0 ? info.sourceCount : null),
      templateId: info.templateId,
      templateType: info.templateType,
      outputFormats: info.outputFormats,
      numberOfOutputs: info.numberOfOutputs,
      dynamicTemplates: info.dynamicTemplates,
    );

    _templatePulse.stop();
    _templatePulse.value = 0;

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
      final rawList = dynEntry0?['sourceMasterList'] as List?;
      final sources =
          rawList
              ?.whereType<Map<String, dynamic>>()
              .map(SourceMasterFilterItem.fromJson)
              .toList() ??
          [];
      if (dynEntry0 != null && dynSourceCount > 0) {
        ctrl.setOutputKeySourceCount(dynSourceCount);
      }
      setState(() {
        _filteredSourceTypes = sources;
        _sourceCountError = false;
      });

      final effectiveCount = ctrl.requiredSourceCount;
      if (effectiveCount == 0) {
        _sourceTypePulse.stop();
        _sourceTypePulse.value = 0;
        _sourceCountPulse.repeat(reverse: true);
      } else {
        _sourceCountPulse.repeat(reverse: true);
        Timer(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          _sourceCountPulse.stop();
          _sourceCountPulse.value = 0;
          _sourceTypePulse.repeat(reverse: true);
        });
      }
    }
  }

  Widget _sidebarClearItem(String text) => Row(
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

  /// Called when user picks an output key in the Dynamic+UniMailing flow.
  /// Loads sourceMasterList from the matching dynamicTemplate entry (no API call).
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

    // Viewing a saved key — sources loaded but no setup animations.
    if (ctrl.savedOutputKeyConfigs.containsKey(key)) return;

    // Fresh key being configured — guide user with step animations.
    _sourceCountPulse.repeat(reverse: true);
    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _sourceCountPulse.stop();
      _sourceCountPulse.value = 0;
      if (sources.isNotEmpty) _sourceTypePulse.repeat(reverse: true);
    });
  }

  void _resetAnimations() {
    // Stop every pulse and reset to zero
    for (final c in [_templatePulse, _sourceCountPulse, _sourceTypePulse]) {
      c.stop();
      c.value = 0;
    }
    // Restart only dept pulse — user must pick dept again
    if (!_deptPulse.isAnimating) {
      _deptPulse.repeat(reverse: true);
    }
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
    // Detect canvas clear and reset sidebar animations/state
    final ctrl = context.watch<PipelineController>();
    if (ctrl.canvasVersion != _lastCanvasVersion) {
      _lastCanvasVersion = ctrl.canvasVersion;
      // Dynamic UniMailing: canvas version changes both during sequential key
      // configuration AND when the user switches between saved keys for review.
      // In both cases we must NOT reset the sidebar — instead reload source
      // types for whichever key is now selected.
      final isDynUniCanvasChange =
          ctrl.isDynamicUniMailing && ctrl.selectedOutputKey.isNotEmpty;
      if (isDynUniCanvasChange) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Stop all step animations when viewing an already-configured key —
          // they are only meant to guide first-time setup.
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
      } else {
        // Non-dynamic or no key selected: full sidebar reset.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resetAnimations();
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
          final canAdd = ctrl.canAddSource;

          // Sync source type pulse with canvas count
          if (ctrl.sidebarTemplate.isNotEmpty && ctrl.requiredSourceCount > 0) {
            final filled = ctrl.sourceNodesOnCanvas >= ctrl.requiredSourceCount;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (filled && _sourceTypePulse.isAnimating) {
                // All sources added → stop
                _sourceTypePulse.stop();
                _sourceTypePulse.value = 0;
              } else if (!filled && !_sourceTypePulse.isAnimating) {
                // Node deleted, count dropped → restart
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

                    // Department
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

                    // Template
                    StepHighlight(
                      animation: _templateAnim,
                      color: AppColors.blue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TEMPLATE',
                            style: AppTextStyles.sectionLabel,
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
                                    if (v == null) return;
                                    _onTemplateSelected(v, ctrl);
                                  },
                                ),
                        ],
                      ),
                    ),

                    // Template type + output format indicator
                    if (ctrl.sidebarTemplate.isNotEmpty &&
                        ctrl.templateType.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      TemplateConfigBadge(
                        templateType: ctrl.templateType,
                        outputFormats: ctrl.outputFormats,
                      ),
                    ],

                    // Output Key selector (Dynamic + UniMailing)
                    if (ctrl.sidebarTemplate.isNotEmpty &&
                        ctrl.isDynamicUniMailing) ...[
                      const SizedBox(height: 8),
                      OutputKeySelector(
                        ctrl: ctrl,
                        onOutputKeySelected: _onOutputKeySelected,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Required count
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

                    // Source counter badge
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
                              return Column(
                                children: _filteredSourceTypes
                                    .map(
                                      (st) => DynamicPaletteItem(
                                        sourceItem: st,
                                        enabled:
                                            canAdd &&
                                            ctrl.requiredSourceCount > 0,
                                      ),
                                    )
                                    .toList(),
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
                      '1. Select Department → Template\n2. Required sources auto-fills\n3. Drag source types to canvas\n4. Connect via ports → Join',
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
    // Dynamic+UniMailing: sourceCount is 0 until an output key is selected — not an error
    final isDynUni = ctrl.isDynamicUniMailing;
    // Template selected but sourceCount is 0 — not configured (only for non-dynamic)
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 14),
            const SizedBox(width: 6),
            const Expanded(
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
                  textAlign: TextAlign.center,
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

// Sidebar palette item — Draggable to canvas
class PaletteItem extends StatelessWidget {
  final NodeType type;
  final bool enabled;
  const PaletteItem({super.key, required this.type, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = type.color;

    Widget content() => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface2,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(type.icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type.subtitle,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Opacity(opacity: 0.3, child: content());
    }

    return Draggable<DragNodeData>(
      data: DragNodeData(type),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.blue),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: content()),
      child: content(),
    );
  }
}

NodeType _sourceTypeToNodeType(int? sourceType) {
  switch (sourceType) {
    case 1:
      return NodeType.manual;
    case 2:
      return NodeType.db; // QRS
    case 3:
      return NodeType.fc;
    default:
      return NodeType.db;
  }
}

// Dynamic palette item driven by API source type data
class DynamicPaletteItem extends StatelessWidget {
  final SourceMasterFilterItem sourceItem;
  final bool enabled;
  const DynamicPaletteItem({
    required this.sourceItem,
    required this.enabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final nodeType = _sourceTypeToNodeType(sourceItem.sourceType);
    final color = nodeType.color;

    Widget content() => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface2,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(nodeType.icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sourceItem.name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sourceItem.sourceTypeLabel.isNotEmpty)
                  Text(
                    sourceItem.sourceTypeLabel,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!enabled) return Opacity(opacity: 0.3, child: content());

    return Draggable<DragNodeData>(
      data: DragNodeData(
        nodeType,
        sourceValue: sourceItem.sourceTypeLabel,
        sourceName: sourceItem.name,
        sourceTypeId: sourceItem.id,
      ),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.blue),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(nodeType.icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                sourceItem.name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: content()),
      child: content(),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIG PANEL (same as HTML .right-panel)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
