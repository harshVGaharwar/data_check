import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../controllers/pipeline_controller.dart';
import '../providers/pipeline_master_provider.dart';

class ConfigPanel extends StatefulWidget {
  const ConfigPanel({super.key});

  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _anim;

  // Track which node is open so we reset state on switch
  String? _prevNodeId;

  // True only after the user explicitly changes the separator dropdown
  bool _sepAcknowledged = false;

  // Persistent controller for the source-name field so typing doesn't lose focus
  final TextEditingController _nameCtrl = TextEditingController();

  int _lastCanvasVersion = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Returns 0-4 depending on what the user should fill next ──
  // Non-manual : 0=sourceName  1=queryFile   2=columnFile  3=outputFormat  4=configBtn
  // Manual     : 0=sourceName  1=separator   2=columnFile  3=outputFormat  4=configBtn
  int _computeStep(PipelineNode node) {
    if (node.confirmState != NodeConfirmState.notConfigured) return -1;
    if (node.name.trim().isEmpty) return 0;
    final isManual = node.type == NodeType.manual;
    if (isManual) {
      if (!_sepAcknowledged) return 1; // separator
      if (node.fileName == null) return 2; // column file
      if (node.selectedCols.isEmpty) return 3; // output format
      return 4; // config button
    } else {
      if (node.queryFileName == null) return 1; // query file
      if (node.fileName == null) return 2; // column file
      if (node.selectedCols.isEmpty) return 3; // output format
      return 4; // config button
    }
  }

