// part of 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node_body.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // UNIMAILING SECTION
// // ─────────────────────────────────────────────────────────────────────────────

// class UniMailingSection extends StatefulWidget {
//   final PipelineController ctrl;
//   final List<PipelineNode> sourceNodes;
//   const UniMailingSection({super.key, required this.ctrl, required this.sourceNodes});

//   @override
//   State<UniMailingSection> createState() => UniMailingSectionState();
// }

// class UniMailingSectionState extends State<UniMailingSection> {
//   late int _customCount;

//   @override
//   void initState() {
//     super.initState();
//     widget.ctrl.addListener(_onCtrlChange);
//     // Prefer the persisted count; for a fresh config default to 1 (Column 1 shown by default)
//     final derived = _deriveCustomCount();
//     _customCount = widget.ctrl.uniMailingCustomCount > 0
//         ? widget.ctrl.uniMailingCustomCount
//         : derived > 0
//         ? derived
//         : 1;
//     // Sync the default count to the controller after the first frame
//     // so validation knows Column 1 is expected to be filled
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted && widget.ctrl.uniMailingCustomCount == 0) {
//         widget.ctrl.setUniMailingCustomCount(_customCount);
//       }
//     });
//   }

//   void _onCtrlChange() => setState(() {});

//   @override
//   void dispose() {
//     widget.ctrl.removeListener(_onCtrlChange);
//     super.dispose();
//   }

//   int _deriveCustomCount() {
//     if (widget.ctrl.uniMailingCustom.isEmpty) return 0;
//     return widget.ctrl.uniMailingCustom.keys
//         .map((k) => int.tryParse(k.substring(1)) ?? 0)
//         .reduce((a, b) => a > b ? a : b);
//   }

//   ({
// List<String> keys, Map<String, String> labels}) _buildAvailable() {
//     final srcNodes = widget.sourceNodes
//         .where((n) => n.selectedCols.isNotEmpty)
//         .toList();
//     final multi = srcNodes.length > 1;
//     final keys = <String>[];
//     final labels = <String, String>{};
//     for (final n in srcNodes) {
//       for (final c in n.selectedCols) {
//         final k = '${n.id}::$c';
//         keys.add(k);
//         labels[k] = multi ? '${n.name} › $c' : c;
//       }
//     }
//     return (keys: keys, labels: labels);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = widget.ctrl;
//     final avail = _buildAvailable();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // UniMailing fields (all optional)
//         Row(
//           children: [
//             const Icon(Icons.email_outlined, size: 10, color: AppColors.violet),
//             const SizedBox(width: 4),
//             const Text(
//               'UNIMAILING FIELDS',
//               style: TextStyle(
//                 color: AppColors.violet,
//                 fontSize: 9,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 0.7,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 6),
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: Column(
//             children: kMandatoryFields.asMap().entries.map((e) {
//               final idx = e.key;
//               final field = e.value;
//               final isLast = idx == kMandatoryFields.length - 1;
//               final current = ctrl.uniMailingMandatory[field] ?? '';
//               final isMapped = avail.keys.contains(current);
//               return UniMappingRow(
//                 label: field,
//                 labelColor: AppColors.violet,
//                 currentKey: isMapped ? current : null,
//                 availableKeys: avail.keys,
//                 colLabels: avail.labels,
//                 isLast: isLast,
//                 isRequired: false,
//                 isMapped: isMapped,
//                 onChanged: (v) => ctrl.setUniMailingMandatory(field, v ?? ''),
//               );
//             }).toList(),
//           ),
//         ),

//         const SizedBox(height: 12),

//         // Custom columns
//         Row(
//           children: [
//             const Icon(
//               Icons.add_box_outlined,
//               size: 10,
//               color: AppColors.violet,
//             ),
//             const SizedBox(width: 4),
//             const Text(
//               'CUSTOM COLUMNS (Column 1–Column 50)',
//               style: TextStyle(
//                 color: AppColors.violet,
//                 fontSize: 9,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 0.7,
//               ),
//             ),
//             const Spacer(),
//             if (_customCount < 50)
//               GestureDetector(
//                 onTap: () {
//                   setState(() => _customCount++);
//                   widget.ctrl.setUniMailingCustomCount(_customCount);
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(6),
//                     color: AppColors.blue,
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppColors.blue.withValues(alpha: 0.25),
//                         blurRadius: 4,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(
//                         Icons.add_rounded,
//                         size: 11,
//                         color: Colors.white,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         'Add Column ${_customCount + 1}',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 9,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 6),

//         if (_customCount == 0)
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(7),
//               color: AppColors.surface2,
//               border: Border.all(color: AppColors.border),
//             ),
//             child: const Center(
//               child: Text(
//                 'No custom columns added',
//                 style: TextStyle(color: AppColors.textMuted, fontSize: 10),
//               ),
//             ),
//           )
//         else
//           Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: AppColors.border),
//             ),
//             child: Column(
//               children: List.generate(_customCount, (i) {
//                 final slot = i + 1;
//                 final key = 'C$slot';
//                 final current = ctrl.uniMailingCustom[key] ?? '';
//                 final isMapped = avail.keys.contains(current);
//                 final isLast = slot == _customCount;
//                 return UniMappingRow(
//                   label: 'Column $slot',
//                   labelColor: AppColors.violet,
//                   currentKey: isMapped ? current : null,
//                   availableKeys: avail.keys,
//                   colLabels: avail.labels,
//                   isLast: isLast,
//                   isRequired: true,
//                   isMapped: isMapped,
//                   onChanged: (v) => ctrl.setUniMailingCustom(key, v ?? ''),
//                   onDelete: isLast
//                       ? () {
//                           ctrl.setUniMailingCustom(key, '');
//                           setState(() => _customCount--);
//                           ctrl.setUniMailingCustomCount(_customCount);
//                         }
//                       : null,
//                 );
//               }),
//             ),
//           ),
//       ],
//     );
//   }
// }

// unimaliling section 

part of 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node_body.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNIMAILING SECTION
// ─────────────────────────────────────────────────────────────────────────────

class UniMailingSection extends StatefulWidget {
  final PipelineController ctrl;
  final List<PipelineNode> sourceNodes;

  /// When false the 7 UNIMAILING FIELDS rows are hidden and only the
  /// CUSTOM COLUMNS block renders — used by Static + User Defined.
  final bool showMandatoryFields;

  const UniMailingSection({
    super.key,
    required this.ctrl,
    required this.sourceNodes,
    this.showMandatoryFields = true,
  });

  @override
  State<UniMailingSection> createState() => UniMailingSectionState();
}

class UniMailingSectionState extends State<UniMailingSection> {
  late int _customCount;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onCtrlChange);
    // Prefer the persisted count; for a fresh config default to 1 (Column 1 shown by default)
    final derived = _deriveCustomCount();
    _customCount = widget.ctrl.uniMailingCustomCount > 0
        ? widget.ctrl.uniMailingCustomCount
        : derived > 0
            ? derived
            : 1;
    // Sync the default count to the controller after the first frame
    // so validation knows Column 1 is expected to be filled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.ctrl.uniMailingCustomCount == 0) {
        widget.ctrl.setUniMailingCustomCount(_customCount);
      }
    });
  }

  void _onCtrlChange() => setState(() {});

  @override
  void dispose() {
    widget.ctrl.removeListener(_onCtrlChange);
    super.dispose();
  }

  int _deriveCustomCount() {
    if (widget.ctrl.uniMailingCustom.isEmpty) return 0;
    return widget.ctrl.uniMailingCustom.keys
        .map((k) => int.tryParse(k.substring(1)) ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  ({List<String> keys, Map<String, String> labels}) _buildAvailable() {
    final srcNodes =
        widget.sourceNodes.where((n) => n.selectedCols.isNotEmpty).toList();
    final multi = srcNodes.length > 1;
    final keys = <String>[];
    final labels = <String, String>{};
    for (final n in srcNodes) {
      for (final c in n.selectedCols) {
        final k = '${n.id}::$c';
        keys.add(k);
        labels[k] = multi ? '${n.name} › $c' : c;
      }
    }
    return (keys: keys, labels: labels);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final avail = _buildAvailable();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // UniMailing fields (all optional) — hidden for Static + User Defined
        if (widget.showMandatoryFields) ...[
          Row(
            children: [
              const Icon(
                Icons.email_outlined,
                size: 10,
                color: AppColors.violet,
              ),
              const SizedBox(width: 4),
              const Text(
                'UNIMAILING FIELDS',
                style: TextStyle(
                  color: AppColors.violet,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: kMandatoryFields.asMap().entries.map((e) {
                final idx = e.key;
                final field = e.value;
                final isLast = idx == kMandatoryFields.length - 1;
                final current = ctrl.uniMailingMandatory[field] ?? '';
                final isMapped = avail.keys.contains(current);
                return UniMappingRow(
                  label: field,
                  labelColor: AppColors.violet,
                  currentKey: isMapped ? current : null,
                  availableKeys: avail.keys,
                  colLabels: avail.labels,
                  isLast: isLast,
                  // ✅ Only "Mail To" is required
                  isRequired: field == "Mail To",
                  isMapped: isMapped,
                  onChanged: (v) => ctrl.setUniMailingMandatory(field, v ?? ''),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Custom columns
        Row(
          children: [
            const Icon(
              Icons.add_box_outlined,
              size: 10,
              color: AppColors.violet,
            ),
            const SizedBox(width: 4),
            const Text(
              'CUSTOM COLUMNS (Column 1–Column 50)',
              style: TextStyle(
                color: AppColors.violet,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const Spacer(),
            if (_customCount < 50)
              GestureDetector(
                onTap: () {
                  setState(() => _customCount++);
                  widget.ctrl.setUniMailingCustomCount(_customCount);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.blue,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Column ${_customCount + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(
          height: 4,
        ),
        Row(
          children: [
            Icon(
              Icons.edit_outlined,
              size: 9,
              color: AppColors.textMuted,
            ),
            const SizedBox(
              width: 4,
            ),
            Expanded(
              child: Text(
                'Tip: tap a Column name to rename it.',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (_customCount == 0)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: AppColors.surface2,
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No custom columns added',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(_customCount, (i) {
                final slot = i + 1;
                final key = 'C$slot';
                final current = ctrl.uniMailingCustom[key] ?? '';
                final isMapped = avail.keys.contains(current);
                final isLast = slot == _customCount;
                return UniMappingRow(
                  label: ctrl.uniMailingCustomLabels[key] ?? 'Column $slot',
                  labelColor: AppColors.violet,
                  currentKey: isMapped ? current : null,
                  availableKeys: avail.keys,
                  colLabels: avail.labels,
                  isLast: isLast,
                  isRequired: true,
                  isMapped: isMapped,
                  onChanged: (v) => ctrl.setUniMailingCustom(key, v ?? ''),
                  onLabelChanged: (name) =>
                      ctrl.setUniMailingCustomLabel(key, name),
                  labelHint: 'Column $slot',
                  // onDelete: isLast
                  //     ? () {
                  //         ctrl.setUniMailingCustom(key, '');
                  //         setState(() => _customCount--);
                  //         ctrl.setUniMailingCustomCount(_customCount);
                  //       }
                  //     : null,
                  onDelete: (slot == 1)
                      ? null // ✅ Column 1 cannot be deleted
                      : (isLast
                          ? () {
                              ctrl.setUniMailingCustom(key, '');
                              setState(() => _customCount--);
                              ctrl.setUniMailingCustomCount(_customCount);
                            }
                          : null),
                );
              }),
            ),
          ),
      ],
    );
  }
}

