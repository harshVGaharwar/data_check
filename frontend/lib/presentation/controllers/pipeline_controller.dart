import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';
import 'package:vizualizer/data/models/pipeline_config.dart';
import 'package:vizualizer/core/utils/join_engine.dart';
class PipelineController extends ChangeNotifier {
  PipelineController({this.templateMode = TemplateMode.configure});

  final TemplateMode templateMode;

  // ── Core state (same as HTML) ──
  final List<PipelineNode> nodes = [];
  final List<PipelineEdge> edges = [];
  int _nodeIdSeq = 0;

  String? selectedNodeId;
  String? selectedEdgeId;

  /// Increments every time clearCanvas() or loadConfiguration() is called.
  int canvasVersion = 0;

  /// Increments ONLY when clearCanvas() is called.
  /// Sidebar watches this to reset dept/template/source-type state.
  int clearVersion = 0;

  // ── Sidebar state (same as HTML sidebar dept/template/count) ──
  String sidebarDept = '';
  String sidebarTemplate = '';
  int sidebarTemplateId = 0;
  String sidebarDeptId = '';
  int requiredSourceCount = 0;

  // ── Template metadata from API ──
  String templateType = '';
  List<String> outputFormats = const [];
  int numberOfOutputs = 0;

  // ── Dynamic template entries from GetTemplatesDynamic API ──
  // Each entry: {srno, id, sourceList, sourceCount, sourceMasterList, sourceType}
  List<Map<String, dynamic>> dynamicTemplates = [];

  // ── Selected output key (e.g. "Output 1 - Static") ──
  String selectedOutputKey = '';

  // ── Dynamic UniMailing per-key saved configs (3rd case) ──
  // key: output key name e.g. 'Output Key 1'
  // value: complete config map ready for payload
  final Map<String, Map<String, dynamic>> savedOutputKeyConfigs = {};

  // ── Output column order set by user in Step 2 of preview dialog ──
  // Each entry: {'nodeId': String, 'col': String, 'priority': int}
  List<Map<String, dynamic>> outputColumnOrder = [];

  // ── UniMailing column mapping (Static + UniMailing templates only) ──
  // key: field name ('Mail To', 'Subject', …)  value: 'nodeId::colName'
  final Map<String, String> uniMailingMandatory = {};
  // key: slot name ('C1', 'C2', …)  value: 'nodeId::colName'
  final Map<String, String> uniMailingCustom = {};
  // number of custom columns the user has added (includes unfilled ones)
  int uniMailingCustomCount = 0;

  // ── Port drag state (same as HTML portDrag) ──
  String? portDragFromNodeId;
  Offset? portDragCurrentPos;

  // ── Pending canvas scroll-to request ──
  String? pendingFocusNodeId;
  void requestFocus(String nodeId) {
    pendingFocusNodeId = nodeId;
    // notifyListeners() already called by the caller (addOutputNode)
  }

  void clearFocusRequest() {
    pendingFocusNodeId = null;
  }

  // ── Dynamic UniMailing (3rd case) getters & methods ──

  /// True when: templateType = Dynamic (code "3" or label contains "dynamic")
  /// AND outputFormats contains UniMailing.
  bool get isDynamicUniMailing {
    final isDynamic =
        templateType == '3' || templateType.toLowerCase().contains('dynamic');
    final hasUnimailing = outputFormats.any(
      (f) => f.toLowerCase().contains('unimailing'),
    );
    return isDynamic && hasUnimailing;
  }

  /// Safe srno reader — Flutter Web returns JSON ints as num/double.
  static int _srno(Map<String, dynamic> dt) => (dt['srno'] as num?)?.toInt() ?? 0;

  /// Build output key list from dynamicTemplates (new API) or numberOfOutputs (old API).
  /// Format: 'Key 1 - Static', 'Key 2 - Dynamic', …
  List<String> get dynamicUniMailingOutputKeys {
    if (dynamicTemplates.isNotEmpty) {
      final result = <String>[];
      final hasStatic = dynamicTemplates.any((dt) => _srno(dt) == 0);
      if (hasStatic) result.add('Key 1 - Static');
      int keyIdx = 2;
      for (final dt in dynamicTemplates) {
        if (_srno(dt) > 0) {
          result.add('Key $keyIdx - Dynamic');
          keyIdx++;
        }
      }
      if (result.isEmpty) result.add('Key 1 - Static');
      return result;
    }
    // Old API / fallback
    final n = numberOfOutputs;
    if (n == 0) return ['Key 1 - Static'];
    return [
      'Key 1 - Static',
      for (int i = 2; i <= n + 1; i++) 'Key $i - Dynamic',
    ];
  }

