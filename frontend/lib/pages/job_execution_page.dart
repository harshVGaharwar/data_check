import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/job_execution_log.dart';
import '../models/template_info.dart';
import '../providers/auth_provider.dart';
import '../services/master_data_service.dart';
import '../widgets/data_result_table.dart';
import '../widgets/select_dropdown_overlay.dart';

class JobExecutionPage extends StatefulWidget {
  const JobExecutionPage({super.key});

  @override
  State<JobExecutionPage> createState() => _JobExecutionPageState();
}

class _JobExecutionPageState extends State<JobExecutionPage> {
  // ── filter state ──────────────────────────────────────────────────────────
  Map<String, int> _deptMap = {};
  bool _deptLoading = true;
  bool _deptError = false;

  List<ManualTemplateInfo> _templates = [];
  bool _templateLoading = false;
  bool _templateError = false;

  String? _selectedDept;
  ManualTemplateInfo? _selectedTemplate;

  // ── results state ─────────────────────────────────────────────────────────
  List<JobExecutionLog> _results = [];
  bool _fetching = false;
  bool _fetched = false;

  // ── overlay links ─────────────────────────────────────────────────────────
  final _deptLayerLink = LayerLink();
  final _templateLayerLink = LayerLink();
  OverlayEntry? _deptOverlay;
  OverlayEntry? _templateOverlay;

  // ── columns ───────────────────────────────────────────────────────────────
  static const _columns = [
    '#',
    'Job Name',
    'Run ID',
    'Template ID',
    'Department',
    'Start Time',
    'Last Updated',
    'Status',
    'Message',
  ];

