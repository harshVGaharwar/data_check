// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/uni_mailing_shared.dart';
// import 'package:vizualizer/core/theme/app_theme.dart';
// import 'package:vizualizer/data/models/pipeline_models.dart';
// import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
// import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/dyn_uni_col_selection_card.dart';
// import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/dynamic_key_mapping_card.dart';
// import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/static_key_mapping_card.dart';

// class DynamicUniMailingOutputSection extends StatefulWidget {
//   final PipelineController ctrl;
//   final List<PipelineNode> sourceNodes;
//   final void Function(String lastKey)? onShowPreview;
//   const DynamicUniMailingOutputSection({
//     super.key,
//     required this.ctrl,
//     required this.sourceNodes,
//     this.onShowPreview,
//   });

//   @override
//   State<DynamicUniMailingOutputSection> createState() =>
//       _DynamicUniMailingOutputSectionState();
// }

// class _DynamicUniMailingOutputSectionState
//     extends State<DynamicUniMailingOutputSection> {
//   // No local key state — driven entirely by ctrl.selectedOutputKey (sidebar).
//   String _prevKey = '';
//   bool _saveSuccess = false;
//   Timer? _saveSuccessTimer;

//   // Working state for the key currently being configured
//   final Set<String> _localSelected = {}; // 'nodeId::colName'
//   final Map<String, String> _workingMandatory =
//       {}; // field/slot → 'nodeId::col'
//   final Map<String, String> _workingCustom = {}; // slot → 'nodeId::col'
//   final Map<String, bool> _localUniqueFields =
//       {}; // 'nodeId::colName' → isUnique
//   int _customCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _prevKey = widget.ctrl.selectedOutputKey;
//     widget.ctrl.addListener(_onCtrlChange);

//     final currentKey = widget.ctrl.selectedOutputKey;

//     if (widget.ctrl.savedOutputKeyConfigs.containsKey(currentKey) &&
//         !widget.ctrl.isOutputKeyFormCleared(currentKey)) {
//       // Widget is mounting on a previously saved key (canvas restore path).
//       // widget.sourceNodes already holds the restored node IDs, so restore
//       // the form synchronously here — no post-frame callback needed.
//       _restoreFormFromSavedConfig(currentKey);
//     } else if (currentKey.isNotEmpty) {
//       // Fresh unconfigured key — just init customCount.
//       _customCount = widget.ctrl.isOutputKeyStatic(currentKey) ? 1 : 0;
//     } else {
//       // No key selected yet — auto-select the next unconfigured key.
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//         final ctrl = widget.ctrl;
//         if (ctrl.selectedOutputKey.isEmpty) {
//           final keys = ctrl.dynamicUniMailingOutputKeys;
//           final next = keys
//               .where((k) => !ctrl.savedOutputKeyConfigs.containsKey(k))
//               .firstOrNull;
//           if (next != null) ctrl.setSelectedOutputKey(next);
//         }
//       });
//     }
//   }

//   void _onCtrlChange() {
//     final newKey = widget.ctrl.selectedOutputKey;
//     if (newKey != _prevKey) {
//       _prevKey = newKey;
//       _saveSuccessTimer?.cancel();
//       _saveSuccess = false;
//       // Clear first so no stale nodeId::col keys are visible for one frame.
//       setState(_resetFormValues);
//       // If this key was already configured AND not manually cleared, restore
//       // its form values after the canvas has been rebuilt with fresh node IDs.
//       if (widget.ctrl.savedOutputKeyConfigs.containsKey(newKey) &&
//           !widget.ctrl.isOutputKeyFormCleared(newKey)) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (!mounted) return;
//           setState(() => _restoreFormFromSavedConfig(newKey));
//         });
//       }
//     } else {
//       setState(() {});
//     }
//   }

//   /// Populates form state from [savedOutputKeyConfigs[key]] using the current
//   /// [widget.sourceNodes] (which have fresh IDs after canvas restore).
//   void _restoreFormFromSavedConfig(String key) {
//     final config = widget.ctrl.savedOutputKeyConfigs[key];
//     if (config == null) return;

//     _localSelected.clear();
//     _workingMandatory.clear();
//     _workingCustom.clear();
//     _localUniqueFields.clear();

//     final isStatic = widget.ctrl.isOutputKeyStatic(key);
//     // Build name → new node-id map from the controller's live source nodes.
//     // ctrl.nodes is always fresh (set synchronously in _restoreOutputKeySnapshot)
//     // whereas widget.sourceNodes may still be from the previous frame.
//     final nameToId = <String, String>{
//       for (final n in widget.ctrl.nodes.where((n) => n.type.isSource))
//         n.name: n.id,
//     };

//     // Restore selected columns.
//     final selCols =
//         (config['SelectedColumns'] as List?)
//             ?.whereType<Map<String, dynamic>>()
//             .toList() ??
//         [];
//     for (final sc in selCols) {
//       final nodeName = sc['NodeName']?.toString() ?? '';
//       final colName = sc['ColName']?.toString() ?? '';
//       final newId = nameToId[nodeName];
//       if (newId != null && colName.isNotEmpty) {
//         final selKey = '$newId::$colName';
//         _localSelected.add(selKey);
//         if (sc['isUniqueField'] == true) _localUniqueFields[selKey] = true;
//       }
//     }

