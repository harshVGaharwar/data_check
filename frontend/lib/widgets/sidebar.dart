import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../models/master_models.dart';
import '../models/template_info.dart';
import '../controllers/pipeline_controller.dart';
import '../providers/auth_provider.dart';
import '../services/master_data_service.dart';
import 'searchable_dropdown.dart';

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

    // Pulse source count briefly, then hand off to source type pulse
    _sourceCountPulse.repeat(reverse: true);
    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _sourceCountPulse.stop();
      _sourceCountPulse.value = 0;
      if (sources.isNotEmpty) _sourceTypePulse.repeat(reverse: true);
    });
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
      // Skip sidebar reset while Dynamic UniMailing output key configuration
      // is in progress — canvas clears between keys but the sidebar must
      // keep its dept/template/source-type state intact until all keys are done.
      final midOutputKeyFlow =
          ctrl.isDynamicUniMailing && !ctrl.allDynamicUniMailingKeysConfigured;
      if (!midOutputKeyFlow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resetAnimations();
        });
      } else {
        // Between output keys: ensure source types are loaded so the user
        // can drag nodes for the next key without re-selecting the template.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_filteredSourceTypes.isEmpty &&
              ctrl.sidebarTemplateId > 0 &&
              ctrl.sidebarDeptId.isNotEmpty) {
            _loadFilteredSourceTypes(
              templateId: ctrl.sidebarTemplateId.toString(),
              departmentId: ctrl.sidebarDeptId,
            );
          }
          // Restart source-type pulse so the user sees they need to drag sources.
          if (!_sourceTypePulse.isAnimating) {
            _sourceTypePulse.repeat(reverse: true);
          }
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
                    _StepHighlight(
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
                    _StepHighlight(
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
                                    final dynSourceCount = int.tryParse(
                                            dynEntry0?['sourceCount']?.toString() ?? '') ??
                                        0;
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

                                    // Template done → stop template pulse
                                    _templatePulse.stop();
                                    _templatePulse.value = 0;

                                    // Dynamic + UniMailing: sources come from output-key
                                    // selection, NOT from a separate API call.
                                    final isDynUni =
                                        (info.templateType == '3' ||
                                            info.templateType
                                                .toLowerCase()
                                                .contains('dynamic')) &&
                                        info.outputFormats.any(
                                          (f) => f.toLowerCase().contains(
                                            'unimailing',
                                          ),
                                        );

                                    if (isDynUni) {
                                      // Clear any stale source types; user must pick an output key
                                      setState(() {
                                        _sourceCountError = false;
                                        _filteredSourceTypes = [];
                                      });
                                      _sourceCountPulse.stop();
                                      _sourceCountPulse.value = 0;
                                      _sourceTypePulse.stop();
                                      _sourceTypePulse.value = 0;
                                    } else {
                                      // Static template (User Defined or UniMailing):
                                      // sourceMasterList and sourceCount come from
                                      // dynamicTemplate[0].
                                      final rawList = dynEntry0?['sourceMasterList'] as List?;
                                      final sources = rawList
                                              ?.whereType<Map<String, dynamic>>()
                                              .map(SourceMasterFilterItem.fromJson)
                                              .toList() ??
                                          [];
                                      if (dynEntry0 != null && dynSourceCount > 0) {
                                        ctrl.setOutputKeySourceCount(dynSourceCount);
                                        setState(() {
                                          _filteredSourceTypes = sources;
                                          _sourceCountError = false;
                                        });
                                      } else {
                                        setState(() {
                                          _filteredSourceTypes = sources;
                                          _sourceCountError = false;
                                        });
                                      }

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
                                  },
                                ),
                        ],
                      ),
                    ),

                    // Template type + output format indicator
                    if (ctrl.sidebarTemplate.isNotEmpty &&
                        ctrl.templateType.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _TemplateConfigBadge(
                        templateType: ctrl.templateType,
                        outputFormats: ctrl.outputFormats,
                      ),
                    ],

                    // Output Key selector (Dynamic + UniMailing)
                    if (ctrl.sidebarTemplate.isNotEmpty &&
                        ctrl.isDynamicUniMailing) ...[
                      const SizedBox(height: 8),
                      _OutputKeySelector(
                        ctrl: ctrl,
                        onOutputKeySelected: _onOutputKeySelected,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Required count
                    _StepHighlight(
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
                    _StepHighlight(
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
                    _JoinPaletteItem(ctrl: ctrl),

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
// JOIN PALETTE ITEM — locked until all source nodes are confirmed
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _JoinPaletteItem extends StatefulWidget {
  final PipelineController ctrl;
  const _JoinPaletteItem({required this.ctrl});

  @override
  State<_JoinPaletteItem> createState() => _JoinPaletteItemState();
}

class _JoinPaletteItemState extends State<_JoinPaletteItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  bool _lastUnlocked = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _lastUnlocked = widget.ctrl.shouldAnimateJoin;
    if (_lastUnlocked) _pulseCtrl.repeat(reverse: true);
  }

  /// Sync every build:
  /// - sources confirmed + no join on canvas → animate
  /// - join dropped on canvas → stop
  /// - join deleted from canvas → restart
  void _syncAnimation(bool shouldAnimate) {
    if (shouldAnimate && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!shouldAnimate && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
    _lastUnlocked = shouldAnimate;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.ctrl.allSourceNodesConfirmed;
    final shouldAnimate = widget.ctrl.shouldAnimateJoin;
    // Sync every build: join on canvas → stop, join deleted → restart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAnimation(shouldAnimate);
    });
    const type = NodeType.join;
    const color = AppColors.blue;

    Widget content({double glowAlpha = 0, double borderAlpha = 1}) => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unlocked
              ? color.withValues(alpha: 0.4 + borderAlpha * 0.6)
              : AppColors.border2,
          width: unlocked ? 1.8 : 1.0,
        ),
        color: unlocked
            ? color.withValues(alpha: 0.04 + glowAlpha * 0.08)
            : AppColors.surface2,
        boxShadow: unlocked && glowAlpha > 0
            ? [
                BoxShadow(
                  color: color.withValues(alpha: glowAlpha * 0.35),
                  blurRadius: 8 + glowAlpha * 10,
                  spreadRadius: glowAlpha * 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: color.withValues(
                alpha: unlocked ? 0.12 + glowAlpha * 0.1 : 0.07,
              ),
            ),
            child: Icon(
              unlocked ? type.icon : Icons.lock_outline_rounded,
              color: unlocked ? color : AppColors.textMuted,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    color: unlocked ? AppColors.text : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  unlocked ? '✦ Ready to drag' : 'Confirm all sources first',
                  style: TextStyle(
                    color: unlocked
                        ? color.withValues(alpha: 0.8)
                        : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Icon(
                Icons.arrow_forward_rounded,
                color: color.withValues(alpha: 0.4 + _pulseAnim.value * 0.6),
                size: 14,
              ),
            ),
        ],
      ),
    );

    if (!unlocked) {
      return GestureDetector(
        onTap: () {
          final sources = widget.ctrl.nodes
              .where((n) => n.type.isSource)
              .toList();
          final required = widget.ctrl.requiredSourceCount;
          final confirmed = sources
              .where((n) => n.confirmState == NodeConfirmState.confirmed)
              .length;
          final String msg;
          if (required > 0 && sources.length < required) {
            msg =
                'Add all $required required source nodes first'
                ' (${sources.length}/$required added).';
          } else {
            msg =
                'Configure all source nodes first'
                ' ($confirmed/${sources.length} confirmed).';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.orange),
          );
        },
        child: Opacity(opacity: 0.5, child: content()),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) => Draggable<DragNodeData>(
        data: DragNodeData(type),
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16),
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
        child: content(
          glowAlpha: _pulseAnim.value,
          borderAlpha: _pulseAnim.value,
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STEP HIGHLIGHT — animated glowing border + bg around a sidebar section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _StepHighlight extends AnimatedWidget {
  final Color color;
  final Widget child;

  const _StepHighlight({
    required Animation<double> animation,
    required this.color,
    required this.child,
  }) : super(listenable: animation);

  Animation<double> get _anim => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final t = _anim.value;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: t * 0.6), width: 1.5),
        boxShadow: t > 0.1
            ? [
                BoxShadow(
                  color: color.withValues(alpha: t * 0.25),
                  blurRadius: 6,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

// ── Template config badge ─────────────────────────────────────────────────────

class _TemplateConfigBadge extends StatelessWidget {
  final String templateType;
  final List<String> outputFormats;

  const _TemplateConfigBadge({
    required this.templateType,
    required this.outputFormats,
  });

  @override
  Widget build(BuildContext context) {
    final isStatic =
        templateType.toLowerCase().contains('static') ||
        templateType == '1' ||
        templateType == '2';
    final typeLabel = isStatic ? 'Static' : 'Dynamic';
    final typeColor = isStatic ? AppColors.green : AppColors.blue;
    final typeIcon = isStatic ? Icons.lock_outline_rounded : Icons.sync_rounded;

    final isUniMailing = outputFormats.any(
      (f) => f.toLowerCase().contains('unimailing'),
    );
    final isUserDefined = outputFormats.any(
      (f) => f.toLowerCase().replaceAll(' ', '').contains('userdefined'),
    );

    final formatLabel = isUniMailing
        ? 'UniMailing'
        : isUserDefined
        ? 'User Defined'
        : outputFormats.where((f) => f.isNotEmpty).join(', ');
    final formatColor = isUniMailing
        ? AppColors.amber
        : isUserDefined
        ? AppColors.violet
        : AppColors.textDim;
    final formatIcon = isUniMailing
        ? Icons.email_rounded
        : isUserDefined
        ? Icons.tune_rounded
        : Icons.description_rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        const Text('TEMPLATE CONFIG', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 5),

        // ── Info card ──
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Type row
              _ConfigRow(
                icon: typeIcon,
                header: 'Template Type',
                value: typeLabel,
                color: typeColor,
                isFirst: true,
              ),
              // Divider
              Divider(height: 1, color: AppColors.border),
              // Format row
              if (formatLabel.isNotEmpty)
                _ConfigRow(
                  icon: formatIcon,
                  header: 'Output Format',
                  value: formatLabel,
                  color: formatColor,
                  isLast: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final IconData icon;
  final String header;
  final String value;
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _ConfigRow({
    required this.icon,
    required this.header,
    required this.value,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(10) : Radius.zero,
          bottom: isLast ? const Radius.circular(10) : Radius.zero,
        ),
        color: color.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Output Key selector ───────────────────────────────────────────────────────

class _OutputKeySelector extends StatelessWidget {
  final PipelineController ctrl;
  final void Function(String key, PipelineController ctrl) onOutputKeySelected;

  const _OutputKeySelector({
    required this.ctrl,
    required this.onOutputKeySelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = ctrl.dynamicUniMailingOutputKeys;
    final selected = ctrl.selectedOutputKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('OUTPUT KEY', style: AppTextStyles.sectionLabel),
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SearchableDropdownField(
          value: (selected.isEmpty || !items.contains(selected))
              ? null
              : selected,
          hint: '— Select Output Key —',
          items: items,
          disabledItems: ctrl.savedOutputKeyConfigs.keys.toSet(),
          leadingBuilder: (item) {
            final isDone = ctrl.savedOutputKeyConfigs.containsKey(item);
            return Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 13,
              color: isDone ? AppColors.green : AppColors.textDim,
            );
          },
          onChanged: (v) {
            if (v == null) return;
            ctrl.setSelectedOutputKey(v);
            onOutputKeySelected(v, ctrl);
          },
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIG PANEL (same as HTML .right-panel)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
