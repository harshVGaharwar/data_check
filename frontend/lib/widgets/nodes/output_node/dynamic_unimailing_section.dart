part of '../output_node_body.dart';

// ═════════════════════════════════════════════════════════════════════════════
// 3RD CASE: Dynamic + UniMailing + noOfOutputKey(n)
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// DYNAMIC UNIMAILING OUTPUT SECTION
// Main section shown in Output Preview Node Body when all 3 conditions met.
// ─────────────────────────────────────────────────────────────────────────────

class _DynamicUniMailingOutputSection extends StatefulWidget {
  final PipelineController ctrl;
  final List<PipelineNode> sourceNodes;
  const _DynamicUniMailingOutputSection({
    required this.ctrl,
    required this.sourceNodes,
  });

  @override
  State<_DynamicUniMailingOutputSection> createState() =>
      _DynamicUniMailingOutputSectionState();
}

class _DynamicUniMailingOutputSectionState
    extends State<_DynamicUniMailingOutputSection> {
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
    _customCount = 0;
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
      return _kMandatoryFields.every(
        (f) =>
            (_workingMandatory[f] ?? '').isNotEmpty &&
            _localSelected.contains(_workingMandatory[f]),
      );
    } else {
      final c0 = _workingMandatory['C0'] ?? '';
      final c1 = _workingMandatory['C1'] ?? '';
      return c0.isNotEmpty &&
          _localSelected.contains(c0) &&
          c1.isNotEmpty &&
          _localSelected.contains(c1);
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
        'MandatoryFields': _kMandatoryFields
            .where((f) => (_workingMandatory[f] ?? '').isNotEmpty)
            .map(
              (f) => {
                'Field': f,
                'ColumnName': resolveCol(_workingMandatory[f]!),
                'SourceName': resolveSource(_workingMandatory[f]!),
                'isUniqueField':
                    _localUniqueFields[_workingMandatory[f]!] ?? false,
              },
            )
            .toList(),
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

    final snapJoinNodes =
        ctrl.nodes.where((n) => n.type == NodeType.join).toList();
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
        snapshotConnected
            .add({'joinNodeId': j.id, 'sourceId': edge.fromNodeId});
      }
    }

    config['_snapshotSources'] = snapshotSrcs;
    config['_snapshotJoinMappings'] = snapshotJoinMappings;
    config['_snapshotEdges'] = snapshotEdges;
    config['_snapshotConnected'] = snapshotConnected;

    ctrl.saveOutputKeyConfig(currentKey, config);
    setState(_resetFormValues);

    if (!ctrl.allDynamicUniMailingKeysConfigured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ctrl.clearCanvasForNextOutputKey();
      });
    }
    // If all keys done: canvas stays, Submit button activates.
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
            _DynUniColSelectionCard(
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
              _StaticKeyMappingCard(
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
              _DynamicKeyMappingCard(
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

// ─────────────────────────────────────────────────────────────────────────────
// STEP A: Per-key column selection card
// ─────────────────────────────────────────────────────────────────────────────

class _DynUniColSelectionCard extends StatelessWidget {
  final List<PipelineNode> sources;
  final Set<String> localSelected; // 'nodeId::colName'
  final Map<String, bool> localUniqueFields;
  final ValueChanged<String> onToggle;
  final void Function(String key, bool val) onUniqueFieldChanged;

  const _DynUniColSelectionCard({
    required this.sources,
    required this.localSelected,
    required this.localUniqueFields,
    required this.onToggle,
    required this.onUniqueFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalSelected = localSelected.length;
    final totalCols = sources.fold<int>(0, (sum, n) => sum + n.cols.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.checklist_rounded,
              size: 11,
              color: AppColors.blue,
            ),
            const SizedBox(width: 4),
            const Text(
              'STEP A — SELECT COLUMNS',
              style: TextStyle(
                color: AppColors.blue,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            // Total selected badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: totalSelected > 0
                    ? AppColors.blue.withValues(alpha: 0.12)
                    : AppColors.surface2,
                border: Border.all(
                  color: totalSelected > 0
                      ? AppColors.blue.withValues(alpha: 0.30)
                      : AppColors.border2,
                ),
              ),
              child: Text(
                '$totalSelected / $totalCols selected',
                style: TextStyle(
                  color: totalSelected > 0
                      ? AppColors.blue
                      : AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (sources.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No source columns available — upload a column file to sources first',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          )
        else
          for (final src in sources) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
                color: AppColors.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.table_chart_rounded,
                        size: 12,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          src.name,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Quick All / None buttons
                      GestureDetector(
                        onTap: () {
                          for (final c in src.cols) {
                            final k = '${src.id}::$c';
                            if (!localSelected.contains(k)) onToggle(k);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.blue.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.blue.withValues(alpha: 0.22),
                            ),
                          ),
                          child: const Text(
                            'All',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          for (final c in src.cols) {
                            final k = '${src.id}::$c';
                            if (localSelected.contains(k)) onToggle(k);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.surface2,
                            border: Border.all(color: AppColors.border2),
                          ),
                          child: const Text(
                            'None',
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${src.cols.where((c) => localSelected.contains('${src.id}::$c')).length}'
                        '/${src.cols.length}',
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: src.cols.map((col) {
                      final k = '${src.id}::$col';
                      final sel = localSelected.contains(k);
                      return GestureDetector(
                        onTap: () => onToggle(k),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: sel ? AppColors.blue : AppColors.bg,
                            border: Border.all(
                              color: sel ? AppColors.blue : AppColors.border2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (sel) ...[
                                const Icon(
                                  Icons.check_rounded,
                                  size: 9,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                col,
                                style: TextStyle(
                                  color: sel ? Colors.white : AppColors.textDim,
                                  fontSize: 9,
                                  fontFamily: AppTextStyles.monoFamily,
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // ── Per-source Unique Field table ──
                  Builder(
                    builder: (_) {
                      final selCols = src.cols
                          .where((c) => localSelected.contains('${src.id}::$c'))
                          .toList();
                      if (selCols.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                    color: AppColors.bg,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 9,
                                        color: AppColors.textMuted,
                                      ),
                                      SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Column',
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          'Unique Field',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.amber,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...selCols.asMap().entries.map((e) {
                                  final i = e.key;
                                  final col = e.value;
                                  final k = '${src.id}::$col';
                                  final isLast = i == selCols.length - 1;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: isLast
                                          ? const BorderRadius.vertical(
                                              bottom: Radius.circular(7),
                                            )
                                          : null,
                                      border: isLast
                                          ? null
                                          : const Border(
                                              bottom: BorderSide(
                                                color: AppColors.border,
                                                width: 0.8,
                                              ),
                                            ),
                                      color: i.isEven
                                          ? AppColors.surface
                                          : AppColors.surface2.withValues(
                                              alpha: 0.5,
                                            ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.circle,
                                          size: 5,
                                          color: AppColors.textDim,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            col,
                                            style: const TextStyle(
                                              color: AppColors.textDim,
                                              fontSize: 9,
                                              fontFamily:
                                                  AppTextStyles.monoFamily,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 70,
                                          child: Checkbox(
                                            value:
                                                localUniqueFields[k] ?? false,
                                            onChanged: (v) =>
                                                onUniqueFieldChanged(
                                                  k,
                                                  v ?? false,
                                                ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            activeColor: AppColors.amber,
                                            side: const BorderSide(
                                              color: AppColors.border2,
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            if (src != sources.last) const SizedBox(height: 6),
          ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP B (Static key): 7 mandatory fields + C1–C50 optional
// ─────────────────────────────────────────────────────────────────────────────

class _StaticKeyMappingCard extends StatelessWidget {
  final Map<String, String> workingMandatory;
  final Map<String, String> workingCustom;
  final int customCount;
  final List<String> availableKeys;
  final Map<String, String> colLabels;
  final void Function(String field, String? val) onMandatoryChanged;
  final void Function(String slot, String? val) onCustomChanged;
  final VoidCallback onAddCustom;
  final VoidCallback onRemoveCustom;

  const _StaticKeyMappingCard({
    required this.workingMandatory,
    required this.workingCustom,
    required this.customCount,
    required this.availableKeys,
    required this.colLabels,
    required this.onMandatoryChanged,
    required this.onCustomChanged,
    required this.onAddCustom,
    required this.onRemoveCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step B header
        Row(
          children: [
            const Icon(
              Icons.settings_rounded,
              size: 11,
              color: AppColors.amber,
            ),
            const SizedBox(width: 4),
            const Text(
              'STEP B — STATIC MAPPING',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 7 Mandatory fields
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 10, color: AppColors.red),
            const SizedBox(width: 4),
            const Text(
              'MANDATORY (7 fields)',
              style: TextStyle(
                color: AppColors.red,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _kMandatoryFields.asMap().entries.map((e) {
              final idx = e.key;
              final field = e.value;
              final isLast = idx == _kMandatoryFields.length - 1;
              final cur = workingMandatory[field] ?? '';
              final isMapped = cur.isNotEmpty && availableKeys.contains(cur);
              return _UniMappingRow(
                label: field,
                labelColor: AppColors.red,
                currentKey: isMapped ? cur : null,
                availableKeys: availableKeys,
                colLabels: colLabels,
                isLast: isLast,
                isRequired: true,
                isMapped: isMapped,
                onChanged: (v) => onMandatoryChanged(field, v),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // C1–C50 optional
        Row(
          children: [
            const Icon(
              Icons.add_box_outlined,
              size: 10,
              color: AppColors.violet,
            ),
            const SizedBox(width: 4),
            const Text(
              'OPTIONAL (C1–C50)',
              style: TextStyle(
                color: AppColors.violet,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (customCount < 50)
              GestureDetector(
                onTap: onAddCustom,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppColors.violet.withValues(alpha: 0.10),
                    border: Border.all(
                      color: AppColors.violet.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    '+ C${customCount + 1}',
                    style: const TextStyle(
                      color: AppColors.violet,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        if (customCount > 0)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(customCount, (i) {
                final slot = i + 1;
                final key = 'C$slot';
                final cur = workingCustom[key] ?? '';
                final isMapped = cur.isNotEmpty && availableKeys.contains(cur);
                final isLast = slot == customCount;
                return _UniMappingRow(
                  label: key,
                  labelColor: AppColors.violet,
                  currentKey: isMapped ? cur : null,
                  availableKeys: availableKeys,
                  colLabels: colLabels,
                  isLast: isLast,
                  isRequired: false,
                  isMapped: isMapped,
                  onChanged: (v) => onCustomChanged(key, v),
                  onDelete: isLast ? onRemoveCustom : null,
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP B (Dynamic key): C0 + C1 mandatory + C2–C20 optional
// ─────────────────────────────────────────────────────────────────────────────

class _DynamicKeyMappingCard extends StatelessWidget {
  final Map<String, String> workingMandatory;
  final Map<String, String> workingCustom;
  final int customCount; // number of optional slots after C1 (0 = none, max 19)
  final List<String> availableKeys;
  final Map<String, String> colLabels;
  final ValueChanged<String?> onC0Changed;
  final ValueChanged<String?> onC1Changed;
  final void Function(String slot, String? val) onCustomChanged;
  final VoidCallback onAddCustom;
  final VoidCallback onRemoveCustom;

  const _DynamicKeyMappingCard({
    required this.workingMandatory,
    required this.workingCustom,
    required this.customCount,
    required this.availableKeys,
    required this.colLabels,
    required this.onC0Changed,
    required this.onC1Changed,
    required this.onCustomChanged,
    required this.onAddCustom,
    required this.onRemoveCustom,
  });

  @override
  Widget build(BuildContext context) {
    final c0 = workingMandatory['C0'] ?? '';
    final c0Mapped = c0.isNotEmpty && availableKeys.contains(c0);
    final c1 = workingMandatory['C1'] ?? '';
    final c1Mapped = c1.isNotEmpty && availableKeys.contains(c1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step B header
        Row(
          children: [
            const Icon(
              Icons.settings_rounded,
              size: 11,
              color: AppColors.amber,
            ),
            const SizedBox(width: 4),
            const Text(
              'STEP B — DYNAMIC MAPPING',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // C0 + C1 mandatory
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 10, color: AppColors.red),
            const SizedBox(width: 4),
            const Text(
              'MANDATORY (C0, C1)',
              style: TextStyle(
                color: AppColors.red,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _UniMappingRow(
                label: 'C0',
                labelColor: AppColors.red,
                currentKey: c0Mapped ? c0 : null,
                availableKeys: availableKeys,
                colLabels: colLabels,
                isLast: false,
                isRequired: true,
                isMapped: c0Mapped,
                onChanged: onC0Changed,
              ),
              _UniMappingRow(
                label: 'C1',
                labelColor: AppColors.red,
                currentKey: c1Mapped ? c1 : null,
                availableKeys: availableKeys,
                colLabels: colLabels,
                isLast: true,
                isRequired: true,
                isMapped: c1Mapped,
                onChanged: onC1Changed,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // C2–C20 optional (max 19 slots)
        Row(
          children: [
            const Icon(
              Icons.add_box_outlined,
              size: 10,
              color: AppColors.violet,
            ),
            const SizedBox(width: 4),
            const Text(
              'OPTIONAL (C2–C20)',
              style: TextStyle(
                color: AppColors.violet,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (customCount < 19)
              GestureDetector(
                onTap: onAddCustom,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppColors.violet.withValues(alpha: 0.10),
                    border: Border.all(
                      color: AppColors.violet.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    '+ C${customCount + 2}',
                    style: const TextStyle(
                      color: AppColors.violet,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        if (customCount > 0)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(customCount, (i) {
                final slot = i + 2; // C2, C3, …
                final key = 'C$slot';
                final cur = workingCustom[key] ?? '';
                final isMapped = cur.isNotEmpty && availableKeys.contains(cur);
                final isLast = slot == customCount + 1;
                return _UniMappingRow(
                  label: key,
                  labelColor: AppColors.violet,
                  currentKey: isMapped ? cur : null,
                  availableKeys: availableKeys,
                  colLabels: colLabels,
                  isLast: isLast,
                  isRequired: false,
                  isMapped: isMapped,
                  onChanged: (v) => onCustomChanged(key, v),
                  onDelete: isLast ? onRemoveCustom : null,
                );
              }),
            ),
          ),
      ],
    );
  }
}
