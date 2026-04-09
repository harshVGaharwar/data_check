import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../models/master_models.dart';
import '../controllers/pipeline_controller.dart';
import '../providers/pipeline_master_provider.dart';

class ConfigPanel extends StatelessWidget {
  const ConfigPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<PipelineController>(
      builder: (context, ctrl, _) {
        final node = ctrl.selectedNodeId != null
            ? ctrl.findNode(ctrl.selectedNodeId!)
            : null;

        return Container(
          width: 260,
          color: AppColors.surface,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        node != null
                            ? 'Configure: ${node.name}'
                            : 'Configure Node',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (node != null)
                      InkWell(
                        onTap: () => ctrl.selectNode(null),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textDim,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: node == null
                    ? const Center(
                        child: Text(
                          'Click a node to configure',
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : _buildConfig(context, ctrl, node),
              ),

              // Delete button
              if (node != null && node.type.isSource)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: InkWell(
                    onTap: () => ctrl.deleteNode(node.id),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.red.withOpacity(0.3),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '🗑 Delete Node',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfig(
    BuildContext context,
    PipelineController ctrl,
    PipelineNode node,
  ) {
    if (!node.type.isSource) {
      return const Center(
        child: Text(
          'Use node card controls',
          style: TextStyle(color: AppColors.textDim, fontSize: 11),
        ),
      );
    }

    final isManual =
        node.type == NodeType.manual ||
        node.sourceTypeValue.toUpperCase() == 'MANUAL';
    final separators = [
      'Comma (,)',
      'Pipe (|)',
      'Tab (\\t)',
      'Semicolon (;)',
      'Space ( )',
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Source Name ──
        const Text('Source Name *', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        TextFormField(
          key: ValueKey('name_${node.id}'),
          initialValue: node.name,
          onChanged: (v) => ctrl.updateNodeName(node.id, v),
          style: const TextStyle(color: AppColors.text, fontSize: 12.5),
          decoration: _inputDecor(),
        ),
        const SizedBox(height: 14),

        // ── Source Type (API-driven dropdown) ──
        const Text('Source Type', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        _SourceTypeDropdown(node: node, ctrl: ctrl),
        const SizedBox(height: 14),

        // ── Separator (Manual type only) ──
        if (isManual) ...[
          const Text('File Separator *', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.border2),
              color: AppColors.surface2,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _sepToLabel(node.separator, separators),
                dropdownColor: AppColors.surface2,
                style: const TextStyle(fontSize: 12, color: AppColors.text),
                items: separators
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    final sep = v.contains(',')
                        ? ','
                        : v.contains('|')
                        ? '|'
                        : v.contains('\\t')
                        ? '\t'
                        : v.contains(';')
                        ? ';'
                        : ' ';
                    node.separator = sep;
                    ctrl.notifyListeners();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Non-manual: info banner ──
        if (!isManual) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: AppColors.blue.withOpacity(0.07),
              border: Border.all(color: AppColors.blue.withOpacity(0.18)),
            ),
            child: const Text(
              'Separator auto-detected from uploaded column file',
              style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10.5),
            ),
          ),
          const SizedBox(height: 14),

          // ── Query File Upload (non-manual only) ──
          const Text(
            'Upload Query File (.txt)',
            style: AppTextStyles.fieldLabel,
          ),
          const SizedBox(height: 4),
          _uploadButton(
            icon: Icons.description_outlined,
            label: 'Upload Query File (.txt)',
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['txt'],
                withData: true,
              );
              if (result != null && result.files.single.bytes != null) {
                final fileName = result.files.single.name;
                ctrl.setQueryFile(node.id, fileName, bytes: result.files.single.bytes!.toList());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Query file loaded: $fileName'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              }
            },
          ),
          if (node.queryFileName != null) ...[
            const SizedBox(height: 4),
            _fileInfoBar(node.queryFileName!, null, AppColors.blue),
          ],
          const SizedBox(height: 14),
        ],

        // ── Column File Upload ──
        const Text(
          'Upload Column File (.csv / .txt)',
          style: AppTextStyles.fieldLabel,
        ),
        const SizedBox(height: 4),
        _uploadButton(
          icon: Icons.upload_file_rounded,
          label: 'Upload Column File (.csv / .txt)',
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['csv', 'txt'],
              withData: true,
            );
            if (result == null || result.files.single.bytes == null) return;

            final bytes = result.files.single.bytes!;
            final fileName = result.files.single.name;
            final text = utf8.decode(bytes, allowMalformed: true);
            final lines = text
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .toList();
            if (lines.isEmpty) return;

            // Auto-detect separator (same as HTML logic)
            final firstLine = lines.first;
            String sep = ',';
            if ('|'.allMatches(firstLine).length > 1) {
              sep = '|';
            } else if ('\t'.allMatches(firstLine).length > 1) {
              sep = '\t';
            } else if (';'.allMatches(firstLine).length > 1) {
              sep = ';';
            }

            // Extract columns from header
            final cols = firstLine
                .split(sep)
                .map((c) => c.trim().replaceAll('"', '').trim())
                .where((c) => c.isNotEmpty)
                .toList();

            if (cols.isEmpty) return;

            // Parse data rows
            final rows = <Map<String, dynamic>>[];
            for (int i = 1; i < lines.length; i++) {
              final vals = lines[i]
                  .split(sep)
                  .map((v) => v.trim().replaceAll('"', '').trim())
                  .toList();
              final row = <String, dynamic>{};
              for (int j = 0; j < cols.length; j++) {
                row[cols[j]] = j < vals.length ? vals[j] : '';
              }
              rows.add(row);
            }

            ctrl.setNodeColumns(node.id, cols, rows, fileName, bytes: bytes.toList());
            // Store auto-detected separator
            node.separator = sep;
            ctrl.notifyListeners();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${cols.length} columns, ${rows.length} rows extracted from $fileName',
                  ),
                  backgroundColor: AppColors.green,
                ),
              );
            }
          },
        ),
        if (node.fileName != null) ...[
          const SizedBox(height: 4),
          _fileInfoBar(
            node.fileName!,
            '${node.cols.length} cols',
            AppColors.green,
          ),
        ],
        const SizedBox(height: 14),

