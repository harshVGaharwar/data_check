import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../models/master_models.dart';
import '../models/template_info.dart';
import '../controllers/pipeline_controller.dart';
import '../providers/auth_provider.dart';
import '../providers/pipeline_master_provider.dart';
import '../services/master_data_service.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  // dept name → dept id
  Map<String, int> _deptMap = {};
  bool _deptLoading = true;

  List<TemplateInfo> _templates = [];
  bool _templateLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
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
    final templates = await service.getTemplatesByDept(deptId);
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _templateLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.surface,
      child: Consumer<PipelineController>(
        builder: (context, ctrl, _) {
          final deptNames = _deptMap.keys.toList();
          final templateNames = _templates.map((t) => t.templateName).toList();
          final canAdd = ctrl.canAddSource;

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: const Text(
                  'PIPELINE CONFIG',
                  style: AppTextStyles.sectionLabel,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    const Text(
                      'TEMPLATE SELECTION',
                      style: AppTextStyles.sectionLabel,
                    ),
                    const SizedBox(height: 6),

                    // Department
                    const Text('Department', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 4),
                    _deptLoading
                        ? _loadingField()
                        : _sidebarDropdown(
                            value: ctrl.sidebarDept.isEmpty
                                ? null
                                : ctrl.sidebarDept,
                            hint: '— Select Dept —',
                            items: deptNames,
                            onChanged: (v) {
                              if (v != null) _onDeptSelected(v, ctrl);
                            },
                          ),
                    const SizedBox(height: 8),

                    // Template
                    const Text('Template', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 4),
                    _templateLoading
                        ? _loadingField()
                        : _sidebarDropdown(
                            value: templateNames.contains(ctrl.sidebarTemplate)
                                ? ctrl.sidebarTemplate
                                : null,
                            hint: ctrl.sidebarDept.isEmpty
                                ? '— Select Dept first —'
                                : '— Select Template —',
                            items: templateNames,
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
                              ctrl.setSidebarTemplate(
                                v,
                                sourceCount: info.sourceCount > 0
                                    ? info.sourceCount
                                    : null,
                                templateId: info.templateId,
                              );
                            },
                          ),
                    const SizedBox(height: 8),

                    // Required count
                    const Text(
                      'Required Input Sources',
                      style: AppTextStyles.fieldLabel,
                    ),
                    const SizedBox(height: 4),
                    _buildRequiredSourcesBox(ctrl),

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
                                ? AppColors.green.withOpacity(0.3)
                                : AppColors.amber.withOpacity(0.3),
                          ),
                          color:
                              ctrl.sourceNodesOnCanvas >=
                                  ctrl.requiredSourceCount
                              ? AppColors.green.withOpacity(0.06)
                              : AppColors.amber.withOpacity(0.06),
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
                    const Text(
                      'SOURCE TYPES',
                      style: AppTextStyles.sectionLabel,
                    ),
                    const SizedBox(height: 6),
                    Consumer<PipelineMasterProvider>(
                      builder: (_, master, __) {
                        if (master.loading) return _loadingField();
                        if (master.sourceTypes.isEmpty) {
                          return const Text(
                            'No source types',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          );
                        }
                        return Column(
                          children: master.sourceTypes
                              .map(
                                (st) => DynamicPaletteItem(
                                  sourceItem: st,
                                  enabled:
                                      canAdd && ctrl.requiredSourceCount > 0,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    const Text('OPERATIONS', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 6),
                    PaletteItem(type: NodeType.join, enabled: true),

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
    // Template selected but sourceCount is 0 — not configured
    if (ctrl.sidebarTemplate.isNotEmpty && ctrl.requiredSourceCount == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFE53935).withOpacity(0.4)),
          color: const Color(0xFFE53935).withOpacity(0.05),
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
      child: Text(
        ctrl.requiredSourceCount > 0
            ? '${ctrl.requiredSourceCount}'
            : 'Select template first',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ctrl.requiredSourceCount > 0
              ? AppColors.amber
              : AppColors.textMuted,
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

  Widget _sidebarDropdown({
    String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border2),
        color: AppColors.surface2,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : null,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          dropdownColor: AppColors.surface2,
          style: const TextStyle(fontSize: 12, color: AppColors.text),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Sidebar palette item — Draggable to canvas
class PaletteItem extends StatelessWidget {
  final NodeType type;
  final bool enabled;
  const PaletteItem({required this.type, required this.enabled});

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
              color: color.withOpacity(0.15),
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
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16),
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

NodeType _sourceValueToNodeType(String sourceValue) {
  switch (sourceValue.toUpperCase()) {
    case 'DB':
    case 'QRS':
      return NodeType.db;
    case 'MANUAL':
      return NodeType.manual;
    case 'FC':
      return NodeType.fc;
    case 'LASER':
      return NodeType.laser;
    default:
      return NodeType.db;
  }
}

// Dynamic palette item driven by API source type data
class DynamicPaletteItem extends StatelessWidget {
  final SourceTypeItem sourceItem;
  final bool enabled;
  const DynamicPaletteItem({
    required this.sourceItem,
    required this.enabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final nodeType = _sourceValueToNodeType(sourceItem.sourceValue);
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
              color: color.withOpacity(0.15),
            ),
            child: Icon(nodeType.icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sourceItem.sourceName,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sourceItem.sourceValue,
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
        sourceValue: sourceItem.sourceValue,
        sourceName: sourceItem.sourceName,
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
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(nodeType.icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                sourceItem.sourceName,
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
