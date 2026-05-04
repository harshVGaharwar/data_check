import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/master_data_service.dart';

class TemplateConfigurationListPage extends StatefulWidget {
  const TemplateConfigurationListPage({super.key});

  @override
  State<TemplateConfigurationListPage> createState() =>
      _TemplateConfigurationListPageState();
}

class _TemplateConfigurationListPageState
    extends State<TemplateConfigurationListPage> {
  List<Map<String, dynamic>> _results = [];
  bool _fetching = false;
  bool _fetched = false;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  int _rowsPerPage = 10;
  int _currentPage = 0;

  static const _columns = [
    '#',
    'Template ID',
    'Template Name',
    'Department',
    'Frequency',
    'Sources',
    'Joins',
    'Outputs',
    'Created By',
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _fetching = true;
      _results = [];
      _fetched = false;
    });
    final auth = context.read<AuthProvider>();
    if (!auth.initialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return mounted && !context.read<AuthProvider>().initialized;
      });
    }
    if (!mounted) return;
    final list =
        await context.read<MasterDataService>().getTemplateConfigurationList();
    if (!mounted) return;
    setState(() {
      _results = list;
      _fetching = false;
      _fetched = true;
      _searchQuery = '';
      _searchCtrl.clear();
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (_fetching) ...[
            const SizedBox(height: 40),
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.blue,
              ),
            ),
          ] else if (_fetched) ...[
            _buildResultsSection(),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

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
            border:
                Border.all(color: AppColors.violet.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            Icons.settings_applications_outlined,
            color: AppColors.violet,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Template Configuration List',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'All templates that have been pipeline-configured',
                style: TextStyle(fontSize: 12, color: AppColors.textDim),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: _fetching ? null : _fetch,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'Refresh',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violet,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.violet.withValues(alpha: 0.4),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
                  'No template configurations found.',
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
            return (item['templateId']?.toString().toLowerCase().contains(q) ??
                    false) ||
                (item['templateName']
                        ?.toString()
                        .toLowerCase()
                        .contains(q) ??
                    false) ||
                (item['department']?.toString().toLowerCase().contains(q) ??
                    false) ||
                (item['frequency']?.toString().toLowerCase().contains(q) ??
                    false) ||
                (item['createdBy']?.toString().toLowerCase().contains(q) ??
                    false);
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
          Row(
            children: [
              _sectionLabel('CONFIGURATIONS', Icons.table_rows_rounded),
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
                  1: FixedColumnWidth(100),
                  2: FlexColumnWidth(2.4),
                  3: FlexColumnWidth(1.6),
                  4: FlexColumnWidth(1.3),
                  5: FixedColumnWidth(72),
                  6: FixedColumnWidth(64),
                  7: FixedColumnWidth(72),
                  8: FlexColumnWidth(1.4),
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

  Set<String> _matchedColumns(String query) {
    if (query.isEmpty) return {};
    final q = query.toLowerCase();
    final matched = <String>{};
    for (final item in _results) {
      if (item['templateId']?.toString().toLowerCase().contains(q) ?? false) {
        matched.add('Template ID');
      }
      if (item['templateName']?.toString().toLowerCase().contains(q) ?? false) {
        matched.add('Template Name');
      }
      if (item['department']?.toString().toLowerCase().contains(q) ?? false) {
        matched.add('Department');
      }
      if (item['frequency']?.toString().toLowerCase().contains(q) ?? false) {
        matched.add('Frequency');
      }
      if (item['createdBy']?.toString().toLowerCase().contains(q) ?? false) {
        matched.add('Created By');
      }
    }
    return matched;
  }

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
                ? AppColors.violet.withValues(alpha: 0.1)
                : Colors.transparent,
            border: isHit
                ? const Border(
                    bottom: BorderSide(color: AppColors.violet, width: 2),
                  )
                : const Border(
                    bottom:
                        BorderSide(color: Colors.transparent, width: 2),
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
                    color: AppColors.violet,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                col,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isHit ? AppColors.violet : AppColors.textDim,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  TableRow _buildTableRow(Map<String, dynamic> item, int index) {
    final tid = item['templateId']?.toString() ?? '—';
    final name = item['templateName']?.toString() ?? '—';
    final dept = item['department']?.toString() ?? '—';
    final freq = item['frequency']?.toString() ?? '—';
    final sources = item['sourceCount']?.toString() ?? '0';
    final joins = item['joinCount']?.toString() ?? '0';
    final outputs = item['outputCount']?.toString() ?? '0';
    final createdBy = item['createdBy']?.toString() ?? '—';
    final bg = index.isEven ? Colors.white : const Color(0xFFF9FAFC);

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
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
        _tdCell(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.violet.withValues(alpha: 0.09),
            ),
            child: Text(
              tid,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.violet,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        _tdCell(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _tdCell(
          child: Text(
            dept,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _tdCell(
          child: Text(
            freq,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _tdCell(
          child: Text(
            sources,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _tdCell(
          child: Text(
            joins,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _tdCell(
          child: Text(
            outputs,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _tdCell(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violet.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    createdBy.isNotEmpty ? createdBy[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.violet,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  createdBy,
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
      ],
    );
  }

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

  Widget _tdCell({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: child,
    );
  }

  Widget _countBadge(int n,
      {String label = '', Color color = AppColors.violet}) {
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
        Icon(icon, size: 13, color: AppColors.violet),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.violet,
            letterSpacing: 0.8,
          ),
        ),
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
        borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.surface,
    );
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
}
