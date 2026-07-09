// NEW REPORT PAGE 

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/new_report_item.dart';
import 'package:vizualizer/data/models/template_info.dart';
import 'package:vizualizer/data/services/storage_service.dart';
import 'package:vizualizer/presentation/providers/auth_provider.dart';
import 'package:vizualizer/data/services/master_data_service.dart';
import 'package:vizualizer/core/utils/download_helper.dart';
import 'package:vizualizer/presentation/widgets/common/data_result_table.dart';
import 'package:vizualizer/presentation/widgets/common/select_dropdown_overlay.dart';

class NewReportPage extends StatefulWidget {
  const NewReportPage({super.key});

  @override
  State<NewReportPage> createState() => New_ReportPageState();
}

class New_ReportPageState extends State<NewReportPage> {
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
  List<NewReportItem> _results = [];
  bool _fetching = false;
  bool _fetched = false;

  // ── overlay links ─────────────────────────────────────────────────────────
  final _deptLayerLink = LayerLink();
  final _templateLayerLink = LayerLink();
  OverlayEntry? _deptOverlay;
  OverlayEntry? _templateOverlay;

  DateTime? _fromDate;
  DateTime? _toDate;

  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();

  // ── columns ───────────────────────────────────────────────────────────────

  static const _columns = [
    '#',
    'Run ID',
    'From Date',
    'To Date',
    'Maker By',
    'Checker By',
    'Status',
    'Download',
  ];