  /// Returns the dynamicTemplate entry corresponding to a given output key label.
  Map<String, dynamic>? getDynamicTemplateForOutputKey(String key) {
    if (dynamicTemplates.isEmpty) return null;
    if (key.contains('Static')) {
      try {
        return dynamicTemplates.firstWhere((dt) => _srno(dt) == 0);
      } catch (_) {
        return null;
      }
    }
    final dynamicItems = dynamicTemplates.where((dt) => _srno(dt) > 0).toList();
    // Key format: 'Key N - Dynamic' where N starts at 2
    final parts = key.split(' ');
    final keyNum = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (keyNum == null) return null;
    final dynIdx = keyNum - 2;
    if (dynIdx < 0 || dynIdx >= dynamicItems.length) return null;
    return dynamicItems[dynIdx];
  }

  /// Keys containing 'Static' are the static output key.
  bool isOutputKeyStatic(String keyName) => keyName.contains('Static');

  /// True once every output key has been saved.
  bool get allDynamicUniMailingKeysConfigured =>
      isDynamicUniMailing &&
      dynamicUniMailingOutputKeys.every(
        (k) => savedOutputKeyConfigs.containsKey(k),
      );

  /// For sequential configuration: all keys except the next unconfigured one
  /// are disabled. Saved keys cannot be re-edited; future keys cannot be
  /// jumped to until prior ones are complete.
  Set<String> get sequentiallyDisabledOutputKeys {
    final keys = dynamicUniMailingOutputKeys;
    final activeKey = keys.firstWhere(
      (k) => !savedOutputKeyConfigs.containsKey(k),
      orElse: () => '',
    );
    return keys.where((k) => k != activeKey).toSet();
  }

  void saveOutputKeyConfig(String keyName, Map<String, dynamic> config) {
    savedOutputKeyConfigs[keyName] = config;
    notifyListeners();
  }

  void removeOutputKeyConfig(String keyName) {
    savedOutputKeyConfigs.remove(keyName);
    notifyListeners();
  }

  // ── Helpers ──
  String _nextId() => 'n${++_nodeIdSeq}';
  String _nextEdgeId() => 'e${++_nodeIdSeq}';

