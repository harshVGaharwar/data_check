import 'package:flutter/material.dart';
import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/uni_mailing_shared.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/dyn_uni_col_selection_card.dart';
import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/dynamic_key_mapping_card.dart';
import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/static_key_mapping_card.dart';

class DynamicUniMailingOutputSection extends StatefulWidget {
  final PipelineController ctrl;
  final List<PipelineNode> sourceNodes;
  const DynamicUniMailingOutputSection({
    super.key,
    required this.ctrl,
    required this.sourceNodes,
  });

  @override
  State<DynamicUniMailingOutputSection> createState() =>
      _DynamicUniMailingOutputSectionState();
}

class _DynamicUniMailingOutputSectionState
    extends State<DynamicUniMailingOutputSection> {
  // No local key state — driven entirely by ctrl.selectedOutputKey (sidebar).
  String _prevKey = '';

  // Working state for the key currently being configured
  final Set<String> _localSelected = {}; // 'nodeId::colName'
  final Map<String, String> _workingMandatory =
      {}; // field/slot → 'nodeId::col'
  final Map<String, String> _workingCustom = {}; // slot → 'nodeId::col'
  final Map<String, bool> _localUniqueFields =
      {}; // 'nodeId::colName' → isUnique
  int _customCount = 0;

  @override
  void initState() {
    super.initState();
    _prevKey = widget.ctrl.selectedOutputKey;
    widget.ctrl.addListener(_onCtrlChange);
    // If a key is already selected on mount, set customCount immediately
    // (onCtrlChange won't fire because the key hasn't changed)
    if (widget.ctrl.selectedOutputKey.isNotEmpty) {
      _customCount =
          widget.ctrl.isOutputKeyStatic(widget.ctrl.selectedOutputKey) ? 1 : 0;
    }
    // If no key is selected yet, auto-select the next unconfigured key.
    if (widget.ctrl.selectedOutputKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctrl = widget.ctrl;
        if (ctrl.selectedOutputKey.isEmpty) {
          final keys = ctrl.dynamicUniMailingOutputKeys;
          final next = keys
              .where((k) => !ctrl.savedOutputKeyConfigs.containsKey(k))
              .firstOrNull;
          if (next != null) ctrl.setSelectedOutputKey(next);
        }
      });
    }
  }

  void _onCtrlChange() {
    final newKey = widget.ctrl.selectedOutputKey;
    if (newKey != _prevKey) {
      setState(() {
        _prevKey = newKey;
        _resetFormValues();
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onCtrlChange);
    super.dispose();
  }

  /// Mutates form fields directly — safe to call inside an existing setState.
  void _resetFormValues() {
    _localSelected.clear();
    _workingMandatory.clear();
    _workingCustom.clear();
    _localUniqueFields.clear();
    // Static key: Column 1 shown by default. Dynamic key: no default column.
    _customCount = _isCurrentKeyStatic ? 1 : 0;
  }

  /// Standalone clear: mutates + triggers rebuild (use for the Clear button).
  void _clearForm() => setState(_resetFormValues);

  bool get _isCurrentKeyStatic =>
      widget.ctrl.isOutputKeyStatic(widget.ctrl.selectedOutputKey);

  bool get _canSave {
    if (widget.ctrl.selectedOutputKey.isEmpty || _localSelected.isEmpty) {
      return false;
    }
    if (_isCurrentKeyStatic) {
      // All added custom columns must be mapped (Column 1 is always required)
      final allCustomFilled = List.generate(_customCount, (i) {
        final key = 'C${i + 1}';
        final val = _workingCustom[key] ?? '';
        return val.isNotEmpty && _localSelected.contains(val);
      }).every((ok) => ok);
      return allCustomFilled;
    } else {
      final c0 = _workingMandatory['C0'] ?? '';
      final c1 = _workingMandatory['C1'] ?? '';
      final mandatoryOk =
          c0.isNotEmpty &&
          _localSelected.contains(c0) &&
          c1.isNotEmpty &&
          _localSelected.contains(c1);
      // All added optional columns (C2+) must also be filled
      final allOptionalFilled = List.generate(_customCount, (i) {
        final key = 'C${i + 2}';
        final val = _workingCustom[key] ?? '';
        return val.isNotEmpty && _localSelected.contains(val);
      }).every((ok) => ok);
      return mandatoryOk && allOptionalFilled;
    }
  }

  void _save() {
    final ctrl = widget.ctrl;
    final currentKey = ctrl.selectedOutputKey;
    if (currentKey.isEmpty) return;

    String resolveCol(String key) =>
        key.contains('::') ? key.split('::')[1] : key;
    PipelineNode? resolveNode(String key) {
      if (!key.contains('::')) return null;
      final nid = key.split('::')[0];
      return widget.sourceNodes.where((n) => n.id == nid).firstOrNull;
    }

    String resolveSource(String key) => resolveNode(key)?.name ?? '';

    final selCols = _localSelected
        .map(
          (k) => {
            'NodeId': k.split('::')[0],
            'NodeName': resolveSource(k),
            'ColName': resolveCol(k),
            'isUniqueField': _localUniqueFields[k] ?? false,
            'SourceTypeValue': resolveNode(k)?.sourceTypeValue ?? '',
          },
        )
        .toList();

    final sortedCustom =
        _workingCustom.entries
            .where(
              (e) => e.value.isNotEmpty && _localSelected.contains(e.value),
            )
            .map(
              (e) => {
                'Slot': e.key,
                'ColumnName': resolveCol(e.value),
                'SourceName': resolveSource(e.value),
                'isUniqueField': _localUniqueFields[e.value] ?? false,
              },
            )
            .toList()
          ..sort((a, b) {
            final ai = int.tryParse((a['Slot'] as String).substring(1)) ?? 0;
            final bi = int.tryParse((b['Slot'] as String).substring(1)) ?? 0;
            return ai.compareTo(bi);
          });

    final Map<String, dynamic> config;
    if (_isCurrentKeyStatic) {
      config = {
        'KeyName': currentKey,
        'KeyType': 'Static',
        'SelectedColumns': selCols,
        // All 7 unimailing fields always sent; empty string if not mapped
        'MandatoryFields': kMandatoryFields.map((f) {
          final val = _workingMandatory[f] ?? '';
          return {
            'Field': f,
            'ColumnName': val.isNotEmpty ? resolveCol(val) : '',
            'SourceName': val.isNotEmpty ? resolveSource(val) : '',
            'isUniqueField': val.isNotEmpty
                ? (_localUniqueFields[val] ?? false)
                : false,
          };
        }).toList(),
        'CustomColumns': sortedCustom,
      };
    } else {
      final c1 = _workingMandatory['C1'] ?? '';
      config = {
        'KeyName': currentKey,
        'KeyType': 'Dynamic',
        'SelectedColumns': selCols,
        'C1': {
          'ColumnName': resolveCol(c1),
          'SourceName': resolveSource(c1),
          'isUniqueField': _localUniqueFields[c1] ?? false,
        },
        'CustomColumns': sortedCustom,
      };
    }

    // Snapshot current canvas state so per-key preview and API submission remain
    // accurate after the canvas is cleared for the next output key.
    final snapshotSrcs = widget.sourceNodes.asMap().entries.map((se) {
      final s = se.value;
      return {
        'idx': se.key,
        'id': s.id,
        'name': s.name,
        'sourceTypeValue': s.sourceTypeValue,
        'sourceTypeId': s.sourceTypeId,
        'separator': s.separator,
        'fileName': s.fileName,
        'queryFileName': s.queryFileName,
        'cols': List<String>.from(s.cols),
        'selectedCols': List<String>.from(s.selectedCols),
        'columnUniqueFields': Map<String, dynamic>.from(s.columnUniqueFields),
        'columnAliases': Map<String, dynamic>.from(s.columnAliases),
        'columnPriorities': Map<String, dynamic>.from(s.columnPriorities),
        'columnFileBytes': s.columnFileBytes,
        'queryFileBytes': s.queryFileBytes,
      };
    }).toList();

    final snapJoinNodes = ctrl.nodes
        .where((n) => n.type == NodeType.join)
        .toList();
    int snapMidx = 0;
    final snapshotJoinMappings = <Map<String, dynamic>>[];
    for (final j in snapJoinNodes) {
      for (final m in j.mappings.where((m) => m.isValid)) {
        final lSrc = ctrl.findNode(m.leftSourceId);
        final rSrc = ctrl.findNode(m.rightSourceId);
        snapshotJoinMappings.add({
          'idx': snapMidx++,
          'joinNodeId': j.id,
          'leftSourceId': m.leftSourceId,
          'leftSourceName': lSrc?.name ?? '',
          'leftCol': m.leftCol,
          'joinType': m.joinType,
          'rightSourceId': m.rightSourceId,
          'rightSourceName': rSrc?.name ?? '',
          'rightCol': m.rightCol,
        });
      }
    }

    final snapshotEdges = ctrl.edges
        .map((e) => {'fromNodeId': e.fromNodeId, 'toNodeId': e.toNodeId})
        .toList();

    final snapshotConnected = <Map<String, dynamic>>[];
    for (final j in snapJoinNodes) {
      for (final edge in ctrl.edges.where((e) => e.toNodeId == j.id)) {
        snapshotConnected.add({
          'joinNodeId': j.id,
          'sourceId': edge.fromNodeId,
        });
      }
    }

    config['_snapshotSources'] = snapshotSrcs;
    config['_snapshotJoinMappings'] = snapshotJoinMappings;
    config['_snapshotEdges'] = snapshotEdges;
    config['_snapshotConnected'] = snapshotConnected;

    ctrl.saveOutputKeyConfig(currentKey, config);
    setState(_resetFormValues);

    if (!ctrl.allDynamicUniMailingKeysConfigured) {
      // Compute the next key NOW while the widget is still mounted.
      final allKeys = ctrl.dynamicUniMailingOutputKeys;
      final nextKey = allKeys
          .where((k) => !ctrl.savedOutputKeyConfigs.containsKey(k))
          .firstOrNull;
      final keyIndex = nextKey != null ? allKeys.indexOf(nextKey) : -1;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // Show dialog BEFORE clearing — widget is still mounted here.
        // Canvas clear unmounts this widget, so we must dialog first.
        if (nextKey != null && keyIndex >= 0) {
          await _showNextKeyDialog(
            completedKey: currentKey,
            nextKeyNumber: keyIndex + 1,
            nextKeyName: nextKey,
          );
        }
        // After user dismisses (or if no dialog), clear the canvas.
        if (mounted) ctrl.clearCanvasForNextOutputKey();
      });
    }
    // If all keys done: canvas stays, Submit button activates.
  }

  Future<void> _showNextKeyDialog({
    required String completedKey,
    required int nextKeyNumber,
    required String nextKeyName,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.12),
              ),
              child: Center(
                child: Text(
                  '$nextKeyNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Key Configuration',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completed key
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.green.withValues(alpha: 0.12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Completed configuration for:',
                  style: TextStyle(fontSize: 11, color: AppColors.textDim),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.green.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.20),
                ),
              ),
              child: Text(
                completedKey,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Divider
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            // Next key
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      '$nextKeyNumber',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Now configure:',
                  style: TextStyle(fontSize: 11, color: AppColors.textDim),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.blue.withValues(alpha: 0.07),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.20),
                ),
              ),
              child: Text(
                nextKeyName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add your source nodes and configure the mappings for this key.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Got it',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _buildColLabels() {
    final multi = widget.sourceNodes.length > 1;
    final labels = <String, String>{};
    for (final n in widget.sourceNodes) {
      for (final c in n.cols) {
        final k = '${n.id}::$c';
        labels[k] = multi ? '${n.name} › $c' : c;
      }
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final keys = ctrl.dynamicUniMailingOutputKeys;
    final configured = ctrl.savedOutputKeyConfigs;
    final currentKey = ctrl.selectedOutputKey;
    final progress = configured.length;
    final total = keys.length;
    final progressColor = progress == total ? AppColors.green : AppColors.amber;

    final sourcesWithCols = widget.sourceNodes
        .where((n) => n.cols.isNotEmpty)
        .toList();
    final colLabels = _buildColLabels();
    final availForMapping = _localSelected.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress header
        Row(
          children: [
            Icon(Icons.email_rounded, size: 12, color: progressColor),
            const SizedBox(width: 5),
            Text(
              'DYNAMIC UNIMAILING KEYS',
              style: TextStyle(
                color: progressColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: progressColor.withValues(alpha: 0.10),
                border: Border.all(
                  color: progressColor.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '$progress / $total configured',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── All configured: show summary list ──
        if (progress == total) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.green.withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              children: keys.asMap().entries.map((e) {
                final i = e.key;
                final k = e.value;
                final cfg = configured[k];
                final keyType = cfg?['KeyType'] as String? ?? '';
                final isLast = i == keys.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: isLast
                        ? (i == 0
                              ? BorderRadius.circular(8)
                              : const BorderRadius.vertical(
                                  bottom: Radius.circular(8),
                                ))
                        : (i == 0
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                )
                              : null),
                    color: i.isEven
                        ? AppColors.green.withValues(alpha: 0.04)
                        : AppColors.surface,
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(
                              color: AppColors.border,
                              width: 0.8,
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          k,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (keyType.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.green.withValues(alpha: 0.10),
                            border: Border.all(
                              color: AppColors.green.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            keyType.toLowerCase(),
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ] else ...[
          // ── Body: driven by sidebar selectedOutputKey ──
          if (currentKey.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface2,
                border: Border.all(color: AppColors.border2),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select an output key from the sidebar to configure.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ── Step A: Column Selection + Unique Field (per source) ──
            DynUniColSelectionCard(
              sources: sourcesWithCols,
              localSelected: Set.from(_localSelected),
              localUniqueFields: Map.from(_localUniqueFields),
              onToggle: (key) {
                setState(() {
                  if (_localSelected.contains(key)) {
                    _localSelected.remove(key);
                    _localUniqueFields.remove(key);
                    _workingMandatory.removeWhere((_, v) => v == key);
                    _workingCustom.removeWhere((_, v) => v == key);
                  } else {
                    _localSelected.add(key);
                  }
                });
              },
              onUniqueFieldChanged: (key, val) =>
                  setState(() => _localUniqueFields[key] = val),
            ),
            const SizedBox(height: 10),

            // ── Step B: Mapping (Static or Dynamic) ──
            if (_isCurrentKeyStatic)
              StaticKeyMappingCard(
                workingMandatory: Map.from(_workingMandatory),
                workingCustom: Map.from(_workingCustom),
                customCount: _customCount,
                availableKeys: availForMapping,
                colLabels: colLabels,
                onMandatoryChanged: (f, v) =>
                    setState(() => _workingMandatory[f] = v ?? ''),
                onCustomChanged: (s, v) =>
                    setState(() => _workingCustom[s] = v ?? ''),
                onAddCustom: () => setState(() => _customCount++),
                onRemoveCustom: () {
                  _workingCustom.remove('C$_customCount');
                  setState(() => _customCount--);
                },
              )
            else
              DynamicKeyMappingCard(
                workingMandatory: Map.from(_workingMandatory),
                workingCustom: Map.from(_workingCustom),
                customCount: _customCount,
                availableKeys: availForMapping,
                colLabels: colLabels,
                onC0Changed: (v) =>
                    setState(() => _workingMandatory['C0'] = v ?? ''),
                onC1Changed: (v) =>
                    setState(() => _workingMandatory['C1'] = v ?? ''),
                onCustomChanged: (s, v) =>
                    setState(() => _workingCustom[s] = v ?? ''),
                onAddCustom: () => setState(() => _customCount++),
                onRemoveCustom: () {
                  _workingCustom.remove('C${_customCount + 1}');
                  setState(() => _customCount--);
                },
              ),
            const SizedBox(height: 10),

            // ── Action buttons ──
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _canSave ? _save : null,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _canSave ? 1.0 : 0.48,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: _canSave
                                ? [
                                    AppColors.blue,
                                    AppColors.blue.withValues(alpha: 0.8),
                                  ]
                                : [AppColors.border2, AppColors.border2],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Add $currentKey',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _clearForm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surface2,
                      border: Border.all(color: AppColors.border2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 13,
                          color: AppColors.textDim,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Clear',
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ], // closes inner else (currentKey form)
        ], // closes outer else (progress < total)
      ],
    );
  }
}