//     if (isStatic) {
//       // Mandatory UniMailing fields.
//       final mandatoryList =
//           (config['MandatoryFields'] as List?)
//               ?.whereType<Map<String, dynamic>>()
//               .toList() ??
//           [];
//       for (final mf in mandatoryList) {
//         final field = mf['Field']?.toString() ?? '';
//         final sourceName = mf['SourceName']?.toString() ?? '';
//         final colName = mf['ColumnName']?.toString() ?? '';
//         if (field.isNotEmpty && colName.isNotEmpty) {
//           final newId = nameToId[sourceName];
//           if (newId != null) _workingMandatory[field] = '$newId::$colName';
//         }
//       }
//       // Custom columns — at least 1 slot always shown for static.
//       final customList =
//           (config['CustomColumns'] as List?)
//               ?.whereType<Map<String, dynamic>>()
//               .toList() ??
//           [];
//       _customCount = customList.isNotEmpty ? customList.length : 1;
//       for (final cc in customList) {
//         final slot = cc['Slot']?.toString() ?? '';
//         final sourceName = cc['SourceName']?.toString() ?? '';
//         final colName = cc['ColumnName']?.toString() ?? '';
//         if (slot.isNotEmpty && colName.isNotEmpty) {
//           final newId = nameToId[sourceName];
//           if (newId != null) _workingCustom[slot] = '$newId::$colName';
//         }
//       }
//     } else {
//       // Dynamic key — restore C0 and C1.
//       for (final slot in ['C0', 'C1']) {
//         final map = config[slot] as Map?;
//         if (map == null) continue;
//         final sourceName = map['SourceName']?.toString() ?? '';
//         final colName = map['ColumnName']?.toString() ?? '';
//         if (colName.isNotEmpty) {
//           final newId = nameToId[sourceName];
//           if (newId != null) _workingMandatory[slot] = '$newId::$colName';
//         }
//       }
//       // Custom columns.
//       final customList =
//           (config['CustomColumns'] as List?)
//               ?.whereType<Map<String, dynamic>>()
//               .toList() ??
//           [];
//       _customCount = customList.length;
//       for (final cc in customList) {
//         final slot = cc['Slot']?.toString() ?? '';
//         final sourceName = cc['SourceName']?.toString() ?? '';
//         final colName = cc['ColumnName']?.toString() ?? '';
//         if (slot.isNotEmpty && colName.isNotEmpty) {
//           final newId = nameToId[sourceName];
//           if (newId != null) _workingCustom[slot] = '$newId::$colName';
//         }
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _saveSuccessTimer?.cancel();
//     widget.ctrl.removeListener(_onCtrlChange);
//     super.dispose();
//   }

//   /// Mutates form fields directly — safe to call inside an existing setState.
//   void _resetFormValues() {
//     _localSelected.clear();
//     _workingMandatory.clear();
//     _workingCustom.clear();
//     _localUniqueFields.clear();
//     // Static key: Column 1 shown by default. Dynamic key: no default column.
//     _customCount = _isCurrentKeyStatic ? 1 : 0;
//   }

//   /// Standalone clear: mutates + triggers rebuild (use for the Clear button).
//   void _clearForm() {
//     final key = widget.ctrl.selectedOutputKey;
//     if (key.isNotEmpty) widget.ctrl.markOutputKeyFormCleared(key);
//     setState(_resetFormValues);
//   }

//   bool get _isCurrentKeyStatic =>
//       widget.ctrl.isOutputKeyStatic(widget.ctrl.selectedOutputKey);

//   bool get _canSave {
//     if (widget.ctrl.selectedOutputKey.isEmpty || _localSelected.isEmpty) {
//       return false;
//     }
//     if (_isCurrentKeyStatic) {
//       // All added custom columns must be mapped (Column 1 is always required)
//       final allCustomFilled = List.generate(_customCount, (i) {
//         final key = 'C${i + 1}';
//         final val = _workingCustom[key] ?? '';
//         return val.isNotEmpty && _localSelected.contains(val);
//       }).every((ok) => ok);
//       return allCustomFilled;
//     } else {
//       final c0 = _workingMandatory['C0'] ?? '';
//       final c1 = _workingMandatory['C1'] ?? '';
//       final mandatoryOk =
//           c0.isNotEmpty &&
//           _localSelected.contains(c0) &&
//           c1.isNotEmpty &&
//           _localSelected.contains(c1);
//       // All added optional columns (C2+) must also be filled
//       final allOptionalFilled = List.generate(_customCount, (i) {
//         final key = 'C${i + 2}';
//         final val = _workingCustom[key] ?? '';
//         return val.isNotEmpty && _localSelected.contains(val);
//       }).every((ok) => ok);
//       return mandatoryOk && allOptionalFilled;
//     }
//   }

//   void _save() {
//     final ctrl = widget.ctrl;
//     final currentKey = ctrl.selectedOutputKey;
//     if (currentKey.isEmpty) return;