  static const _columnWidths = {
    0: FixedColumnWidth(44), // #
    1: FlexColumnWidth(1.4), // Run ID
    2: FlexColumnWidth(1.2), // From Date
    3: FlexColumnWidth(1.2), // To Date
    4: FlexColumnWidth(1.4), // Maker By
    5: FlexColumnWidth(1.4), // Checker By
    6: FlexColumnWidth(1.0), // Status
    7: FixedColumnWidth(90), // Download
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

  Future<void> _pickFromDate() async {
    final storageService = StorageService();
    final session = await storageService.loadSession();
    final int allowedDays = session?.user.reportDate.daycount ?? 0;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: allowedDays)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _fromDate = date;
        _fromDateController.text = _format(date);
        _toDate = null;
        _toDateController.clear();
      });
    }
  }

  Future<void> _pickToDate() async {
    if (_fromDate == null) {
      _snack("Please select From Date first.", isError: true);
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _fromDate!,
      firstDate: _fromDate!,
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _toDate = date;
        _toDateController.text = _format(date);
      });
    }
  }

  String _format(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
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
    final items =
        _deptMap.keys.map((k) => (id: _deptMap[k]!, label: k)).toList();
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
        .getManualTemplatesByDept(deptId, 20);
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _templateLoading = false;
      _templateError = templates.isEmpty;
    });
  }

  // Future<void> _fetch() async {
  //   if (_selectedDept == null) {
  //     _snack('Please select a department.', isError: true);
  //     return;
  //   }
  //   if (_selectedTemplate == null) {
  //     _snack('Please select a template.', isError: true);
  //     return;
  //   }
  //   final deptId = _deptMap[_selectedDept!]!;
  //   setState(() {
  //     _fetching = true;
  //     _results = [];
  //     _fetched = false;

  Future<void> _fetch() async {
    final auth = context.read<AuthProvider>();
    final checkerBy = auth.user?.user.employeeCode ?? '';
    if (_selectedDept == null) {
      _snack('Please select a department.', isError: true);
      return;
    }
    if (_selectedTemplate == null) {
      _snack('Please select a template.', isError: true);
      return;
    }
    if (_fromDate == null) {
      _snack('Please select From Date.', isError: true);
      return;
    }
    if (_toDate == null) {
      _snack('Please select To Date.', isError: true);
      return;
    }

    final deptId = _deptMap[_selectedDept!]!;
    setState(() {
      _fetching = true;
      _results = [];
      _fetched = false;
    });

    final results = await context.read<MasterDataService>().getNewReportList(
        templateId: '${_selectedTemplate!.templateId}',
        departmentId: '$deptId',
        fromDate: _format(_fromDate!),
        toDate: _format(_toDate!),
        createdBy: checkerBy);

    if (!mounted) return;
    setState(() {
      _results = results;
      _fetching = false;
      _fetched = true;
    });
  }
  //   });
  //   final results = await context.read<MasterDataService>().getReportList(
  //         templateId: '${_selectedTemplate!.templateId}',
  //         departmentId: '$deptId',
  //       );
  //   if (!mounted) return;
  //   setState(() {
  //     _results = results;
  //     _fetching = false;
  //     _fetched = true;
  //   });
  // }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
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
            DataResultTable<NewReportItem>(
              items: _results,
              columns: _columns,
              columnWidths: _columnWidths,
              emptyMessage:
                  'No records found for the selected template.', //TODO

              searchFilter: (item, q) {
                final query = q.trim();

                final lowerQuery = query.toLowerCase();

                final status =
                    (item.isFileReady?.toString().toUpperCase() == "Y")
                        ? "completed"
                        : "in-progress";

                return
                    // ✅ RunID is case-sensitive
                    item.runId.contains(query) ||

                        // ✅ All other fields lowercase search
                        item.fromDate.toLowerCase().contains(lowerQuery) ||
                        item.toDate.toLowerCase().contains(lowerQuery) ||
                        item.makerBy.toLowerCase().contains(lowerQuery) ||
                        item.checkerBy.toLowerCase().contains(lowerQuery) ||
                        status.contains(lowerQuery) ||
                        item.filename.toLowerCase().contains(lowerQuery);
              },
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
              'Data Fusion Output',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
            // SizedBox(height: 2),
            // Text(
            //   'View upload output for manual data submissions',
            //   style: TextStyle(
            //     fontSize: 12,
            //     color: AppColors.blue,
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
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

          // -------- ROW 1 : Department + Template + From Date + To Date ----------
          Row(
            children: [
              // Department
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Department *', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    _deptLoading
                        ? _loadingField()
                        : _deptError
                            ? _errorField(_loadDepartments)
                            : CompositedTransformTarget(
                                link: _deptLayerLink,
                                child: GestureDetector(
                                  onTap: () => _openDeptOverlay(320),
                                  child: _dropdownTrigger(
                                    value: _selectedDept,
                                    hint: '— Select Department —',
                                    isOpen: _deptOverlay != null,
                                  ),
                                ),
                              ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Template
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Template *', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    _templateLoading
                        ? _loadingField()
                        : _templateError
                            ? _errorField(() => _onDeptSelected(_selectedDept!))
                            : CompositedTransformTarget(
                                link: _templateLayerLink,
                                child: GestureDetector(
                                  onTap: (_selectedDept != null &&
                                          !_templateLoading)
                                      ? () => _openTemplateOverlay(320)
                                      : null,
                                  child: _dropdownTrigger(
                                    value: _selectedTemplate?.templateName,
                                    hint: _selectedDept == null
                                        ? '— Select Department first —'
                                        : '— Select Template —',
                                    isOpen: _templateOverlay != null,
                                    enabled: _selectedDept != null,
                                  ),
                                ),
                              ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // From Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("From Date *", style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickFromDate,
                      child: _dropdownTrigger(
                        value: _fromDateController.text.isNotEmpty
                            ? _fromDateController.text
                            : null,
                        hint: "Select From Date",
                        isOpen: false,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // To Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("To Date *", style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickToDate,
                      child: _dropdownTrigger(
                        value: _toDateController.text.isNotEmpty
                            ? _toDateController.text
                            : null,
                        hint: _fromDate == null
                            ? "Select From Date first"
                            : "Select To Date",
                        isOpen: false,
                        enabled: _fromDate != null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // -------- FETCH BUTTON (FULL WIDTH BELOW ROW) ----------
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _fetching ? null : _fetch,
                icon: const Icon(Icons.search_rounded,
                    size: 16, color: Colors.white),
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
                  disabledBackgroundColor:
                      AppColors.blue.withValues(alpha: 0.4),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ── table: column matcher & row builder ───────────────────────────────────

  Set<String> _matchedColumns(List<NewReportItem> items, String query) {
    if (query.isEmpty) return {};

    final q = query.trim();
    final lowerQ = q.toLowerCase();

    final matched = <String>{};

    for (final item in items) {
      final status = (item.isFileReady?.toString().toUpperCase() == "Y")
          ? "completed"
          : "in-progress";

      // ✅ Run ID case-sensitive
      if (item.runId.contains(q)) matched.add('Run ID');

      if (item.fromDate.toLowerCase().contains(lowerQ))
        matched.add('From Date');
      if (item.toDate.toLowerCase().contains(lowerQ)) matched.add('To Date');
      if (item.makerBy.toLowerCase().contains(lowerQ)) matched.add('Maker By');
      if (item.checkerBy.toLowerCase().contains(lowerQ))
        matched.add('Checker By');
      if (status.contains(lowerQ)) matched.add('Status');
      if (item.filename.toLowerCase().contains(lowerQ)) matched.add('Download');
    }

    return matched;
  }

  TableRow _buildTableRow(NewReportItem item, int index) {
    final bg = index.isEven ? Colors.white : const Color(0xFFF9FAFC);
    final filename = item.filename.isEmpty ? '—' : item.filename;
    final departmentId = item.departmentName;

    // Status conversion
    final isReady = (item.isFileReady?.toString().toUpperCase() == "Y");
    final statusText = isReady ? "Completed" : "In-Progress";
    final statusColor = isReady ? AppColors.green : AppColors.amber;

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

        // Run ID
        DataResultTable.tdCell(
          child: Text(
            item.runId,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
        ),

        // From Date
        DataResultTable.tdCell(
          child: Text(
            item.fromDate.isEmpty ? '—' : item.fromDate,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
        ),

        // To Date
        DataResultTable.tdCell(
          child: Text(
            item.toDate.isEmpty ? '—' : item.toDate,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
        ),

        // Maker By
        DataResultTable.tdCell(
          child: Text(
            item.makerBy.isEmpty ? '—' : item.makerBy,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
        ),

        // Checker By
        DataResultTable.tdCell(
          child: Text(
            item.checkerBy.isEmpty ? '—' : item.checkerBy,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
        ),

        // STATUS
        DataResultTable.tdCell(
          child: Text(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // DOWNLOAD
        DataResultTable.tdCell(
          child: Tooltip(
            message: isReady ? "Download: ${item.filename}" : "File not ready",
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isReady
                  ? () => downloadReportFile(
                        context: context,
                        filename: filename,
                        departmentId: departmentId,
                        templateId: item.templateId.isNotEmpty
                            ? item.templateId
                            : _selectedTemplate?.templateId.toString() ?? '',
                        requestId: item.requestId.isNotEmpty
                            ? item.requestId
                            : item.runId,
                      )
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isReady
                      ? AppColors.blue.withValues(alpha: 0.08)
                      : AppColors.slate.withValues(alpha: 0.10),
                  border: Border.all(
                    color: isReady
                        ? AppColors.blue.withValues(alpha: 0.18)
                        : AppColors.slate.withValues(alpha: 0.20),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.download_rounded,
                    size: 13,
                    color: isReady ? AppColors.blue : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
  }) =>
      Container(
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