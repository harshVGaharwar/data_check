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
import 'shimmer_button.dart';
import 'sidebar.dart' show DynamicPaletteItem;

class EditSidebar extends StatefulWidget {
  final Future<void> Function(int templateId, int deptId) onFetchConfig;
  const EditSidebar({super.key, required this.onFetchConfig});

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

  int? _selectedTemplateId;
  bool _fetching = false;
  bool _configLoaded = false;

  late final AnimationController _deptPulse;
  late final AnimationController _templatePulse;
  late final AnimationController _sourceCountPulse;
  late final Animation<double> _deptAnim;
  late final Animation<double> _templateAnim;
  late final Animation<double> _sourceCountAnim;

  int _lastClearVersion = 0;

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

    _loadDepartments();
  }

  @override
  void dispose() {
    _deptPulse.dispose();
    _templatePulse.dispose();
    _sourceCountPulse.dispose();
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
    ctrl.setSidebarDept(deptName, deptId: _deptMap[deptName]?.toString() ?? '');
    _deptPulse.stop();
    _deptPulse.value = 0;
    _templatePulse.repeat(reverse: true);
    setState(() {
      _templates = [];
      _templateLoading = true;
      _selectedTemplateId = null;
      _filteredSourceTypes = [];
      _sourceCountError = false;
      _configLoaded = false;
    });

    final deptId = _deptMap[deptName];
    if (deptId == null) {
      setState(() => _templateLoading = false);
      return;
    }

    final service = context.read<MasterDataService>();
    // Only approved+configured templates
    final templates = await service.getTemplatesByDept(deptId, 14);
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _templateLoading = false;
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
    for (final c in [_templatePulse, _sourceCountPulse]) {
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
      _selectedTemplateId = null;
      _fetching = false;
    });
  }

  Future<void> _onFetchTapped(PipelineController ctrl) async {
    final deptId = int.tryParse(ctrl.sidebarDeptId) ?? 0;
    final templateId = _selectedTemplateId ?? 0;
    if (deptId == 0 || templateId == 0) return;

    setState(() => _fetching = true);
    try {
      await widget.onFetchConfig(templateId, deptId);
      if (mounted) setState(() => _configLoaded = true);
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PipelineController>();

    if (ctrl.clearVersion != _lastClearVersion) {
      _lastClearVersion = ctrl.clearVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetAnimations();
      });
    }

    return Container(
      width: 220,
      color: AppColors.surface,
      child: Consumer<PipelineController>(
        builder: (context, ctrl, _) {
          final deptNames = _deptMap.keys.toList();
          final templateNames = _templates.map((t) => t.templateName).toList();

          final sourcesLoaded =
              _filteredSourceTypes.isNotEmpty && !_sourceTypesLoading;
          final canFetch =
              ctrl.sidebarDept.isNotEmpty &&
              ctrl.sidebarTemplate.isNotEmpty &&
              !_sourceCountError &&
              ctrl.requiredSourceCount > 0 &&
              sourcesLoaded &&
              !_fetching &&
              !_configLoaded;

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

                    // ── Template (approved only) ──
                    _StepHighlight(
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
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Approved',
                                  style: AppTextStyles.sectionLabel.copyWith(
                                    color: AppColors.green,
                                    fontSize: 8,
                                  ),
                                ),
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
                                    setState(() {
                                      _selectedTemplateId = info.templateId;
                                      _configLoaded = false;
                                    });

                                    final deptId = _deptMap[ctrl.sidebarDept];
                                    if (deptId != null && info.templateId > 0) {
                                      _loadFilteredSourceTypes(
                                        templateId: info.templateId.toString(),
                                        departmentId: deptId.toString(),
                                      );
                                    }

                                    _templatePulse.stop();
                                    _templatePulse.value = 0;

                                    if (info.sourceCount == 0) {
                                      setState(() => _sourceCountError = true);
                                      _sourceCountPulse.repeat(reverse: true);
                                    } else {
                                      setState(() => _sourceCountError = false);
                                      _sourceCountPulse.repeat(reverse: true);
                                      Timer(
                                        const Duration(milliseconds: 1000),
                                        () {
                                          if (!mounted) return;
                                          _sourceCountPulse.stop();
                                          _sourceCountPulse.value = 0;
                                        },
                                      );
                                    }
                                  },
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Source Count ──
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
                            color: AppColors.green.withValues(alpha: 0.3),
                          ),
                          color: AppColors.green.withValues(alpha: 0.06),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Required Sources',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${ctrl.requiredSourceCount}',
                              style: const TextStyle(
                                color: AppColors.green,
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
                    Column(
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
                            final canAdd =
                                _configLoaded &&
                                ctrl.canAddSource &&
                                ctrl.requiredSourceCount > 0;
                            return Column(
                              children: _filteredSourceTypes
                                  .map(
                                    (st) => DynamicPaletteItem(
                                      sourceItem: st,
                                      enabled: canAdd,
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Operations ──
                    const Text('OPERATIONS', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 6),
                    _JoinPaletteItem(ctrl: ctrl),

                    const SizedBox(height: 16),

                    // ── Load Configuration button ──
                    if (_fetching)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.blue.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.blue,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Loading…',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ShimmerButton(
                          label: 'Load Configuration',
                          icon: Icons.cloud_download_outlined,
                          color: AppColors.blue,
                          animating: canFetch,
                          onTap: canFetch ? () => _onFetchTapped(ctrl) : null,
                        ),
                      ),

                    const SizedBox(height: 12),
                    const Text(
                      'INSTRUCTIONS',
                      style: AppTextStyles.sectionLabel,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '1. Select Dept → Approved Template\n2. Verify source count & types\n3. Tap Load Configuration\n4. Edit nodes, then re-submit',
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
    if (ctrl.sidebarTemplate.isNotEmpty && ctrl.requiredSourceCount == 0) {
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

// ── Join palette item (same as Sidebar) ──
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
    if (widget.ctrl.shouldAnimateJoin) _pulseCtrl.repeat(reverse: true);
  }

  void _syncAnimation(bool shouldAnimate) {
    if (shouldAnimate && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!shouldAnimate && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
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

// ── Step highlight (identical to Sidebar's version) ──
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