//     String resolveCol(String key) =>
//         key.contains('::') ? key.split('::')[1] : key;
//     PipelineNode? resolveNode(String key) {
//       if (!key.contains('::')) return null;
//       final nid = key.split('::')[0];
//       return widget.sourceNodes.where((n) => n.id == nid).firstOrNull;
//     }

//     String resolveSource(String key) => resolveNode(key)?.name ?? '';

//     final selCols = _localSelected
//         .map(
//           (k) => {
//             'NodeId': k.split('::')[0],
//             'NodeName': resolveSource(k),
//             'ColName': resolveCol(k),
//             'isUniqueField': _localUniqueFields[k] ?? false,
//             'SourceTypeValue': resolveNode(k)?.sourceTypeValue ?? '',
//           },
//         )
//         .toList();

//     final sortedCustom =
//         _workingCustom.entries
//             .where(
//               (e) => e.value.isNotEmpty && _localSelected.contains(e.value),
//             )
//             .map(
//               (e) => {
//                 'Slot': e.key,
//                 'ColumnName': resolveCol(e.value),
//                 'SourceName': resolveSource(e.value),
//                 'isUniqueField': _localUniqueFields[e.value] ?? false,
//               },
//             )
//             .toList()
//           ..sort((a, b) {
//             final ai = int.tryParse((a['Slot'] as String).substring(1)) ?? 0;
//             final bi = int.tryParse((b['Slot'] as String).substring(1)) ?? 0;
//             return ai.compareTo(bi);
//           });

//     final Map<String, dynamic> config;
//     if (_isCurrentKeyStatic) {
//       config = {
//         'KeyName': currentKey,
//         'KeyType': 'Static',
//         'SelectedColumns': selCols,
//         // All 7 unimailing fields always sent; empty string if not mapped
//         'MandatoryFields': kMandatoryFields.map((f) {
//           final val = _workingMandatory[f] ?? '';
//           return {
//             'Field': f,
//             'ColumnName': val.isNotEmpty ? resolveCol(val) : '',
//             'SourceName': val.isNotEmpty ? resolveSource(val) : '',
//             'isUniqueField': val.isNotEmpty
//                 ? (_localUniqueFields[val] ?? false)
//                 : false,
//           };
//         }).toList(),
//         'CustomColumns': sortedCustom,
//       };
//     } else {
//       final c0 = _workingMandatory['C0'] ?? '';
//       final c1 = _workingMandatory['C1'] ?? '';
//       config = {
//         'KeyName': currentKey,
//         'KeyType': 'Dynamic',
//         'SelectedColumns': selCols,
//         'C0': {
//           'ColumnName': resolveCol(c0),
//           'SourceName': resolveSource(c0),
//           'isUniqueField': _localUniqueFields[c0] ?? false,
//         },
//         'C1': {
//           'ColumnName': resolveCol(c1),
//           'SourceName': resolveSource(c1),
//           'isUniqueField': _localUniqueFields[c1] ?? false,
//         },
//         'CustomColumns': sortedCustom,
//       };
//     }

//     // Snapshot current canvas state so per-key preview and API submission remain
//     // accurate after the canvas is cleared for the next output key.
//     final snapshotSrcs = widget.sourceNodes.asMap().entries.map((se) {
//       final s = se.value;
//       return {
//         'idx': se.key,
//         'id': s.id,
//         'name': s.name,
//         'sourceTypeValue': s.sourceTypeValue,
//         'sourceTypeId': s.sourceTypeId,
//         'separator': s.separator,
//         'fileName': s.fileName,
//         'queryFileName': s.queryFileName,
//         'cols': List<String>.from(s.cols),
//         'selectedCols': _localSelected
//             .where((k) => k.split('::')[0] == s.id)
//             .map((k) => k.split('::')[1])
//             .toList(),
//         'columnUniqueFields': Map.fromEntries(
//           _localUniqueFields.entries
//               .where((e) => e.key.split('::')[0] == s.id)
//               .map((e) => MapEntry(e.key.split('::')[1], e.value)),
//         ),
//         'columnAliases': Map<String, dynamic>.from(s.columnAliases),
//         'columnPriorities': Map<String, dynamic>.from(s.columnPriorities),
//         'columnFileBytes': s.columnFileBytes,
//         'queryFileBytes': s.queryFileBytes,
//       };
//     }).toList();

//     final snapJoinNodes = ctrl.nodes
//         .where((n) => n.type == NodeType.join)
//         .toList();
//     int snapMidx = 0;
//     final snapshotJoinMappings = <Map<String, dynamic>>[];
//     for (final j in snapJoinNodes) {
//       for (final m in j.mappings.where((m) => m.isValid)) {
//         final lSrc = ctrl.findNode(m.leftSourceId);
//         final rSrc = ctrl.findNode(m.rightSourceId);
//         snapshotJoinMappings.add({
//           'idx': snapMidx++,
//           'joinNodeId': j.id,
//           'leftSourceId': m.leftSourceId,
//           'leftSourceName': lSrc?.name ?? '',
//           'leftCol': m.leftCol,
//           'joinType': m.joinType,
//           'rightSourceId': m.rightSourceId,
//           'rightSourceName': rSrc?.name ?? '',
//           'rightCol': m.rightCol,
//         });
//       }
//     }