        // ── Columns (pills — toggle on/off) ──
        if (node.cols.isNotEmpty) ...[
          Text(
            'Output Format Selection (${node.selectedCols.length}/${node.cols.length})',
            style: AppTextStyles.fieldLabel,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: node.cols.map((c) {
              final sel = node.selectedCols.contains(c);
              return InkWell(
                onTap: () => ctrl.toggleColumn(node.id, c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: sel
                        ? AppColors.blue.withOpacity(0.15)
                        : AppColors.surface2,
                    border: Border.all(
                      color: sel ? AppColors.blue : AppColors.border2,
                    ),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      color: sel ? AppColors.blue : AppColors.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: AppColors.surface2,
            ),
            child: const Center(
              child: Text(
                'Upload a file to see columns',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ),

        // ── Data rows count ──
        if (node.rows.isNotEmpty) ...[
          const SizedBox(height: 14),
          _fileInfoBar(
            '${node.rows.length} data rows loaded',
            null,
            AppColors.green,
          ),
        ],
      ],
    );
  }

  /// Map separator char → display label for the dropdown value
  String _sepToLabel(String sep, List<String> separators) {
    const map = {
      ',': 'Comma (,)',
      '|': 'Pipe (|)',
      '\t': 'Tab (\\t)',
      ';': 'Semicolon (;)',
      ' ': 'Space ( )',
    };
    final label = map[sep] ?? separators[0];
    return separators.contains(label) ? label : separators[0];
  }

  InputDecoration _inputDecor() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: AppColors.border2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: AppColors.border2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: AppColors.blue),
      ),
      filled: true,
      fillColor: AppColors.surface2,
    );
  }

  Widget _uploadButton({
    required IconData icon,
    required String label,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border2,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textDim, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileInfoBar(String text, String? badge, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 11)),
          ),
          if (badge != null)
            Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SOURCE TYPE DROPDOWN
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SourceTypeDropdown extends StatelessWidget {
  final PipelineNode node;
  final PipelineController ctrl;
  const _SourceTypeDropdown({required this.node, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final master = context.watch<PipelineMasterProvider>();

    if (master.loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                strokeWidth: 1.5,
                color: AppColors.textDim,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Loading...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (master.sourceTypes.isEmpty) {
      // Fallback: show node type label read-only
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border2),
          color: AppColors.surface2,
        ),
        child: Row(
          children: [
            Icon(node.type.icon, color: node.type.color, size: 14),
            const SizedBox(width: 8),
            Text(
              node.type.label,
              style: const TextStyle(color: AppColors.text, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final items = master.sourceTypes;
    final currentValue = node.sourceTypeValue.isNotEmpty
        ? node.sourceTypeValue
        : null;
    final matchedItem = currentValue != null
        ? items
              .where(
                (i) =>
                    i.sourceValue.toUpperCase() == currentValue.toUpperCase(),
              )
              .firstOrNull
        : null;

    // If sourceTypeValue was set from drag, show read-only badge — no re-selection needed
    if (matchedItem != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.blue.withOpacity(0.3)),
          color: AppColors.blue.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: AppColors.blue.withOpacity(0.12),
                border: Border.all(color: AppColors.blue.withOpacity(0.25)),
              ),
              child: Text(
                matchedItem.sourceValue,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                matchedItem.sourceName,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.lock_outline, size: 12, color: AppColors.textDim),
          ],
        ),
      );
    }

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
          isDense: true,
          value: null,
          hint: const Text(
            'Select source type',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          dropdownColor: AppColors.surface2,
          style: const TextStyle(color: AppColors.text, fontSize: 12),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.textDim,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.sourceValue,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: AppColors.blue.withOpacity(0.1),
                          border: Border.all(
                            color: AppColors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          item.sourceValue,
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.sourceName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) ctrl.updateNodeSourceType(node.id, value);
          },
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATUS BAR (same as HTML .statusbar)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
