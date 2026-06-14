import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/report_item.dart';
import 'package:vizualizer/data/models/template_info.dart';
import 'package:vizualizer/presentation/providers/auth_provider.dart';
import 'package:vizualizer/data/services/master_data_service.dart';
import 'package:vizualizer/core/utils/download_helper.dart';
import 'package:vizualizer/presentation/widgets/common/data_result_table.dart';
import 'package:vizualizer/presentation/widgets/common/select_dropdown_overlay.dart';
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
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
  List<ReportItem> _results = [];
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
    'Request ID',
    'Template ID',
    'Template Name',
    'Checker By',
    'Checker Date',
    'Maker By',
    'Maker Date',
    'Download',
  ];

  static const _columnWidths = {
    0: FixedColumnWidth(44),
    1: FlexColumnWidth(1.4),
    2: FlexColumnWidth(1.2),
    3: FlexColumnWidth(2.0),
    4: FlexColumnWidth(1.3),
    5: FlexColumnWidth(1.5),
    6: FlexColumnWidth(1.3),
    7: FlexColumnWidth(1.5),
    8: FixedColumnWidth(90),
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
    final deptId = _deptMap[_selectedDept!]!;
    setState(() {
      _fetching = true;
      _results = [];
      _fetched = false;
    });
    final results = await context.read<MasterDataService>().getReportList(
      templateId: '${_selectedTemplate!.templateId}',
      departmentId: '$deptId',
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
            DataResultTable<ReportItem>(
              items: _results,
              columns: _columns,
              columnWidths: _columnWidths,
              emptyMessage: 'No records found for the selected template.',
              searchFilter: (item, q) =>
                  item.requestId.toLowerCase().contains(q) ||
                  item.templateId.toLowerCase().contains(q) ||
                  item.templateName.toLowerCase().contains(q) ||
                  item.checkerBy.toLowerCase().contains(q) ||
                  formatTableDate(item.checkerDate).toLowerCase().contains(q) ||
                  item.makerBy.toLowerCase().contains(q) ||
                  item.filename.toLowerCase().contains(q) ||
                  formatTableDate(item.makerDate).toLowerCase().contains(q),
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
                AppColors.blue.withValues(alpha: 0.18),
                AppColors.blue.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            color: AppColors.blue,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'View upload history and status for manual data submissions',
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
                      'Fetch Report',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.blue.withValues(
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

  Set<String> _matchedColumns(List<ReportItem> items, String query) {
    if (query.isEmpty) return {};
    final q = query.toLowerCase();
    final matched = <String>{};
    for (final item in items) {
      if (item.requestId.toLowerCase().contains(q)) matched.add('Request ID');
      if (item.templateId.toLowerCase().contains(q)) matched.add('Template ID');
      if (item.templateName.toLowerCase().contains(q)) matched.add('Template Name');
      if (item.checkerBy.toLowerCase().contains(q)) matched.add('Checker By');
      if (formatTableDate(item.checkerDate).toLowerCase().contains(q)) {
        matched.add('Checker Date');
      }
      if (item.makerBy.toLowerCase().contains(q)) matched.add('Maker By');
      if (formatTableDate(item.makerDate).toLowerCase().contains(q)) {
        matched.add('Maker Date');
      }
      if (item.filename.toLowerCase().contains(q)) matched.add('Download');
    }
    return matched;
  }

  TableRow _buildTableRow(ReportItem item, int index) {
    final filename = item.filename.isEmpty ? '—' : item.filename;
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    final extColor = _extColor(ext);
    final makerBy = item.makerBy.isEmpty ? '—' : item.makerBy;
    final checkerBy = item.checkerBy.isEmpty ? '—' : item.checkerBy;
    final bg = index.isEven ? Colors.white : const Color(0xFFF9FAFC);

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

        // Request ID
        DataResultTable.tdCell(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.blue.withValues(alpha: 0.09),
            ),
            child: Text(
              item.requestId.isEmpty ? '—' : item.requestId,
              style: const TextStyle(
                fontSize: 11,
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
            item.templateId.isEmpty ? '—' : item.templateId,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textDim,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Template Name
        DataResultTable.tdCell(
          child: Text(
            item.templateName.isEmpty ? '—' : item.templateName,
            style: const TextStyle(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Checker By
        DataResultTable.tdCell(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    checkerBy.isNotEmpty && checkerBy != '—'
                        ? checkerBy[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  checkerBy,
                  style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Checker Date
        DataResultTable.tdCell(
          child: Text(
            item.checkerDate.isEmpty ? '—' : formatTableDate(item.checkerDate),
            style: const TextStyle(fontSize: 11, color: AppColors.textDim),
          ),
        ),

        // Maker By
        DataResultTable.tdCell(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blue.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    makerBy.isNotEmpty && makerBy != '—'
                        ? makerBy[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  makerBy,
                  style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Maker Date
        DataResultTable.tdCell(
          child: Text(
            formatTableDate(item.makerDate),
            style: const TextStyle(fontSize: 11, color: AppColors.textDim),
          ),
        ),

        // Download
        DataResultTable.tdCell(
          child: Tooltip(
            message: 'Download $filename',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => downloadCheckerFile(
                context: context,
                filename: item.filename,
                templateId: item.templateId.isNotEmpty
                    ? item.templateId
                    : _selectedTemplate?.templateId.toString() ?? '',
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.blue.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: extColor.withValues(alpha: 0.15),
                      ),
                      child: Text(
                        ext.isEmpty ? 'FILE' : ext.toUpperCase(),
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: extColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.download_rounded,
                      size: 13,
                      color: AppColors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Color _extColor(String ext) {
    switch (ext) {
      case 'csv':
        return AppColors.green;
      case 'xlsx':
      case 'xls':
        return AppColors.blue;
      case 'json':
        return AppColors.amber;
      default:
        return AppColors.slate;
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