//     final snapshotEdges = ctrl.edges
//         .map((e) => {'fromNodeId': e.fromNodeId, 'toNodeId': e.toNodeId})
//         .toList();

//     final snapshotConnected = <Map<String, dynamic>>[];
//     for (final j in snapJoinNodes) {
//       for (final edge in ctrl.edges.where((e) => e.toNodeId == j.id)) {
//         snapshotConnected.add({
//           'joinNodeId': j.id,
//           'sourceId': edge.fromNodeId,
//         });
//       }
//     }

//     config['_snapshotSources'] = snapshotSrcs;
//     config['_snapshotJoinMappings'] = snapshotJoinMappings;
//     config['_snapshotEdges'] = snapshotEdges;
//     config['_snapshotConnected'] = snapshotConnected;

//     // Capture BEFORE saving — if this key was already saved we are re-editing
//     // it, not doing a first-time configure. Re-edits should never trigger the
//     // "Next Key" dialog or clear the canvas for a different key.
//     final wasAlreadyConfigured = ctrl.savedOutputKeyConfigs.containsKey(
//       currentKey,
//     );

//     ctrl.saveOutputKeyConfig(currentKey, config);

//     if (!wasAlreadyConfigured && !ctrl.allDynamicUniMailingKeysConfigured) {
//       // First-time save of this key and more keys remain — advance workflow.
//       setState(_resetFormValues);
//       final allKeys = ctrl.dynamicUniMailingOutputKeys;
//       final nextKey = allKeys
//           .where((k) => !ctrl.savedOutputKeyConfigs.containsKey(k))
//           .firstOrNull;
//       final keyIndex = nextKey != null ? allKeys.indexOf(nextKey) : -1;

//       debugPrint(
//         '[NEXT_KEY] completedKey="$currentKey"'
//         ' | allKeys=$allKeys'
//         ' | nextKey="$nextKey"'
//         ' | savedKeys=${ctrl.savedOutputKeyConfigs.keys.toList()}'
//         ' | allConfigured=${ctrl.allDynamicUniMailingKeysConfigured}',
//       );
//       WidgetsBinding.instance.addPostFrameCallback((_) async {
//         if (!mounted) return;
//         if (nextKey != null && keyIndex >= 0) {
//           await _showNextKeyDialog(
//             completedKey: currentKey,
//             nextKeyNumber: keyIndex + 1,
//             nextKeyName: nextKey,
//           );
//         }
//         if (mounted) ctrl.clearCanvasForNextOutputKey();
//       });
//     } else if (!wasAlreadyConfigured) {
//       // Last key saved for the first time — deselect and show preview.
//       ctrl.clearSelectedOutputKey();
//       final keys = ctrl.dynamicUniMailingOutputKeys;
//       if (keys.isNotEmpty && currentKey == keys.last) {
//         final lastKey = currentKey;
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) widget.onShowPreview?.call(lastKey);
//         });
//       }
//     } else {
//       // Re-edit of an already-saved key — flash the button to confirm save.
//       _saveSuccessTimer?.cancel();
//       setState(() => _saveSuccess = true);
//       _saveSuccessTimer = Timer(const Duration(milliseconds: 1500), () {
//         if (mounted) setState(() => _saveSuccess = false);
//       });
//       // Also show preview if this is the last key (only trigger available).
//       final keys = ctrl.dynamicUniMailingOutputKeys;
//       if (keys.isNotEmpty && currentKey == keys.last) {
//         final lastKey = currentKey;
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) widget.onShowPreview?.call(lastKey);
//         });
//       }
//     }
//   }

//   Future<void> _showNextKeyDialog({
//     required String completedKey,
//     required int nextKeyNumber,
//     required String nextKeyName,
//   }) async {
//     if (!mounted) return;
//     final allKeys = widget.ctrl.dynamicUniMailingOutputKeys;
//     final total = allKeys.length;
//     final completedCount = nextKeyNumber - 1;

//     await showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => Center(
//         child: Material(
//           color: Colors.transparent,
//           child: Container(
//             width: 360,
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.18),
//                   blurRadius: 24,
//                   offset: const Offset(0, 8),
//                 ),
//               ],
//             ),
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── Header ──
//                 Row(
//                   children: [
//                     Container(
//                       width: 38,
//                       height: 38,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: AppColors.blue.withValues(alpha: 0.10),
//                       ),
//                       child: const Icon(
//                         Icons.key_rounded,
//                         size: 17,
//                         color: AppColors.blue,
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Key configuration',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w700,
//                             color: AppColors.text,
//                           ),
//                         ),
//                         Text(
//                           'Step $nextKeyNumber of $total',
//                           style: const TextStyle(
//                             fontSize: 11,
//                             color: AppColors.textMuted,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 14),

