import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Formats an ISO date string to dd/mm/yyyy hh:mm. Returns '—' for null/empty.
String formatTableDate(String? raw) {
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

/// Reusable paginated data table with search and column-highlight.
///
/// Pages supply [columns], [columnWidths], [rowBuilder], [searchFilter], and
/// [columnMatcher] — everything else (search state, pagination, header row,
/// empty-state) is handled here.
class DataResultTable<T> extends StatefulWidget {
  final List<T> items;
  final List<String> columns;
  final Map<int, TableColumnWidth> columnWidths;

  /// Return true when [item] matches [query].
  final bool Function(T item, String query) searchFilter;

  /// Return the set of column names that contain a match for [query].
  final Set<String> Function(List<T> items, String query) columnMatcher;

  /// Build one data [TableRow] for [item] at visual [index] (0-based, absolute).
  final TableRow Function(T item, int index) rowBuilder;

  final String emptyMessage;

  const DataResultTable({
    super.key,
    required this.items,
    required this.columns,
    required this.columnWidths,
    required this.searchFilter,
    required this.columnMatcher,
    required this.rowBuilder,
    this.emptyMessage = 'No records found.',
  });

  /// Shared cell padding used by row builders in parent pages.
  static Widget tdCell({required Widget child}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: child,
  );

  @override
  State<DataResultTable<T>> createState() => _DataResultTableState<T>();
}

class _DataResultTableState<T> extends State<DataResultTable<T>> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant DataResultTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the parent fetches new results, reset search + pagination.
    if (!identical(oldWidget.items, widget.items)) {
      _searchCtrl.clear();
      _searchQuery = '';
      _currentPage = 0;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 44,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.emptyMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _searchQuery.isEmpty
        ? widget.items
        : widget.items
              .where((i) => widget.searchFilter(i, _searchQuery))
              .toList();

    final totalPages = max(1, (filtered.length / _rowsPerPage).ceil());
    final safePage = _currentPage.clamp(0, totalPages - 1);
    final start = safePage * _rowsPerPage;
    final end = min(start + _rowsPerPage, filtered.length);
    final pageRows = filtered.sublist(start, end);
    final matched = widget.columnMatcher(widget.items, _searchQuery);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── top bar ──────────────────────────────────────────────────────
          Row(
            children: [
              _sectionLabel('RESULTS', Icons.table_rows_rounded),
              const SizedBox(width: 10),
              _countBadge(widget.items.length, label: 'total'),
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

          // ── search bar ───────────────────────────────────────────────────
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

          // ── table ────────────────────────────────────────────────────────
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
                columnWidths: widget.columnWidths,
                children: [
                  _buildHeaderRow(matched),
                  ...pageRows.asMap().entries.map(
                    (e) => widget.rowBuilder(e.value, start + e.key),
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

  // ── header row ─────────────────────────────────────────────────────────────

  TableRow _buildHeaderRow(Set<String> highlighted) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFF1F4F9)),
      children: widget.columns.map((col) {
        final isHit = highlighted.contains(col);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isHit
                ? AppColors.violet.withValues(alpha: 0.08)
                : Colors.transparent,
            border: isHit
                ? const Border(
                    bottom: BorderSide(color: AppColors.violet, width: 2),
                  )
                : const Border(
                    bottom: BorderSide(color: Colors.transparent, width: 2),
                  ),
          ),
          child: Row(
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
              Flexible(
                child: Text(
                  col,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isHit ? AppColors.violet : AppColors.textDim,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── pagination ─────────────────────────────────────────────────────────────

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

  // ── small helpers ──────────────────────────────────────────────────────────

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

  Widget _sectionLabel(String title, IconData icon) => Row(
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

  Widget _countBadge(
    int n, {
    String label = '',
    Color color = AppColors.blue,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: color.withValues(alpha: 0.1),
    ),
    child: Text(
      label.isEmpty ? '$n' : '$n $label',
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );

  InputDecoration _inputDecoration(
    String hint, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
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
