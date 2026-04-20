import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/template_info.dart';
import '../providers/auth_provider.dart';
import '../services/master_data_service.dart';
import '../utils/file_download_stub.dart'
    if (dart.library.js_interop) '../utils/file_download_web.dart';

class CheckerPage extends StatefulWidget {
  const CheckerPage({super.key});

  @override
  State<CheckerPage> createState() => _CheckerPageState();
}

class _CheckerPageState extends State<CheckerPage> {
  // ── filter state ──────────────────────────────────────────────────────────
  Map<String, int> _deptMap = {};
  bool _deptLoading = true;

  List<ManualTemplateInfo> _templates = [];
  bool _templateLoading = false;

  String? _selectedDept;
  ManualTemplateInfo? _selectedTemplate;

  final _reqIdCtrl = TextEditingController();

  // ── results state ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _results = [];
  bool _fetching = false;
  bool _fetched = false;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── pagination state ──────────────────────────────────────────────────────
  int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _reqIdCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── data loading ──────────────────────────────────────────────────────────

  Future<void> _loadDepartments() async {
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
    });
  }

  Future<void> _onDeptSelected(String dept) async {
    setState(() {
      _selectedDept = dept;
      _selectedTemplate = null;
      _templates = [];
      _templateLoading = true;
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
    final reqId = _reqIdCtrl.text.trim();
    if (reqId.isEmpty) {
      _snack('Please enter a Request ID.', isError: true);
      return;
    }
    final deptId = _deptMap[_selectedDept!]!;
    setState(() {
      _fetching = true;
      _results = [];
      _fetched = false;
    });
    final results = await context.read<MasterDataService>().getCheckerTayList(
      templateId: '${_selectedTemplate!.templateId}',
      departmentId: '$deptId',
      requestId: reqId,
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _fetching = false;
      _fetched = true;
      _searchQuery = '';
      _searchCtrl.clear();
      _currentPage = 0;
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
            _buildResultsSection(),
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
                AppColors.amber.withValues(alpha: 0.18),
                AppColors.amber.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            Icons.fact_check_outlined,
            color: AppColors.amber,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checker',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Review and approve uploaded manual data by request',
              style: TextStyle(fontSize: 12, color: AppColors.textDim),
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
          _sectionLabel('FILTER', Icons.tune_rounded),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _labelledDropdown(
                  label: 'Department',
                  hint: 'Select department',
                  value: _selectedDept,
                  items: _deptMap.keys.toList(),
                  loading: _deptLoading,
                  onChanged: (v) {
                    if (v != null) _onDeptSelected(v);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _labelledDropdown(
                  label: 'Template',
                  hint: _selectedDept == null
                      ? 'Select department first'
                      : 'Select template',
                  value: _selectedTemplate?.templateName,
                  items: _templates.map((t) => t.templateName).toList(),
                  loading: _templateLoading,
                  enabled: _selectedDept != null && !_templateLoading,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedTemplate = _templates.firstWhere(
                        (t) => t.templateName == v,
                      );
                      _results = [];
                      _fetched = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _labelledField(
                  label: 'Request ID',
                  child: TextField(
                    controller: _reqIdCtrl,
                    style: const TextStyle(fontSize: 13, color: AppColors.text),
                    decoration: _inputDecoration('e.g. REQ_00021'),
                    onSubmitted: (_) => _fetch(),
                  ),
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
                      'Search',
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

  // ── results section ───────────────────────────────────────────────────────

  static const _columns = [
    '#',
    'Request ID',
    'Department',
    'Template',
    'Created By',
    'Created Date',
    'Download',
    'Approval',
  ];

  Widget _buildResultsSection() {
    if (_results.isEmpty) {
      return _card(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 44,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 12),
                Text(
                  'No records found for the given criteria.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _searchQuery.isEmpty
        ? _results
        : _results.where((item) {
            final q = _searchQuery.toLowerCase();
            return (item['requestId']?.toString().toLowerCase().contains(q) ??
                    false) ||
                (item['departmentName']?.toString().toLowerCase().contains(q) ??
                    false) ||
                (item['templateName']?.toString().toLowerCase().contains(q) ??
                    false) ||
                (item['makerBy']?.toString().toLowerCase().contains(q) ??
                    false) ||
                (item['filename']?.toString().toLowerCase().contains(q) ??
                    false) ||
                _formatDate(
                  item['makerDate']?.toString(),
                ).toLowerCase().contains(q);
          }).toList();

    final totalPages = max(1, (filtered.length / _rowsPerPage).ceil());
    final safePage = _currentPage.clamp(0, totalPages - 1);
    final start = safePage * _rowsPerPage;
    final end = min(start + _rowsPerPage, filtered.length);
    final pageRows = filtered.sublist(start, end);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header row ──
          Row(
            children: [
              _sectionLabel('RESULTS', Icons.table_rows_rounded),
              const SizedBox(width: 10),
              _countBadge(_results.length, label: 'total'),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(width: 6),
                _countBadge(
                  filtered.length,
                  label: 'filtered',
                  color: AppColors.amber,
                ),
              ],
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),

          // ── search bar ──
          SizedBox(
            height: 40,
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 13, color: AppColors.text),
              onChanged: (v) => setState(() {
                _searchQuery = v.trim();
                _currentPage = 0;
              }),
              decoration: _inputDecoration(
                'Search across all columns…',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: AppColors.textDim,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.textDim,
                        ),
                        onPressed: () => setState(() {
                          _searchQuery = '';
                          _searchCtrl.clear();
                          _currentPage = 0;
                        }),
                        splashRadius: 14,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── table ──
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No records match your search.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Table(
                border: TableBorder.all(
                  color: AppColors.border,
                  width: 1,
                  borderRadius: BorderRadius.circular(10),
                ),
                columnWidths: const {
                  0: FixedColumnWidth(44),
                  1: FlexColumnWidth(1.6),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(1.3),
                  5: FlexColumnWidth(1.7),
                  6: FixedColumnWidth(84),
                  7: FlexColumnWidth(2.4),
                },
                children: [
                  _buildHeaderRow(_matchedColumns(_searchQuery)),
                  ...pageRows.asMap().entries.map(
                    (e) => _buildTableRow(e.value, start + e.key),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildPaginationBar(
              filtered.length,
              totalPages,
              safePage,
              start,
              end,
            ),
          ],
        ],
      ),
    );
  }

  // ── matched columns for search highlight ─────────────────────────────────

  Set<String> _matchedColumns(String query) {
    if (query.isEmpty) return {};
    final q = query.toLowerCase();
    final matched = <String>{};
    for (final item in _results) {
      if (item['requestId']?.toString().toLowerCase().contains(q) ?? false)
        matched.add('Request ID');
      if (item['departmentName']?.toString().toLowerCase().contains(q) ?? false)
        matched.add('Department');
      if (item['templateName']?.toString().toLowerCase().contains(q) ?? false)
        matched.add('Template');
      if (item['makerBy']?.toString().toLowerCase().contains(q) ?? false)
        matched.add('Created By');
      if (_formatDate(item['makerDate']?.toString()).toLowerCase().contains(q))
        matched.add('Created Date');
      if (item['filename']?.toString().toLowerCase().contains(q) ?? false)
        matched.add('Download');
    }
    return matched;
  }

  // ── table header row ──────────────────────────────────────────────────────

  TableRow _buildHeaderRow(Set<String> highlighted) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFF1F4F9)),
      children: _columns.map((col) {
        final isHit = highlighted.contains(col);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isHit
                ? AppColors.blue.withValues(alpha: 0.1)
                : Colors.transparent,
            border: isHit
                ? const Border(
                    bottom: BorderSide(color: AppColors.blue, width: 2),
                  )
                : const Border(
                    bottom: BorderSide(color: Colors.transparent, width: 2),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHit) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                col,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isHit ? AppColors.blue : AppColors.textDim,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── table data row ────────────────────────────────────────────────────────

  TableRow _buildTableRow(Map<String, dynamic> item, int index) {
    final filename = item['filename']?.toString() ?? '—';
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    final extColor = _extColor(ext);
    final makerBy = item['makerBy']?.toString() ?? '—';
    final makerDate = _formatDate(item['makerDate']?.toString());
    final requestId = item['requestId']?.toString() ?? '—';
    final templateName = item['templateName']?.toString() ?? '—';
    final deptName = item['departmentName']?.toString() ?? '—';
    final bg = index.isEven ? Colors.white : const Color(0xFFF9FAFC);

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        // # index
        _tdCell(
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

        // Request ID — inline chip
        _tdCell(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.blue.withValues(alpha: 0.09),
                ),
                child: Text(
                  requestId,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Department
        _tdCell(
          child: Text(
            deptName,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Template
        _tdCell(
          child: Text(
            templateName,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Created By
        _tdCell(
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
                    makerBy.isNotEmpty ? makerBy[0].toUpperCase() : '?',
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDim,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Created Date
        _tdCell(
          child: Text(
            makerDate,
            style: const TextStyle(fontSize: 11, color: AppColors.textDim),
          ),
        ),

        // Download
        _tdCell(
          child: Tooltip(
            message: 'Download $filename',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _downloadFile(filename, item),
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

        // Approval
        _tdCell(
          child: Row(
            children: [
              Expanded(
                child: _approvalButton(
                  label: 'Approve',
                  color: const Color(0xFF059669),
                  icon: Icons.check_rounded,
                  onTap: () => _showRemarkDialog(item: item, isApproved: true),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _approvalButton(
                  label: 'Reject',
                  color: const Color(0xFFDC2626),
                  icon: Icons.close_rounded,
                  onTap: () => _showRemarkDialog(item: item, isApproved: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── pagination bar ────────────────────────────────────────────────────────

  Widget _buildPaginationBar(
    int total,
    int totalPages,
    int safePage,
    int start,
    int end,
  ) {
    return Row(
      children: [
        const Text(
          'Rows per page:',
          style: TextStyle(fontSize: 12, color: AppColors.textDim),
        ),
        const SizedBox(width: 8),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border2),
            color: AppColors.surface,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _rowsPerPage,
              isDense: true,
              style: const TextStyle(fontSize: 12, color: AppColors.text),
              dropdownColor: AppColors.surface,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.textDim,
              ),
              items: [10, 25, 50, 100]
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _rowsPerPage = v;
                  _currentPage = 0;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '${start + 1}–$end of $total',
          style: const TextStyle(fontSize: 12, color: AppColors.textDim),
        ),
        const Spacer(),
        _pageButton(
          icon: Icons.first_page_rounded,
          enabled: safePage > 0,
          onTap: () => setState(() => _currentPage = 0),
          tooltip: 'First page',
        ),
        const SizedBox(width: 4),
        _pageButton(
          icon: Icons.chevron_left_rounded,
          enabled: safePage > 0,
          onTap: () => setState(() => _currentPage = safePage - 1),
          tooltip: 'Previous page',
        ),
        const SizedBox(width: 8),
        Text(
          'Page ${safePage + 1} of $totalPages',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(width: 8),
        _pageButton(
          icon: Icons.chevron_right_rounded,
          enabled: safePage < totalPages - 1,
          onTap: () => setState(() => _currentPage = safePage + 1),
          tooltip: 'Next page',
        ),
        const SizedBox(width: 4),
        _pageButton(
          icon: Icons.last_page_rounded,
          enabled: safePage < totalPages - 1,
          onTap: () => setState(() => _currentPage = totalPages - 1),
          tooltip: 'Last page',
        ),
      ],
    );
  }

  Widget _pageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: enabled ? AppColors.border2 : AppColors.border,
            ),
            color: AppColors.surface,
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? AppColors.textDim : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // ── download ──────────────────────────────────────────────────────────────

  Future<void> _downloadFile(String filename, Map<String, dynamic> item) async {
    final templateId =
        item['template_id']?.toString() ??
        _selectedTemplate?.templateId.toString() ??
        '';
    _snack('Downloading $filename…');
    final result = await context.read<MasterDataService>().downloadCheckerFile(
      filename: filename,
      templateId: templateId,
    );
    if (!mounted) return;
    if (result.success) {
      await triggerFileDownload(filename, result.bytes);
    } else {
      _snack(result.message, isError: true);
    }
  }

  // ── remark dialog ─────────────────────────────────────────────────────────

  Future<void> _showRemarkDialog({
    required Map<String, dynamic> item,
    required bool isApproved,
  }) async {
    final remarkCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final color = isApproved
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);
    final label = isApproved ? 'Approve' : 'Reject';
    final icon = isApproved
        ? Icons.check_circle_outline
        : Icons.cancel_outlined;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              '$label Request',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.bg,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Request ID:',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textDim,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['requestId']?.toString() ?? '—',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Remark *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: remarkCtrl,
                  maxLines: 3,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13, color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Enter your remark…',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.red,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.bg,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Remark is required'
                      : null,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textDim),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final remark = remarkCtrl.text.trim();
    final auth = context.read<AuthProvider>();
    final checkerBy = auth.user?.user.employeeCode ?? '';
    final templateId =
        item['template_id']?.toString() ??
        _selectedTemplate?.templateId.toString() ??
        '';
    final deptId = (_deptMap[_selectedDept] ?? 0).toString();
    final requestId = item['requestId']?.toString() ?? '';

    setState(() => _fetching = true);
    final result = await context
        .read<MasterDataService>()
        .submitCheckerApproval(
          templateId: templateId,
          departmentId: deptId,
          requestId: requestId,
          checkerBy: checkerBy,
          remark: remark,
          isApproved: isApproved,
        );
    if (!mounted) return;
    setState(() => _fetching = false);
    if (result.success) {
      _snack('$label successful (Req #${result.reqId})');
      await _fetch();
    } else {
      _snack('Failed: ${result.message}', isError: true);
    }
  }

  // ── small widgets ─────────────────────────────────────────────────────────

  Widget _approvalButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 11, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tdCell({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: child,
    );
  }

  Widget _countBadge(int n, {String label = '', Color color = AppColors.blue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        label.isEmpty ? '$n' : '$n $label',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.blue),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.blue,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _labelledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.surface,
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      return '$dd/$mm/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
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
      case 'txt':
        return AppColors.slate;
      default:
        return AppColors.slate;
    }
  }

  Widget _card({required Widget child}) {
    return Container(
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
  }

  Widget _labelledDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool loading = false,
    bool enabled = true,
  }) {
    return _labelledField(
      label: label,
      child: loading
          ? _loadingField()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: enabled ? AppColors.border2 : AppColors.border,
                ),
                color: enabled ? AppColors.surface : AppColors.bg,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: items.contains(value) ? value : null,
                  hint: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(fontSize: 13, color: AppColors.text),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: enabled ? AppColors.textDim : AppColors.textMuted,
                  ),
                  items: items
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
    );
  }

  Widget _loadingField() {
    return Container(
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
}