//                 // ── COMPLETED label ──
//                 Row(
//                   children: const [
//                     Icon(
//                       Icons.check_circle_outline_rounded,
//                       size: 12,
//                       color: AppColors.green,
//                     ),
//                     SizedBox(width: 4),
//                     Text(
//                       'COMPLETED',
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.green,
//                         letterSpacing: 0.6,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 5),

//                 // ── Completed key card ──
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(9),
//                     color: AppColors.green.withValues(alpha: 0.06),
//                     border: Border.all(
//                       color: AppColors.green.withValues(alpha: 0.20),
//                     ),
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 11,
//                     vertical: 9,
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.check_rounded,
//                         size: 14,
//                         color: AppColors.green,
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               completedKey,
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w700,
//                                 color: AppColors.text,
//                               ),
//                             ),
//                             const Text(
//                               'Mapping saved',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 color: AppColors.textMuted,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 7,
//                           vertical: 3,
//                         ),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(5),
//                           color: AppColors.green.withValues(alpha: 0.13),
//                         ),
//                         child: const Text(
//                           'Done',
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.green,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 10),

//                 // ── Progress bar ──
//                 Row(
//                   children: List.generate(total, (i) {
//                     final Color segColor;
//                     if (i < completedCount) {
//                       segColor = AppColors.green;
//                     } else if (i == completedCount) {
//                       segColor = AppColors.blue;
//                     } else {
//                       segColor = AppColors.border2;
//                     }
//                     return Expanded(
//                       child: Container(
//                         margin: EdgeInsets.only(right: i < total - 1 ? 3 : 0),
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: segColor,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     );
//                   }),
//                 ),
//                 const SizedBox(height: 14),