  // ── Wraps [child] with a pulsing glow border only when [forStep] is active ──
  Widget _hl(
    int forStep,
    int activeStep,
    Widget child, {
    Color color = AppColors.blue,
    bool borderOnly = false,
  }) {
    // Always wrap in AnimatedBuilder + Container with a BoxDecoration so the
    // widget tree structure stays constant as `step` changes.
    // KEY: decoration must never be null — Container adds/removes an internal
    // DecoratedBox when decoration flips null↔non-null, which remounts the
    // child and kills TextField focus.  Use alpha=0 for the inactive state.
    return AnimatedBuilder(
      animation: _anim,
      child:
          child, // passed as AnimatedBuilder.child so it isn't rebuilt every frame
      builder: (_, builtChild) {
        final isActive = forStep == activeStep;
        final t = isActive ? _anim.value : 0.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: t * 0.65),
              width: 1.5,
            ),
            color: borderOnly ? null : color.withValues(alpha: t * 0.05),
            boxShadow: t > 0.1 && !borderOnly
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: t * 0.18),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: builtChild,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PipelineController>(
      builder: (context, ctrl, _) {
        final node = ctrl.selectedNodeId != null
            ? ctrl.findNode(ctrl.selectedNodeId!)
            : null;

        // ── Detect canvas clear → reset all local state ──
        if (ctrl.canvasVersion != _lastCanvasVersion) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _nameCtrl.clear();
            setState(() {
              _lastCanvasVersion = ctrl.canvasVersion;
              _prevNodeId = null;
              _sepAcknowledged = false;
            });
          });
        }

        // ── Detect node switch → reset state and sync name controller ──
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final newId = ctrl.selectedNodeId;
          if (newId != _prevNodeId) {
            final newNode = newId != null ? ctrl.findNode(newId) : null;
            _nameCtrl.text = newNode?.name ?? '';
            setState(() {
              _prevNodeId = newId;
              _sepAcknowledged = false;
            });
          }
        });

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
                          color: AppColors.red.withValues(alpha: 0.3),
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

    final isLocked = node.confirmState == NodeConfirmState.confirmed;
    final isManual = node.type == NodeType.manual;
    final step = _computeStep(node);
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
        // ── Source Type (API-driven dropdown) ──
        const Text('Source Type *', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        _SourceTypeDropdown(node: node, ctrl: ctrl, isLocked: isLocked),
        const SizedBox(height: 14),

        // ── Source Name ── (step 0)
        const Text('Source Name *', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        _hl(
          0,
          step,
          TextFormField(
            controller: _nameCtrl,
            readOnly: isLocked,
            onChanged: isLocked ? null : (v) => ctrl.updateNodeName(node.id, v),
            style: TextStyle(
              color: isLocked ? AppColors.textDim : AppColors.text,
              fontSize: 12.5,
            ),
            decoration: _inputDecor(locked: isLocked),
          ),
          borderOnly: true,
        ),
        const SizedBox(height: 14),

        // ── Separator (Manual only) ── (step 1 for manual)
        if (isManual) ...[
          const Text('File Separator *', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 4),
          _hl(
            1,
            step,
            Opacity(
              opacity: isLocked ? 0.5 : 1.0,
              child: IgnorePointer(
                ignoring: isLocked,
                child: Container(
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text,
                      ),
                      items: separators
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
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
                          ctrl.updateNodeSeparator(node.id, sep);
                          setState(() => _sepAcknowledged = true);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            borderOnly: true,
          ),
          const SizedBox(height: 14),
        ],

        // ── Non-manual: Query File Upload ── (step 1 for non-manual)
        if (!isManual) ...[
          const Text(
            'Upload Query File (.txt) *',
            style: AppTextStyles.fieldLabel,
          ),
          const SizedBox(height: 4),
          _hl(
            1,
            step,
            _uploadButton(
              icon: Icons.description_outlined,
              label: 'Upload Query File (.txt)',
              isLocked: isLocked,
              onTap: isLocked
                  ? null
                  : () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['txt'],
                        withData: true,
                      );
                      if (result != null && result.files.single.bytes != null) {
                        final fileName = result.files.single.name;
                        final queryBytes = result.files.single.bytes!;
                        final queryText = utf8.decode(
                          queryBytes,
                          allowMalformed: true,
                        );
                        if (!_isValidQueryFile(queryText)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Invalid file: the query file must contain a valid SQL query (e.g. starting with SELECT, WITH, INSERT, etc.). Column/CSV files are not allowed here.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
                        ctrl.setQueryFile(
                          node.id,
                          fileName,
                          bytes: queryBytes.toList(),
                        );
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
            borderOnly: true,
          ),
          if (node.queryFileName != null) ...[
            const SizedBox(height: 4),
            _fileInfoBar(node.queryFileName!, null, AppColors.blue),
          ],
          const SizedBox(height: 14),
        ],

        // ── Column File Upload ── (step 2)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Column File (.csv / .txt) *',
              style: AppTextStyles.fieldLabel,
            ),
            const SizedBox(height: 4),
            _hl(
              2,
              step,
              _uploadButton(
                icon: Icons.upload_file_rounded,
                label: 'Upload Column File (.csv / .txt)',
                isLocked: isLocked,
                onTap: isLocked
                    ? null
                    : () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['csv', 'txt'],
                          withData: true,
                        );
                        if (result == null || result.files.single.bytes == null)
                          return;
                        final bytes = result.files.single.bytes!;
                        final fileName = result.files.single.name;
                        final text = utf8.decode(bytes, allowMalformed: true);
                        final lines = text
                            .split('\n')
                            .where((l) => l.trim().isNotEmpty)
                            .toList();
                        if (lines.isEmpty) return;
                        final firstLine = lines.first;
                        String sep = ',';
                        if ('|'.allMatches(firstLine).length > 1) {
                          sep = '|';
                        } else if ('\t'.allMatches(firstLine).length > 1) {
                          sep = '\t';
                        } else if (';'.allMatches(firstLine).length > 1) {
                          sep = ';';
                        }
                        final cols = firstLine
                            .split(sep)
                            .map((c) => c.trim().replaceAll('"', '').trim())
                            .where((c) => c.isNotEmpty)
                            .toList();
                        if (cols.isEmpty) return;
                        // Reject if the file is actually a SQL query file
                        if (_isValidQueryFile(text)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Invalid file: this looks like a SQL query file. Please upload a column file (.csv / .txt with column headers).',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
                        if (!_isValidColumnHeaders(cols)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Invalid file: the first row must contain column headers, not raw data or unstructured text.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
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
                        ctrl.setNodeColumns(
                          node.id,
                          cols,
                          rows,
                          fileName,
                          bytes: bytes.toList(),
                        );
                        ctrl.updateNodeSeparator(node.id, sep);
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
              borderOnly: true,
            ),
            if (node.fileName != null) ...[
              const SizedBox(height: 4),
              _fileInfoBar(
                node.fileName!,
                '${node.cols.length} cols',
                AppColors.green,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        const SizedBox(height: 20),

        // ── Confirm / Edit button ──
        _ConfirmSection(node: node, ctrl: ctrl),

        const SizedBox(height: 8),
      ],
    );
  }

  /// Returns true if the extracted column headers look like real column names.
  /// Rejects: all-numeric headers, single long unstructured string, or headers
  /// that are sentences (contain multiple spaces / punctuation).
  bool _isValidColumnHeaders(List<String> cols) {
    if (cols.isEmpty) return false;
    // Every token must not be a plain integer/float
    final allNumeric = cols.every((c) => double.tryParse(c) != null);
    if (allNumeric) return false;
    // If there is only one "column" and it looks like a sentence/paragraph
    if (cols.length == 1 && cols.first.length > 60) return false;
    // A column name should not contain sentence-level punctuation like '.' mid-word
    // or be a multi-word natural-language sentence (more than 5 space-separated words)
    final looksLikeSentence = cols.any((c) {
      final wordCount = c.trim().split(RegExp(r'\s+')).length;
      return wordCount > 5;
    });
    if (looksLikeSentence) return false;
    return true;
  }

  /// Returns true if the text content looks like a SQL query.
  bool _isValidQueryFile(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final upper = trimmed.toUpperCase();
    const sqlKeywords = [
      'SELECT',
      'WITH',
      'INSERT',
      'UPDATE',
      'DELETE',
      'CREATE',
      'MERGE',
      'CALL',
      'EXEC',
    ];
    return sqlKeywords.any((kw) => upper.startsWith(kw));
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

  InputDecoration _inputDecor({bool locked = false}) {
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
        borderSide: BorderSide(
          color: locked ? AppColors.border2 : AppColors.blue,
        ),
      ),
      filled: true,
      fillColor: locked
          ? AppColors.surface2.withValues(alpha: 0.6)
          : AppColors.surface2,
      suffixIcon: locked
          ? const Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: AppColors.textMuted,
            )
          : null,
    );
  }

  Widget _uploadButton({
    required IconData icon,
    required String label,
    required Function()? onTap,
    bool isLocked = false,
  }) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: InkWell(
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
              Icon(
                isLocked ? Icons.lock_outline_rounded : icon,
                color: AppColors.textDim,
                size: 16,
              ),
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
      ),
    );
  }

  Widget _fileInfoBar(String text, String? badge, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
// CONFIRM SECTION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ConfirmSection extends StatelessWidget {
  final PipelineNode node;
  final PipelineController ctrl;
  const _ConfirmSection({required this.node, required this.ctrl});

  String? _validate() {
    final isManual = node.type == NodeType.manual;
    if (node.name.trim().isEmpty) return 'Source Name is required.';
    if (node.sourceTypeValue.isEmpty) return 'Source Type is required.';
    if (isManual) {
      if (node.fileName == null) return 'Upload Column File is required.';
    } else {
      if (node.queryFileName == null) return 'Upload Query File is required.';
      if (node.fileName == null) return 'Upload Column File is required.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = node.confirmState;
    final isConfirmed = state == NodeConfirmState.confirmed;
    final isEditing = state == NodeConfirmState.editing;
    final isReady = _validate() == null;

    if (isConfirmed) {
      // ── Confirmed state ──
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.green.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Confirmed',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => ctrl.editNode(node.id),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.4),
                ),
                color: AppColors.amber.withValues(alpha: 0.07),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, color: AppColors.amber, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // ── Not configured / Editing state ──
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditing) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: AppColors.amber.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, color: AppColors.amber, size: 13),
                SizedBox(width: 6),
                Text(
                  'Editing — re-confirm when done',
                  style: TextStyle(color: AppColors.amber, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
        InkWell(
          onTap: () {
            final error = _validate();
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.red),
              );
              return;
            }
            ctrl.confirmNode(node.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${node.name} confirmed successfully.'),
                backgroundColor: AppColors.green,
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isReady
                  ? AppColors.blue
                  : AppColors.border.withValues(alpha: 0.5),
              border: Border.all(
                color: isReady ? AppColors.blue : AppColors.border2,
                width: isReady ? 2.0 : 1.0,
              ),
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_rounded,
                  color: isReady ? Colors.white : AppColors.textMuted,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  'Configure',
                  style: TextStyle(
                    color: isReady ? Colors.white : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SOURCE TYPE DROPDOWN
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SourceTypeDropdown extends StatelessWidget {
  final PipelineNode node;
  final PipelineController ctrl;
  final bool isLocked;
  const _SourceTypeDropdown({
    required this.node,
    required this.ctrl,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final master = context.watch<PipelineMasterProvider>();
    return Opacity(
      opacity: isLocked ? 0.55 : 1.0,
      child: IgnorePointer(
        ignoring: isLocked,
        child: _buildDropdown(context, master),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, PipelineMasterProvider master) {
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

    final matchedItem = node.sourceTypeId > 0
        ? master.sourceTypes.where((i) => i.id == node.sourceTypeId).firstOrNull
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
        color: AppColors.blue.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: AppColors.blue.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
            ),
            child: Text(
              matchedItem?.sourceValue ?? node.sourceTypeValue,
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
              matchedItem?.sourceName ?? node.sourceTypeName,
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
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATUS BAR (same as HTML .statusbar)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