  PipelineNode? findNode(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  PipelineEdge? findEdge(String id) {
    for (final e in edges) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ── Source count logic (same as HTML canAddSource / refreshSourceCounter) ──
  int get sourceNodesOnCanvas => nodes.where((n) => n.type.isSource).length;
  bool get canAddSource {
    if (requiredSourceCount <= 0) return true;
    return sourceNodesOnCanvas < requiredSourceCount;
  }

  /// True when:
  ///   1. Required source count is met (if set), AND
  ///   2. ALL source nodes on canvas are confirmed.
  /// Join Operation drag is gated behind this.
  bool get allSourceNodesConfirmed {
    final sources = nodes.where((n) => n.type.isSource).toList();
    if (sources.isEmpty) return false;
    // Step 1 — count check
    if (requiredSourceCount > 0 && sources.length < requiredSourceCount) {
      return false;
    }
    // Step 2 — all confirmed check
    return sources.every((n) => n.confirmState == NodeConfirmState.confirmed);
  }

  /// True when join palette should pulse:
  /// sources all confirmed AND no join node on canvas yet.
  bool get shouldAnimateJoin =>
      allSourceNodesConfirmed && !nodes.any((n) => n.type == NodeType.join);

  void confirmNode(String nodeId) {
    final node = findNode(nodeId);
    if (node == null) return;
    node.confirmState = NodeConfirmState.confirmed;
    notifyListeners();
  }

  void editNode(String nodeId) {
    final node = findNode(nodeId);
    if (node == null) return;
    node.confirmState = NodeConfirmState.editing;
    notifyListeners();
  }

  // ── Sidebar actions (same as HTML onSidebarDeptChange / onSidebarTemplateChange) ──
  void setSidebarDept(String dept, {
String deptId = ''}) {
    sidebarDept = dept;
    sidebarDeptId = deptId;
    sidebarTemplate = '';
    sidebarTemplateId = 0;
    requiredSourceCount = 0;
    templateType = '';
    outputFormats = const [];
    numberOfOutputs = 0;
    dynamicTemplates = [];
    selectedOutputKey = '';
    outputColumnOrder = [];
    uniMailingMandatory.clear();
    uniMailingCustom.clear();
    uniMailingCustomCount = 0;
    savedOutputKeyConfigs.clear();
    notifyListeners();
  }

  void setSidebarTemplate(
    String template, {
    int? sourceCount,
    int templateId = 0,
    String templateType = '',
    List<String> outputFormats = const [],
    int numberOfOutputs = 0,
    List<Map<String, dynamic>> dynamicTemplates = const [],
  }) {
    final isSameTemplate = templateId != 0 && templateId == sidebarTemplateId;
    sidebarTemplate = template;
    sidebarTemplateId = templateId;
    requiredSourceCount =
        sourceCount ?? PipelineConfig.templateSourceCount[template] ?? 0;
    this.templateType = templateType;
    this.outputFormats = List<String>.from(outputFormats);
    this.numberOfOutputs = numberOfOutputs;
    this.dynamicTemplates = List<Map<String, dynamic>>.from(dynamicTemplates);
    outputColumnOrder = [];
    // Clear saved configs for a new template before computing auto-select.
    if (!isSameTemplate) savedOutputKeyConfigs.clear();
    // Auto-select the first unconfigured output key for sequential flow.
    if (isDynamicUniMailing) {
      final keys = dynamicUniMailingOutputKeys;
      selectedOutputKey = keys.firstWhere(
        (k) => !savedOutputKeyConfigs.containsKey(k),
        orElse: () => keys.isNotEmpty ? keys.first : '',
      );
    } else {
      selectedOutputKey = '';
    }
    debugPrint(
      '[CTRL] setSidebarTemplate: type=$templateType, formats=$outputFormats, dynamicCount=${this.dynamicTemplates.length}, isDynUni=$isDynamicUniMailing',
    );
    notifyListeners();
  }

  /// Update required source count when an output key is selected.
  void setOutputKeySourceCount(int count) {
    requiredSourceCount = count;
    notifyListeners();
  }

  void setSelectedOutputKey(String key) {
    if (key == selectedOutputKey) return;
    // Clear canvas when switching output keys in Dynamic UniMailing so each key
    // gets a fresh canvas instead of retaining the previous key's source nodes.
    if (isDynamicUniMailing && nodes.isNotEmpty) {
      nodes.clear();
      edges.clear();
      selectedNodeId = null;
      selectedEdgeId = null;
      _nodeIdSeq = 0;
      portDragFromNodeId = null;
      portDragCurrentPos = null;
      pendingFocusNodeId = null;
      outputColumnOrder = [];
      uniMailingMandatory.clear();
      uniMailingCustom.clear();
      canvasVersion++;
    }
    selectedOutputKey = key;
    notifyListeners();
  }

  bool get hasOutputNode => nodes.any((n) => n.type == NodeType.output);

  /// Adds an output-preview node to the right of the join node.
  /// Removes any existing output node first (only one allowed).
  PipelineNode addOutputNode(String joinNodeId) {
    nodes.removeWhere((n) => n.type == NodeType.output);
    edges.removeWhere((e) => e.toNodeId == 'output' || e.fromNodeId == 'output');
    final joinNode = findNode(joinNodeId);
    final pos = joinNode != null
        ? Offset(
            joinNode.position.dx + 360,
            joinNode.position.dy,
          )
        : const Offset(600, 300);
    final node = PipelineNode(
      id: _nextId(),
      type: NodeType.output,
      name: 'Output Preview',
      position: pos,
    );
    node.position = _clamp(node.position, node);
    nodes.add(node);
    // Wire join → output edge
    edges.add(PipelineEdge(
      id: _nextEdgeId(),
      fromNodeId: joinNodeId,
      toNodeId: node.id,
    ));
    pendingFocusNodeId = node.id;
    notifyListeners();
    return node;
  }

  void setOutputColumnOrder(List<Map<String, dynamic>> order) {
    outputColumnOrder = List<Map<String, dynamic>>.from(order);
    // No notifyListeners needed — called just before submit
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // NODE CRUD (same as HTML addNode / deleteNode / clearCanvas)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Same as HTML addNode(type, name, x, y)
  PipelineNode addNode(
    NodeType type,
    Offset position, {
    String? name,
    String sourceTypeValue = '',
    int sourceTypeId = 0,
    String sourceTypeName = '',
  }) {
    // If name is explicitly provided (even empty string), use it; otherwise fall back to type.label
    final resolvedName = name ?? type.label;
    final node = PipelineNode(
      id: _nextId(),
      type: type,
      name: resolvedName,
      position: position,
      department: sidebarDept.isNotEmpty ? sidebarDept : 'Finance',
      template: sidebarTemplate,
    );
    if (sourceTypeValue.isNotEmpty) node.sourceTypeValue = sourceTypeValue;
    if (sourceTypeId > 0) node.sourceTypeId = sourceTypeId;
    if (sourceTypeName.isNotEmpty) node.sourceTypeName = sourceTypeName;
    node.position = _clamp(node.position, node);
    nodes.add(node);
    notifyListeners();
    return node;
  }

  /// Same as HTML deleteNode(nodeId)
  void deleteNode(String nodeId) {
    nodes.removeWhere((n) => n.id == nodeId);
    edges.removeWhere((e) => e.fromNodeId == nodeId || e.toNodeId == nodeId);
    // Clean JOIN references and remove stale mappings
    for (final n in nodes.where((n) => n.type == NodeType.join)) {
      if (n.leftSrcId == nodeId) n.leftSrcId = null;
      if (n.rightSrcId == nodeId) n.rightSrcId = null;
      n.mappings.removeWhere(
        (m) => m.leftSourceId == nodeId || m.rightSourceId == nodeId,
      );
    }
    if (selectedNodeId == nodeId) selectedNodeId = null;
    if (portDragFromNodeId == nodeId) portDragFromNodeId = null;
    notifyListeners();
  }

  /// Same as HTML clearCanvas()
  void clearCanvas() {
    nodes.clear();
    edges.clear();
    selectedNodeId = null;
    selectedEdgeId = null;
    _nodeIdSeq = 0;
    portDragFromNodeId = null;
    portDragCurrentPos = null;
    pendingFocusNodeId = null;
    sidebarDept = '';
    sidebarTemplate = '';
    sidebarTemplateId = 0;
    sidebarDeptId = '';
    requiredSourceCount = 0;
    templateType = '';
    outputFormats = const [];
    numberOfOutputs = 0;
    dynamicTemplates = [];
    selectedOutputKey = '';
    outputColumnOrder = [];
    uniMailingMandatory.clear();
    uniMailingCustom.clear();
    uniMailingCustomCount = 0;
    savedOutputKeyConfigs.clear();
    canvasVersion++;
    clearVersion++;
    notifyListeners();
  }

  /// Clears only the canvas nodes/edges after saving a Dynamic UniMailing
  /// output key config. Preserves template metadata and savedOutputKeyConfigs
  /// so the user can rebuild the canvas for the next output key.
  void clearCanvasForNextOutputKey() {
    nodes.clear();
    edges.clear();
    selectedNodeId = null;
    selectedEdgeId = null;
    _nodeIdSeq = 0;
    portDragFromNodeId = null;
    portDragCurrentPos = null;
    pendingFocusNodeId = null;
    outputColumnOrder = [];
    uniMailingMandatory.clear();
    uniMailingCustom.clear();
    uniMailingCustomCount = 0;
    // Auto-advance sidebar selection to the next unconfigured key so the user
    // doesn't have to manually pick one from the dropdown after the canvas clears.
    final keys = dynamicUniMailingOutputKeys;
    final next = keys
        .where((k) => !savedOutputKeyConfigs.containsKey(k))
        .firstOrNull;
    selectedOutputKey = next ?? '';
    // Intentionally NOT clearing: sidebarDept, sidebarTemplate, sidebarTemplateId,
    // sidebarDeptId, requiredSourceCount, templateType, outputFormats,
    // numberOfOutputs, savedOutputKeyConfigs.
    // Intentionally NOT incrementing clearVersion (sidebar keeps dept/template).
    canvasVersion++;
    notifyListeners();
  }

  /// Hydrate the canvas from a saved GetTemplateConfig API response.
  /// Positions nodes automatically: sources on the left, join in the middle,
  /// output on the right.
  void loadConfiguration(Map<String, dynamic> config) {
    nodes.clear();
    edges.clear();
    selectedNodeId = null;
    selectedEdgeId = null;
    _nodeIdSeq = 0;

    final rawSources = config['Sources'];
    final rawJoins = config['JoinMappings'];

    final sources = (rawSources is List)
        ? rawSources.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final joinMappings = (rawJoins is List)
        ? rawJoins.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    // ── 1. Source nodes ──
    final nameToNewId = <String, String>{}; // SourceName → new node ID
    const double srcX = 150;
    const double srcGap = 280;
    double srcY = 80;

    for (final src in sources) {
      final srcName = src['SourceName']?.toString() ?? '';
      final cols = (src['Columns']?.toString() ?? '')
          .split(',')
          .where((c) => c.isNotEmpty)
          .toList();
      final selCols = (src['SelectedColumns']?.toString() ?? '')
          .split(',')
          .where((c) => c.isNotEmpty)
          .toList();
      final srcTypeStr = src['SourceType']?.toString() ?? '';
      final srcTypeId = int.tryParse(srcTypeStr) ?? 0;
      final qFile = src['QueryFile']?.toString() ?? '';
      final nodeType = _nodeTypeFromSourceTypeId(srcTypeId);

      final nodeId = _nextId();
      nameToNewId[srcName] = nodeId;

      nodes.add(
        PipelineNode(
          id: nodeId,
          type: nodeType,
          name: srcName,
          position: Offset(srcX, srcY),
          department: sidebarDept,
          template: sidebarTemplate,
          cols: cols,
          selectedCols: selCols,
          separator: src['Separator']?.toString() ?? ',',
          fileName: src['ColumnFile']?.toString(),
          queryFileName: qFile.isEmpty ? null : qFile,
          sourceTypeValue: _sourceLabelFromTypeId(srcTypeId),
          sourceTypeId: srcTypeId,
          sourceTypeName: _sourceLabelFromTypeId(srcTypeId),
          confirmState: NodeConfirmState.confirmed,
          sourceId: int.tryParse(src['SourceId']?.toString() ?? ''),
        ),
      );

      srcY += srcGap;
    }

    // ── 2. Join node ──
    final joinCenterY = (srcY - srcGap) / 2 + 80;
    final joinId = _nextId();
    final joinMappingObjs = <ColumnMapping>[];
    for (final jm in joinMappings) {
      final ln = jm['LeftSourceName']?.toString() ?? '';
      final rn = jm['RightSourceName']?.toString() ?? '';
      joinMappingObjs.add(
        ColumnMapping(
          leftSourceId: nameToNewId[ln] ?? '',
          leftCol: jm['LeftColumn']?.toString() ?? '',
          joinType: _normaliseJoinType(jm['JoinType']?.toString() ?? ''),
          operationValue: '=',
          rightSourceId: nameToNewId[rn] ?? '',
          rightCol: jm['RightColumn']?.toString() ?? '',
        ),
      );
    }

    nodes.add(
      PipelineNode(
        id: joinId,
        type: NodeType.join,
        name: 'Join Operation',
        position: Offset(440, joinCenterY - 70),
        department: sidebarDept,
        template: sidebarTemplate,
        mappings: joinMappingObjs,
        confirmState: joinMappingObjs.isNotEmpty
            ? NodeConfirmState.confirmed
            : NodeConfirmState.notConfigured,
      ),
    );

    // Edges: every source → join
    for (final srcName in nameToNewId.keys) {
      edges.add(
        PipelineEdge(
          id: _nextEdgeId(),
          fromNodeId: nameToNewId[srcName]!,
          toNodeId: joinId,
        ),
      );
    }

    // ── 3. Restore columnAliases from outputColumns ──
    final rawOutputCols = config['outputColumns'];
    if (rawOutputCols is List) {
      for (final oc in rawOutputCols.whereType<Map<String, dynamic>>()) {
        final srcName = oc['sourceName']?.toString() ?? '';
        final sourceColName = oc['SourceColName']?.toString() ?? '';
        final columnName = oc['ColumnName']?.toString() ?? '';
        if (sourceColName.isEmpty || columnName.isEmpty) continue;
        final nodeId = nameToNewId[srcName];
        if (nodeId == null) continue;
        final node = nodes.where((n) => n.id == nodeId).firstOrNull;
        node?.columnAliases[sourceColName] = columnName;
      }
    }

    canvasVersion++;
    notifyListeners();
  }

  /// Sets only the column file bytes on a node (used after downloading existing
  /// files when loading a saved configuration).
  void setNodeColumnFileBytes(String nodeId, List<int> bytes) {
    final node = findNode(nodeId);
    if (node == null) return;
    node.columnFileBytes = bytes;
    notifyListeners();
  }

  static NodeType _nodeTypeFromSourceTypeId(int id) {
    switch (id) {
      case 1:
        return NodeType.manual;
      case 3:
        return NodeType.fc;
      default:
        return NodeType.db;
    }
  }

  static String _sourceLabelFromTypeId(int id) {
    switch (id) {
      case 1:
        return 'Manual';
      case 2:
        return 'QRS';
      case 3:
        return 'FC';
      default:
        return 'Database';
    }
  }

  static String _normaliseJoinType(String raw) {
    switch (raw.toLowerCase().replaceAll('_', ' ').trim()) {
      case 'left join':
      case 'left_join':
        return 'LEFT JOIN';
      case 'right join':
      case 'right_join':
        return 'RIGHT JOIN';
      case 'inner join':
      case 'inner_join':
        return 'INNER JOIN';
      default:
        return raw.toUpperCase();
    }
  }

  /// Move node by delta (drag handler)
  static const double canvasWidth = 3000;
  static const double canvasHeight = 2000;

  Offset _clamp(Offset pos, PipelineNode node) => Offset(
    pos.dx.clamp(0.0, canvasWidth - node.nodeWidth),
    pos.dy.clamp(0.0, canvasHeight - node.nodeHeight),
  );

  void moveNode(String nodeId, Offset delta) {
    final node = findNode(nodeId);
    if (node != null) {
      node.position = _clamp(node.position + delta, node);
      notifyListeners();
    }
  }

  void selectNode(String? nodeId) {
    selectedNodeId = nodeId;
    selectedEdgeId = null;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // EDGE CRUD (same as HTML addEdge / removeEdge / selectEdge)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Same as HTML addEdge(fromId, toId) — includes auto-direction-correction
  void addEdge(String fromId, String toId) {
    final fromNode = findNode(fromId);
    final toNode = findNode(toId);
    if (fromNode == null || toNode == null) {
      debugPrint('EDGE FAIL: fromNode or toNode null. from=$fromId to=$toId');
      return;
    }

    // Auto-correct direction
    if (toNode.type.isSource && fromNode.type == NodeType.join) {
      final tmp = fromId;
      fromId = toId;
      toId = tmp;
    }

    if (edges.any((e) => e.fromNodeId == fromId && e.toNodeId == toId)) {
      debugPrint('EDGE SKIP: duplicate from=$fromId to=$toId');
      return;
    }

    edges.add(
      PipelineEdge(id: _nextEdgeId(), fromNodeId: fromId, toNodeId: toId),
    );
    debugPrint(
      'EDGE ADDED: from=$fromId to=$toId | total edges=${edges.length}',
    );

    final target = findNode(toId);
    if (target != null && target.type == NodeType.join) {
      _syncJoinSources(target);
    }

    notifyListeners();
  }

  /// Same as HTML removeEdge(fromId, toId)
  void removeEdge(String edgeId) {
    final edge = findEdge(edgeId);
    if (edge == null) return;
    edges.removeWhere((e) => e.id == edgeId);

    // Resync JOIN if source disconnected
    final target = findNode(edge.toNodeId);
    if (target != null && target.type == NodeType.join) {
      _syncJoinSources(target);
    }
    selectedEdgeId = null;
    notifyListeners();
  }

  /// Same as HTML selectEdge(fromId, toId) — toggle
  void selectEdge(String edgeId) {
    selectedEdgeId = (selectedEdgeId == edgeId) ? null : edgeId;
    selectedNodeId = null;
    notifyListeners();
  }

  void deselectAll() {
    selectedNodeId = null;
    selectedEdgeId = null;
    notifyListeners();
  }

  /// Same as HTML syncJoinSources(joinNode)
  void _syncJoinSources(PipelineNode joinNode) {
    final inEdges = edges.where((e) => e.toNodeId == joinNode.id).toList();
    final srcA = inEdges.isNotEmpty ? findNode(inEdges[0].fromNodeId) : null;
    final srcB = inEdges.length > 1 ? findNode(inEdges[1].fromNodeId) : null;

    joinNode.leftSrcId = srcA?.id;
    joinNode.rightSrcId = srcB?.id;

    // Seed empty mapping if none
    if (joinNode.mappings.isEmpty) {
      joinNode.mappings.add(ColumnMapping());
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PORT DRAG (same as HTML portDrag state)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void startPortDrag(String nodeId, Offset pos) {
    portDragFromNodeId = nodeId;
    portDragCurrentPos = pos;
    notifyListeners();
  }

  void updatePortDrag(Offset pos) {
    portDragCurrentPos = pos;
    notifyListeners();
  }

  void endPortDrag(String? targetNodeId) {
    if (portDragFromNodeId != null &&
        targetNodeId != null &&
        portDragFromNodeId != targetNodeId) {
      addEdge(portDragFromNodeId!, targetNodeId);
    }
    portDragFromNodeId = null;
    portDragCurrentPos = null;
    notifyListeners();
  }

  void cancelPortDrag() {
    portDragFromNodeId = null;
    portDragCurrentPos = null;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // JOIN MAPPING (same as HTML joinCardAddFromInput / joinCardMapDel)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void addMappingToJoin(String joinNodeId, ColumnMapping mapping) {
    final node = findNode(joinNodeId);
    if (node == null) return;
    // Remove empty seed mappings
    node.mappings.removeWhere((m) => !m.isValid);
    node.mappings.add(mapping);
    node.joinType = mapping.joinType;
    notifyListeners();
  }

  void removeMappingFromJoin(String joinNodeId, int index) {
    final node = findNode(joinNodeId);
    if (node == null || index < 0 || index >= node.mappings.length) return;
    node.mappings.removeAt(index);
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // JOIN RESULT (same as HTML getNodeRows — recursive)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Recursive — handles chained joins (join1 → join2 → output)
  List<Map<String, dynamic>>? getNodeRows(String nodeId) {
    final node = findNode(nodeId);
    if (node == null) return null;

    // Source node — return its rows
    if (node.type.isSource) {
      return node.rows.isNotEmpty ? node.rows : null;
    }

    // JOIN node — execute join using mapping source IDs
    if (node.type == NodeType.join) {
      final validMappings = node.mappings.where((m) => m.isValid).toList();
      if (validMappings.isEmpty) return null;

      // Use first mapping's source IDs to determine left/right
      final firstMap = validMappings.first;
      final leftRows = getNodeRows(firstMap.leftSourceId);
      final rightRows = getNodeRows(firstMap.rightSourceId);
      if (leftRows == null || rightRows == null) return null;

      return JoinEngine.execute(
        leftRows: leftRows,
        rightRows: rightRows,
        mappings: node.mappings,
        joinType: firstMap.joinType,
      );
    }

    return null;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INIT FROM SOURCES (same as HTML initFromSources)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void initFromSources(List<Map<String, String>> sources) {
    clearCanvas();

    final count = sources.length;
    const srcX = 60.0;
    const joinX = 320.0;
    // const outX = 720.0;
    const startY = 60.0;
    final gapY = min(180.0, 500.0 / max(count, 1));

    // ── Add source nodes ──
    final srcNodes = <PipelineNode>[];
    for (int i = 0; i < count; i++) {
      final src = sources[i];
      final node = PipelineNode(
        id: _nextId(),
        type: NodeTypeExt.fromString(src['type'] ?? 'fc'),
        name: src['name'] ?? 'Source ${i + 1}',
        position: Offset(srcX, startY + i * gapY),
        department: src['department'] ?? 'Finance',
        template: src['template'] ?? '',
        sourceId: int.tryParse(src['id'] ?? ''),
      );
      nodes.add(node);
      srcNodes.add(node);
    }

    // ── Add JOIN nodes (chain) ──
    String? lastJoinId;
    if (count >= 2) {
      for (int i = 0; i < count - 1; i++) {
        final joinNode = PipelineNode(
          id: _nextId(),
          type: NodeType.join,
          name: 'Join Operation',
          position: Offset(joinX, startY + (i + 0.5) * gapY),
        );
        nodes.add(joinNode);

        if (i == 0) {
          addEdge(srcNodes[0].id, joinNode.id);
          addEdge(srcNodes[1].id, joinNode.id);
        } else {
          addEdge(lastJoinId!, joinNode.id);
          addEdge(srcNodes[i + 1].id, joinNode.id);
        }
        lastJoinId = joinNode.id;
      }
    }

    // ── Auto-fill sidebar ──
    if (sources.isNotEmpty) {
      sidebarDept = sources[0]['department'] ?? 'Finance';
      sidebarTemplate = sources[0]['template'] ?? '';
      requiredSourceCount =
          PipelineConfig.templateSourceCount[sidebarTemplate] ?? count;
    }

    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SEED DEMO DATA (same as HTML seedDemoData)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void seedDemoData() {
    for (final node in nodes) {
      if (!node.type.isSource) continue;
      // Try name-based first (for initFromSources), then type-based (for sidebar drag)
      final demo =
          PipelineConfig.demoData[node.name] ?? demoDataByType[node.type];
      if (demo != null && node.rows.isEmpty) {
        node.cols = List<String>.from(demo.cols);
        node.selectedCols = List<String>.from(demo.cols);
        node.rows = demo.rows.map((r) => Map<String, dynamic>.from(r)).toList();
      }
    }
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // UPDATE SOURCE (same as HTML updateSingleSource / updateSources)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void updateSingleSource(Map<String, dynamic> srcJson) {
    final node = nodes.firstWhere(
      (n) => n.sourceId == srcJson['id'] && n.type.isSource,
      orElse: () => PipelineNode(
        id: '',
        type: NodeType.db,
        name: '',
        position: Offset.zero,
      ),
    );
    if (node.id.isEmpty) return;

    bool changed = false;
    if (srcJson['name'] != null && srcJson['name'] != node.name) {
      node.name = srcJson['name'];
      changed = true;
    }
    if (srcJson['department'] != null &&
        srcJson['department'] != node.department) {
      node.department = srcJson['department'];
      changed = true;
    }
    if (srcJson['template'] != null && srcJson['template'] != node.template) {
      node.template = srcJson['template'];
      changed = true;
    }
    if (srcJson['type'] != null) {
      final newType = NodeTypeExt.fromString(srcJson['type']);
      if (newType != node.type) {
        node.type = newType;
        node.cols = [];
        node.selectedCols = [];
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  // ── Node name update (same as HTML liveUpdateNode) ──
  void updateNodeName(String nodeId, String name) {
    final node = findNode(nodeId);
    if (node != null) {
      node.name = name;
      notifyListeners();
    }
  }

  void updateNodeSeparator(String nodeId, String separator) {
    final node = findNode(nodeId);
    if (node != null) {
      node.separator = separator;
      notifyListeners();
    }
  }

  void clearNodeColumnFile(String nodeId) {
    final node = findNode(nodeId);
    if (node == null) return;
    node.fileName = null;
    node.columnFileBytes = null;
    node.cols = [];
    node.selectedCols = [];
    node.rows = [];
    notifyListeners();
  }

  void updateNodeSourceType(
    String nodeId,
    String sourceTypeValue, {
    int sourceTypeId = 0,
  }) {
    final node = findNode(nodeId);
    if (node != null) {
      node.sourceTypeValue = sourceTypeValue;
      if (sourceTypeId > 0) node.sourceTypeId = sourceTypeId;
      notifyListeners();
    }
  }

  // ── Set columns from file (same as HTML handleColFile) ──
  void setNodeColumns(
    String nodeId,
    List<String> cols,
    List<Map<String, dynamic>> rows,
    String fileName, {
    List<int>? bytes,
  }) {
    final node = findNode(nodeId);
    if (node == null) return;
    node.cols = cols;
    node.selectedCols = [];
    node.rows = rows;
    node.fileName = fileName;
    node.columnFileBytes = bytes;
    notifyListeners();
  }

  // ── Set query file name ──
  void setQueryFile(String nodeId, String fileName, {
List<int>? bytes}) {
    final node = findNode(nodeId);
    if (node == null) return;
    node.queryFileName = fileName;
    node.queryFileBytes = bytes;
    notifyListeners();
  }

  // ── Toggle column selection ──
  void toggleColumn(String nodeId, String col) {
    final node = findNode(nodeId);
    if (node == null) return;
    if (node.selectedCols.contains(col)) {
      node.selectedCols.remove(col);
      // Clear stale priority so it doesn't conflict when reselected later
      node.columnPriorities.remove(col);
    } else {
      node.selectedCols.add(col);
    }
    notifyListeners();
  }

  void setColumnAlias(String nodeId, String col, String alias) {
    final node = findNode(nodeId);
    if (node == null) return;
    if (alias.trim().isEmpty) {
      node.columnAliases.remove(col);
    } else {
      node.columnAliases[col] = alias.trim();
    }
    notifyListeners();
  }

  void setUniMailingMandatory(String field, String colKey) {
    if (colKey.isEmpty) {
      uniMailingMandatory.remove(field);
    } else {
      uniMailingMandatory[field] = colKey;
    }
    notifyListeners();
  }

  void setUniMailingCustom(String key, String colKey) {
    if (colKey.isEmpty) {
      uniMailingCustom.remove(key);
    } else {
      uniMailingCustom[key] = colKey;
    }
    notifyListeners();
  }

  void setUniMailingCustomCount(int count) {
    uniMailingCustomCount = count;
    notifyListeners();
  }

  void setColumnPriority(String nodeId, String col, int priority) {
    final node = findNode(nodeId);
    if (node == null) return;
    if (priority <= 0) {
      node.columnPriorities.remove(col);
    } else {
      node.columnPriorities[col] = priority;
    }
    notifyListeners();
  }

  void setColumnUniqueField(String nodeId, String col, bool isUnique) {
    final node = findNode(nodeId);
    if (node == null) return;
    if (isUnique) {
      // Only one unique field allowed per source — clear all others first
      node.columnUniqueFields.updateAll((_, __) => false);
    }
    node.columnUniqueFields[col] = isUnique;
    notifyListeners();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FILE: widgets/edge_painter.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// CustomPainter that draws all edges as bezier curves