//                 // ── Footer ──
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: ElevatedButton(
//                     onPressed: () => Navigator.of(ctx).pop(),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.blue,
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 9,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: const [
//                         Text(
//                           'Got it',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 13,
//                           ),
//                         ),
//                         SizedBox(width: 5),
//                         Icon(Icons.arrow_forward_rounded, size: 13),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Map<String, String> _buildColLabels() {
//     final multi = widget.sourceNodes.length > 1;
//     final labels = <String, String>{};
//     for (final n in widget.sourceNodes) {
//       for (final c in n.cols) {
//         final k = '${n.id}::$c';
//         labels[k] = multi ? '${n.name} › $c' : c;
//       }
//     }
//     return labels;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = widget.ctrl;
//     final keys = ctrl.dynamicUniMailingOutputKeys;
//     final configured = ctrl.savedOutputKeyConfigs;
//     final currentKey = ctrl.selectedOutputKey;
//     final progress = configured.length;
//     final total = keys.length;
//     final progressColor = progress == total ? AppColors.green : AppColors.amber;

//     final sourcesWithCols = widget.sourceNodes
//         .where((n) => n.cols.isNotEmpty)
//         .toList();
//     final colLabels = _buildColLabels();
//     final availForMapping = _localSelected.toList();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Progress header
//         Row(
//           children: [
//             Icon(Icons.email_rounded, size: 12, color: progressColor),
//             const SizedBox(width: 5),
//             Text(
//               'DYNAMIC UNIMAILING KEYS',
//               style: TextStyle(
//                 color: progressColor,
//                 fontSize: 9,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 0.7,
//               ),
//             ),
//             const Spacer(),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(10),
//                 color: progressColor.withValues(alpha: 0.10),
//                 border: Border.all(
//                   color: progressColor.withValues(alpha: 0.25),
//                 ),
//               ),
//               child: Text(
//                 '$progress / $total configured',
//                 style: TextStyle(
//                   color: progressColor,
//                   fontSize: 9,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),

//         // ── Body: driven by sidebar selectedOutputKey ──
//         if (currentKey.isEmpty) ...[
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               color: progress == total
//                   ? AppColors.green.withValues(alpha: 0.06)
//                   : AppColors.surface2,
//               border: Border.all(
//                 color: progress == total
//                     ? AppColors.green.withValues(alpha: 0.30)
//                     : AppColors.border2,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   progress == total
//                       ? Icons.check_circle_rounded
//                       : Icons.info_outline_rounded,
//                   size: 14,
//                   color: progress == total
//                       ? AppColors.green
//                       : AppColors.textMuted,
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     progress == total
//                         ? 'All $total keys configured. Select a key from the sidebar to review or edit.'
//                         : 'Select an output key from the sidebar to configure.',
//                     style: TextStyle(
//                       color: progress == total
//                           ? AppColors.green
//                           : AppColors.textMuted,
//                       fontSize: 11,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ] else ...[
//           // ── Step A: Column Selection + Unique Field (per source) ──
//           DynUniColSelectionCard(
//             sources: sourcesWithCols,
//             localSelected: Set.from(_localSelected),
//             localUniqueFields: Map.from(_localUniqueFields),
//             onToggle: (key) {
//               setState(() {
//                 if (_localSelected.contains(key)) {
//                   _localSelected.remove(key);
//                   _localUniqueFields.remove(key);
//                   _workingMandatory.removeWhere((_, v) => v == key);
//                   _workingCustom.removeWhere((_, v) => v == key);
//                 } else {
//                   _localSelected.add(key);
//                 }
//               });
//             },
//             onUniqueFieldChanged: (key, val) =>
//                 setState(() => _localUniqueFields[key] = val),
//           ),
//           const SizedBox(height: 10),

//           // ── Step B: Mapping (Static or Dynamic) ──
//           if (_isCurrentKeyStatic)
//             StaticKeyMappingCard(
//               workingMandatory: Map.from(_workingMandatory),
//               workingCustom: Map.from(_workingCustom),
//               customCount: _customCount,
//               availableKeys: availForMapping,
//               colLabels: colLabels,
//               onMandatoryChanged: (f, v) =>
//                   setState(() => _workingMandatory[f] = v ?? ''),
//               onCustomChanged: (s, v) =>
//                   setState(() => _workingCustom[s] = v ?? ''),
//               onAddCustom: () => setState(() => _customCount++),
//               onRemoveCustom: () {
//                 _workingCustom.remove('C$_customCount');
//                 setState(() => _customCount--);
//               },
//             )
//           else
//             DynamicKeyMappingCard(
//               workingMandatory: Map.from(_workingMandatory),
//               workingCustom: Map.from(_workingCustom),
//               customCount: _customCount,
//               availableKeys: availForMapping,
//               colLabels: colLabels,
//               onC0Changed: (v) =>
//                   setState(() => _workingMandatory['C0'] = v ?? ''),
//               onC1Changed: (v) =>
//                   setState(() => _workingMandatory['C1'] = v ?? ''),
//               onCustomChanged: (s, v) =>
//                   setState(() => _workingCustom[s] = v ?? ''),
//               onAddCustom: () => setState(() => _customCount++),
//               onRemoveCustom: () {
//                 _workingCustom.remove('C${_customCount + 1}');
//                 setState(() => _customCount--);
//               },
//             ),
//           const SizedBox(height: 10),

//           // ── Action buttons ──
//           Row(
//             children: [
//               Expanded(
//                 child: GestureDetector(
//                   onTap: _canSave ? _save : null,
//                   child: AnimatedOpacity(
//                     duration: const Duration(milliseconds: 150),
//                     opacity: _canSave ? 1.0 : 0.48,
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       padding: const EdgeInsets.symmetric(vertical: 9),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         gradient: LinearGradient(
//                           colors: _saveSuccess
//                               ? [
//                                   AppColors.green,
//                                   AppColors.green.withValues(alpha: 0.8),
//                                 ]
//                               : _canSave
//                               ? [
//                                   AppColors.blue,
//                                   AppColors.blue.withValues(alpha: 0.8),
//                                 ]
//                               : [AppColors.border2, AppColors.border2],
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             _saveSuccess
//                                 ? Icons.check_circle_rounded
//                                 : Icons.add_circle_outline_rounded,
//                             size: 13,
//                             color: Colors.white,
//                           ),
//                           const SizedBox(width: 5),
//                           Text(
//                             _saveSuccess ? 'Saved ✓' : 'Add $currentKey',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 11,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               GestureDetector(
//                 onTap: _clearForm,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 9,
//                   ),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     color: AppColors.surface2,
//                     border: Border.all(color: AppColors.border2),
//                   ),
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.refresh_rounded,
//                         size: 13,
//                         color: AppColors.textDim,
//                       ),
//                       SizedBox(width: 4),
//                       Text(
//                         'Clear',
//                         style: TextStyle(
//                           color: AppColors.textDim,
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ], // closes inner else (currentKey form)
//       ],
//     );
//   }
// }




import 'dart:async';
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
  final void Function(String lastKey)? onShowPreview;
  const DynamicUniMailingOutputSection({
    super.key,
    required this.ctrl,
    required this.sourceNodes,
    this.onShowPreview,
  });

  @override
  State<DynamicUniMailingOutputSection> createState() =>
      _DynamicUniMailingOutputSectionState();
}

class _DynamicUniMailingOutputSectionState
    extends State<DynamicUniMailingOutputSection> {
  // No local key state — driven entirely by ctrl.selectedOutputKey (sidebar).
  String _prevKey = '';
  bool _saveSuccess = false;
  Timer? _saveSuccessTimer;

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

    final currentKey = widget.ctrl.selectedOutputKey;

    if (widget.ctrl.savedOutputKeyConfigs.containsKey(currentKey) &&
        !widget.ctrl.isOutputKeyFormCleared(currentKey)) {
      // Widget is mounting on a previously saved key (canvas restore path).
      // widget.sourceNodes already holds the restored node IDs, so restore
      // the form synchronously here — no post-frame callback needed.
      _restoreFormFromSavedConfig(currentKey);
    } else if (currentKey.isNotEmpty) {
      // Fresh unconfigured key — just init customCount.
      _customCount = widget.ctrl.isOutputKeyStatic(currentKey) ? 1 : 0;
    } else {
      // No key selected yet — auto-select the next unconfigured key.
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
      _prevKey = newKey;
      _saveSuccessTimer?.cancel();
      _saveSuccess = false;
      // Clear first so no stale nodeId::col keys are visible for one frame.
      setState(_resetFormValues);
      // If this key was already configured AND not manually cleared, restore
      // its form values after the canvas has been rebuilt with fresh node IDs.
      if (widget.ctrl.savedOutputKeyConfigs.containsKey(newKey) &&
          !widget.ctrl.isOutputKeyFormCleared(newKey)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _restoreFormFromSavedConfig(newKey));
        });
      }
    } else {
      setState(() {});
    }
  }

  /// Populates form state from [savedOutputKeyConfigs[key]] using the current
  /// [widget.sourceNodes] (which have fresh IDs after canvas restore).
  void _restoreFormFromSavedConfig(String key) {
    final config = widget.ctrl.savedOutputKeyConfigs[key];
    if (config == null) return;

    _localSelected.clear();
    _workingMandatory.clear();
    _workingCustom.clear();
    _localUniqueFields.clear();

    final isStatic = widget.ctrl.isOutputKeyStatic(key);
    // Build name → new node-id map from the controller's live source nodes.
    // ctrl.nodes is always fresh (set synchronously in _restoreOutputKeySnapshot)
    // whereas widget.sourceNodes may still be from the previous frame.
    final nameToId = <String, String>{
      for (final n in widget.ctrl.nodes.where((n) => n.type.isSource))
        n.name: n.id,
    };

    // Restore selected columns.
    final selCols = (config['SelectedColumns'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    for (final sc in selCols) {
      final nodeName = sc['NodeName']?.toString() ?? '';
      final colName = sc['ColName']?.toString() ?? '';
      final newId = nameToId[nodeName];
      if (newId != null && colName.isNotEmpty) {
        final selKey = '$newId::$colName';
        _localSelected.add(selKey);
        if (sc['isUniqueField'] == true) _localUniqueFields[selKey] = true;
      }
    }

    if (isStatic) {
      // Mandatory UniMailing fields.
      final mandatoryList = (config['MandatoryFields'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          [];
      for (final mf in mandatoryList) {
        final field = mf['Field']?.toString() ?? '';
        final sourceName = mf['SourceName']?.toString() ?? '';
        final colName = mf['ColumnName']?.toString() ?? '';
        if (field.isNotEmpty && colName.isNotEmpty) {
          final newId = nameToId[sourceName];
          if (newId != null) _workingMandatory[field] = '$newId::$colName';
        }
      }
      // Custom columns — at least 1 slot always shown for static.
      final customList = (config['CustomColumns'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          [];
      _customCount = customList.isNotEmpty ? customList.length : 1;
      for (final cc in customList) {
        final slot = cc['Slot']?.toString() ?? '';
        final sourceName = cc['SourceName']?.toString() ?? '';
        final colName = cc['ColumnName']?.toString() ?? '';
        if (slot.isNotEmpty && colName.isNotEmpty) {
          final newId = nameToId[sourceName];
          if (newId != null) _workingCustom[slot] = '$newId::$colName';
        }
      }
    } else {
      // Dynamic key — restore C0 and C1.
      for (final slot in ['C0', 'C1']) {
        final map = config[slot] as Map?;
        if (map == null) continue;
        final sourceName = map['SourceName']?.toString() ?? '';
        final colName = map['ColumnName']?.toString() ?? '';
        if (colName.isNotEmpty) {
          final newId = nameToId[sourceName];
          if (newId != null) _workingMandatory[slot] = '$newId::$colName';
        }
      }
      // Custom columns.
      final customList = (config['CustomColumns'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          [];
      _customCount = customList.length;
      for (final cc in customList) {
        final slot = cc['Slot']?.toString() ?? '';
        final sourceName = cc['SourceName']?.toString() ?? '';
        final colName = cc['ColumnName']?.toString() ?? '';
        if (slot.isNotEmpty && colName.isNotEmpty) {
          final newId = nameToId[sourceName];
          if (newId != null) _workingCustom[slot] = '$newId::$colName';
        }
      }
    }
  }

  @override
  void dispose() {
    _saveSuccessTimer?.cancel();
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
  void _clearForm() {
    final key = widget.ctrl.selectedOutputKey;
    if (key.isNotEmpty) widget.ctrl.markOutputKeyFormCleared(key);
    setState(_resetFormValues);
  }

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
      final mandatoryOk = c0.isNotEmpty &&
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

    final sortedCustom = _workingCustom.entries
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
            'isUniqueField':
                val.isNotEmpty ? (_localUniqueFields[val] ?? false) : false,
          };
        }).toList(),
        'CustomColumns': sortedCustom,
      };
    } else {
      final c0 = _workingMandatory['C0'] ?? '';
      final c1 = _workingMandatory['C1'] ?? '';
      config = {
        'KeyName': currentKey,
        'KeyType': 'Dynamic',
        'SelectedColumns': selCols,
        'C0': {
          'ColumnName': resolveCol(c0),
          'SourceName': resolveSource(c0),
          'isUniqueField': _localUniqueFields[c0] ?? false,
        },
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
        'typeId': s.typeId,
        'separator': s.separator,
        'fileName': s.fileName,
        'queryFileName': s.queryFileName,
        'cols': List<String>.from(s.cols),
        'selectedCols': _localSelected
            .where((k) => k.split('::')[0] == s.id)
            .map((k) => k.split('::')[1])
            .toList(),
        'columnUniqueFields': Map.fromEntries(
          _localUniqueFields.entries
              .where((e) => e.key.split('::')[0] == s.id)
              .map((e) => MapEntry(e.key.split('::')[1], e.value)),
        ),
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

    // Capture BEFORE saving — if this key was already saved we are re-editing
    // it, not doing a first-time configure. Re-edits should never trigger the
    // "Next Key" dialog or clear the canvas for a different key.
    final wasAlreadyConfigured = ctrl.savedOutputKeyConfigs.containsKey(
      currentKey,
    );

    ctrl.saveOutputKeyConfig(currentKey, config);

    if (!wasAlreadyConfigured && !ctrl.allDynamicUniMailingKeysConfigured) {
      // First-time save of this key and more keys remain — advance workflow.
      setState(_resetFormValues);
      final allKeys = ctrl.dynamicUniMailingOutputKeys;
      final nextKey = allKeys
          .where((k) => !ctrl.savedOutputKeyConfigs.containsKey(k))
          .firstOrNull;
      final keyIndex = nextKey != null ? allKeys.indexOf(nextKey) : -1;

      debugPrint(
        '[NEXT_KEY] completedKey="$currentKey"'
        ' | allKeys=$allKeys'
        ' | nextKey="$nextKey"'
        ' | savedKeys=${ctrl.savedOutputKeyConfigs.keys.toList()}'
        ' | allConfigured=${ctrl.allDynamicUniMailingKeysConfigured}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (nextKey != null && keyIndex >= 0) {
          await _showNextKeyDialog(
            completedKey: currentKey,
            nextKeyNumber: keyIndex + 1,
            nextKeyName: nextKey,
          );
        }
        if (mounted) ctrl.clearCanvasForNextOutputKey();
      });
    } else if (!wasAlreadyConfigured) {
      // Last key saved for the first time — deselect and show preview.
      ctrl.clearSelectedOutputKey();
      final keys = ctrl.dynamicUniMailingOutputKeys;
      if (keys.isNotEmpty && currentKey == keys.last) {
        final lastKey = currentKey;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onShowPreview?.call(lastKey);
        });
      }
    } else {
      // Re-edit of an already-saved key — flash the button to confirm save.
      _saveSuccessTimer?.cancel();
      setState(() => _saveSuccess = true);
      _saveSuccessTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _saveSuccess = false);
      });
      // Also show preview if this is the last key (only trigger available).
      final keys = ctrl.dynamicUniMailingOutputKeys;
      if (keys.isNotEmpty && currentKey == keys.last) {
        final lastKey = currentKey;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onShowPreview?.call(lastKey);
        });
      }
    }
  }

  Future<void> _showNextKeyDialog({
    required String completedKey,
    required int nextKeyNumber,
    required String nextKeyName,
  }) async {
    if (!mounted) return;
    final allKeys = widget.ctrl.dynamicUniMailingOutputKeys;
    final total = allKeys.length;
    final completedCount = nextKeyNumber - 1;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 360,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.blue.withValues(alpha: 0.10),
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        size: 17,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Key configuration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'Step $nextKeyNumber of $total',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── COMPLETED label ──
                Row(
                  children: const [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 12,
                      color: AppColors.green,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // ── Completed key card ──
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: AppColors.green.withValues(alpha: 0.06),
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              completedKey,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const Text(
                              'Mapping saved',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: AppColors.green.withValues(alpha: 0.13),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Progress bar ──
                Row(
                  children: List.generate(total, (i) {
                    final Color segColor;
                    if (i < completedCount) {
                      segColor = AppColors.green;
                    } else if (i == completedCount) {
                      segColor = AppColors.blue;
                    } else {
                      segColor = AppColors.border2;
                    }
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < total - 1 ? 3 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: segColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),

                // ── Footer ──
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Got it',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward_rounded, size: 13),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

    final sourcesWithCols =
        widget.sourceNodes.where((n) => n.cols.isNotEmpty).toList();
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

        // ── Body: driven by sidebar selectedOutputKey ──
        if (currentKey.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: progress == total
                  ? AppColors.green.withValues(alpha: 0.06)
                  : AppColors.surface2,
              border: Border.all(
                color: progress == total
                    ? AppColors.green.withValues(alpha: 0.30)
                    : AppColors.border2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  progress == total
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 14,
                  color:
                      progress == total ? AppColors.green : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progress == total
                        ? 'All $total keys configured. Select a key from the sidebar to review or edit.'
                        : 'Select an output key from the sidebar to configure.',
                    style: TextStyle(
                      color: progress == total
                          ? AppColors.green
                          : AppColors.textMuted,
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: _saveSuccess
                              ? [
                                  AppColors.green,
                                  AppColors.green.withValues(alpha: 0.8),
                                ]
                              : _canSave
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
                          Icon(
                            _saveSuccess
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _saveSuccess ? 'Saved ✓' : 'Add $currentKey',
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
      ],
    );
  }
}