  static const _columnWidths = {
    0: FixedColumnWidth(44),
    1: FlexColumnWidth(1.8),
    2: FlexColumnWidth(1.6),
    3: FlexColumnWidth(1.2),
    4: FlexColumnWidth(1.4),
    5: FlexColumnWidth(1.6),
    6: FlexColumnWidth(1.6),
    7: FixedColumnWidth(110),
    8: FlexColumnWidth(2.2),
  };

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _deptOverlay?.remove();
    _templateOverlay?.remove();
    super.dispose();
  }

  // ── overlay helpers ───────────────────────────────────────────────────────

  void _closeDeptOverlay() {
    _deptOverlay?.remove();
    _deptOverlay = null;
    if (mounted) setState(() {});
  }

  void _closeTemplateOverlay() {
    _templateOverlay?.remove();
    _templateOverlay = null;
    if (mounted) setState(() {});
  }

  void _openDeptOverlay(double width) {
    _closeDeptOverlay();
    final items = _deptMap.keys
        .map((k) => (id: _deptMap[k]!, label: k))
        .toList();
    _deptOverlay = OverlayEntry(
      builder: (_) => SelectDropdownOverlay(
        layerLink: _deptLayerLink,
        items: items,
        selectedId: _selectedDept != null ? _deptMap[_selectedDept] : null,
        dropdownWidth: width,
        searchHint: 'Search department...',
        onDismiss: _closeDeptOverlay,
        onSelect: (id, label) {
          _closeDeptOverlay();
          _onDeptSelected(label);
        },
      ),
    );
    Overlay.of(context).insert(_deptOverlay!);
    setState(() {});
  }

  void _openTemplateOverlay(double width) {
    _closeTemplateOverlay();
    final items = _templates
        .asMap()
        .entries
        .map((e) => (id: e.key, label: e.value.templateName))
        .toList();
    _templateOverlay = OverlayEntry(
      builder: (_) => SelectDropdownOverlay(
        layerLink: _templateLayerLink,
        items: items,
        selectedId: _selectedTemplate != null
            ? _templates.indexOf(_selectedTemplate!)
            : null,
        dropdownWidth: width,
        searchHint: 'Search template...',
        onDismiss: _closeTemplateOverlay,
        onSelect: (id, label) {
          _closeTemplateOverlay();
          setState(() {
            _selectedTemplate = _templates[id];
            _results = [];
            _fetched = false;
          });
        },
      ),
    );
    Overlay.of(context).insert(_templateOverlay!);
    setState(() {});
  }

  // ── data loading ──────────────────────────────────────────────────────────

  Future<void> _loadDepartments() async {
    setState(() {
      _deptLoading = true;
      _deptError = false;
    });
    final auth = context.read<AuthProvider>();
    if (!auth.initialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return mounted && !context.read<AuthProvider>().initialized;
      });
    }
    if (!mounted) return;
    final map = await context.read<MasterDataService>().getDepartmentMap();
    if (!mounted) return;
    setState(() {
      _deptMap = map;
      _deptLoading = false;
      _deptError = map.isEmpty;
    });
  }

  Future<void> _onDeptSelected(String dept) async {
    setState(() {
      _selectedDept = dept;
      _selectedTemplate = null;
      _templates = [];
      _templateLoading = true;
      _templateError = false;
      _results = [];
      _fetched = false;
    });
    final deptId = _deptMap[dept];
    if (deptId == null) {
      setState(() => _templateLoading = false);
      return;
    }
    final templates = await context
        .read<MasterDataService>()
        .getManualTemplatesByDept(deptId);
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _templateLoading = false;
      _templateError = templates.isEmpty;
    });
  }

  Future<void> _fetch() async {
    if (_selectedDept == null) {
      _snack('Please select a department.', isError: true);
      return;
    }
    if (_selectedTemplate == null) {
      _snack('Please select a template.', isError: true);
      return;
    }
    setState(() {
      _fetching = true;
      _results = [];
      _fetched = false;
    });
    final results = await context.read<MasterDataService>().getJobExecutionLog(
      templateId: '${_selectedTemplate!.templateId}',
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _fetching = false;
      _fetched = true;
    });
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildFilterCard(),
          if (_fetching) ...[
            const SizedBox(height: 40),
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.blue,
              ),
            ),
          ] else if (_fetched) ...[
            const SizedBox(height: 20),
            DataResultTable<JobExecutionLog>(
              items: _results,
              columns: _columns,
              columnWidths: _columnWidths,
              emptyMessage:
                  'No execution logs found for the selected template.',
              searchFilter: (item, q) =>
                  item.jobName.toLowerCase().contains(q) ||
                  item.runId.toLowerCase().contains(q) ||
                  '${item.templateId}'.contains(q) ||
                  item.deptName.toLowerCase().contains(q) ||
                  item.status.toLowerCase().contains(q) ||
                  item.message.toLowerCase().contains(q) ||
                  formatTableDate(item.startTime).toLowerCase().contains(q) ||
                  formatTableDate(item.lastUpdated).toLowerCase().contains(q),
              columnMatcher: _matchedColumns,
              rowBuilder: _buildTableRow,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                AppColors.violet.withValues(alpha: 0.18),
                AppColors.violet.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.violet.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            Icons.play_circle_outline_rounded,
            color: AppColors.violet,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Execution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Track job run history and execution status for templates',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── filter card ───────────────────────────────────────────────────────────

  Widget _buildFilterCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Department', style: AppTextStyles.fieldLabel),
                        const SizedBox(height: 6),
                        _deptLoading
                            ? _loadingField()
                            : _deptError
                            ? _errorField(_loadDepartments)
                            : CompositedTransformTarget(
                                link: _deptLayerLink,
                                child: GestureDetector(
                                  onTap: () =>
                                      _openDeptOverlay(constraints.maxWidth),
                                  child: _dropdownTrigger(
                                    value: _selectedDept,
                                    hint: '— Select Department —',
                                    isOpen: _deptOverlay != null,
                                  ),
                                ),
                              ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final enabled = _selectedDept != null && !_templateLoading;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Template', style: AppTextStyles.fieldLabel),
                        const SizedBox(height: 6),
                        _templateLoading
                            ? _loadingField()
                            : _templateError
                            ? _errorField(() => _onDeptSelected(_selectedDept!))
                            : CompositedTransformTarget(
                                link: _templateLayerLink,
                                child: GestureDetector(
                                  onTap: enabled
                                      ? () => _openTemplateOverlay(
                                          constraints.maxWidth,
                                        )
                                      : null,
                                  child: _dropdownTrigger(
                                    value: _selectedTemplate?.templateName,
                                    hint: _selectedDept == null
                                        ? '— Select Department first —'
                                        : '— Select Template —',
                                    isOpen: _templateOverlay != null,
                                    enabled: enabled,
                                  ),
                                ),
                              ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _fetching ? null : _fetch,
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: const Text(
                      'Fetch Logs',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.violet,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.violet.withValues(
                        alpha: 0.4,
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── table: column matcher & row builder ───────────────────────────────────

  Set<String> _matchedColumns(List<JobExecutionLog> items, String query) {
    if (query.isEmpty) return {};
    final q = query.toLowerCase();
    final matched = <String>{};
    for (final item in items) {
      if (item.jobName.toLowerCase().contains(q)) matched.add('Job Name');
      if (item.runId.toLowerCase().contains(q)) matched.add('Run ID');
      if ('${item.templateId}'.contains(q)) matched.add('Template ID');
      if (item.deptName.toLowerCase().contains(q)) matched.add('Department');
      if (formatTableDate(item.startTime).toLowerCase().contains(q))
        matched.add('Start Time');
      if (formatTableDate(item.lastUpdated).toLowerCase().contains(q))
        matched.add('Last Updated');
      if (item.status.toLowerCase().contains(q)) matched.add('Status');
      if (item.message.toLowerCase().contains(q)) matched.add('Message');
    }
    return matched;
  }

  TableRow _buildTableRow(JobExecutionLog item, int index) {
    final bg = index.isEven ? Colors.white : const Color(0xFFF9FAFC);
    final statusColor = _statusColor(item.status);
    final statusLabel = _statusLabel(item.status);

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        // #
        DataResultTable.tdCell(
          child: Text(
            '${index + 1}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Job Name
        DataResultTable.tdCell(
          child: Text(
            item.jobName.isEmpty ? '—' : item.jobName,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Run ID
        DataResultTable.tdCell(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.blue.withValues(alpha: 0.09),
            ),
            child: Text(
              item.runId.isEmpty ? '—' : item.runId,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.blue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Template ID
        DataResultTable.tdCell(
          child: Text(
            '${item.templateId}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textDim,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Department
        DataResultTable.tdCell(
          child: Text(
            item.deptName.isEmpty ? '—' : item.deptName,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Start Time
        DataResultTable.tdCell(
          child: Text(
            formatTableDate(item.startTime),
            style: const TextStyle(fontSize: 11, color: AppColors.textDim),
          ),
        ),

        // Last Updated
        DataResultTable.tdCell(
          child: Text(
            formatTableDate(item.lastUpdated),
            style: const TextStyle(fontSize: 11, color: AppColors.textDim),
          ),
        ),

        // Status
        DataResultTable.tdCell(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: statusColor.withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    statusLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Message
        DataResultTable.tdCell(
          child: Text(
            item.message.isEmpty ? '—' : item.message,
            style: const TextStyle(fontSize: 11, color: AppColors.textDim),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  // ── status helpers ────────────────────────────────────────────────────────

  String _statusLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'SUCCESS':
      case 'COMPLETED':
        return 'Success';
      case 'FAILED':
      case 'ERROR':
        return 'Failed';
      case 'PENDING':
        return 'Pending';
      default:
        return raw.isEmpty ? 'Unknown' : raw;
    }
  }

  Color _statusColor(String raw) {
    switch (raw.toUpperCase()) {
      case 'IN_PROGRESS':
        return AppColors.amber;
      case 'SUCCESS':
      case 'COMPLETED':
        return AppColors.green;
      case 'FAILED':
      case 'ERROR':
        return AppColors.red;
      case 'PENDING':
        return AppColors.blue;
      default:
        return AppColors.textDim;
    }
  }

  // ── filter card helpers ───────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _dropdownTrigger({
    required String? value,
    required String hint,
    required bool isOpen,
    bool enabled = true,
  }) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isOpen
            ? AppColors.violet
            : enabled
            ? AppColors.border2
            : AppColors.border,
      ),
      color: enabled ? AppColors.surface : AppColors.bg,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            value ?? hint,
            style: TextStyle(
              fontSize: 13,
              color: value != null ? AppColors.text : AppColors.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          isOpen
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: enabled ? AppColors.textDim : AppColors.textMuted,
        ),
      ],
    ),
  );

  Widget _errorField(VoidCallback onRetry) => GestureDetector(
    onTap: onRetry,
    child: Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
        color: AppColors.red.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 14, color: AppColors.red),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Failed to load. Tap to retry',
              style: TextStyle(fontSize: 12, color: AppColors.red),
            ),
          ),
          Icon(Icons.refresh_rounded, size: 14, color: AppColors.red),
        ],
      ),
    ),
  );

  Widget _loadingField() => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
      color: AppColors.bg,
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
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}
