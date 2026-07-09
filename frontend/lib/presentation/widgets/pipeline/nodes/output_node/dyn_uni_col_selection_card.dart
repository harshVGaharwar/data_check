// import 'package:flutter/material.dart';
// import 'package:vizualizer/core/theme/app_theme.dart';
// import 'package:vizualizer/data/models/pipeline_models.dart';

// class DynUniColSelectionCard extends StatelessWidget {
//   final List<PipelineNode> sources;
//   final Set<String> localSelected; // 'nodeId::colName'
//   final Map<String, bool> localUniqueFields;
//   final ValueChanged<String> onToggle;
//   final void Function(String key, bool val) onUniqueFieldChanged;

//   const DynUniColSelectionCard({super.key, 
//     required this.sources,
//     required this.localSelected,
//     required this.localUniqueFields,
//     required this.onToggle,
//     required this.onUniqueFieldChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final totalSelected = localSelected.length;
//     final totalCols = sources.fold<int>(0, (sum, n) => sum + n.cols.length);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Icon(
//               Icons.checklist_rounded,
//               size: 11,
//               color: AppColors.blue,
//             ),
//             const SizedBox(width: 4),
//             const Text(
//               'STEP A — SELECT COLUMNS',
//               style: TextStyle(
//                 color: AppColors.blue,
//                 fontSize: 9,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 0.6,
//               ),
//             ),
//             const Spacer(),
//             // Total selected badge
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(10),
//                 color: totalSelected > 0
//                     ? AppColors.blue.withValues(alpha: 0.12)
//                     : AppColors.surface2,
//                 border: Border.all(
//                   color: totalSelected > 0
//                       ? AppColors.blue.withValues(alpha: 0.30)
//                       : AppColors.border2,
//                 ),
//               ),
//               child: Text(
//                 '$totalSelected / $totalCols selected',
//                 style: TextStyle(
//                   color: totalSelected > 0
//                       ? AppColors.blue
//                       : AppColors.textMuted,
//                   fontSize: 9,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 6),
//         if (sources.isEmpty)
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               color: AppColors.bg,
//               border: Border.all(color: AppColors.border),
//             ),
//             child: const Center(
//               child: Text(
//                 'No source columns available — upload a column file to sources first',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: AppColors.textMuted, fontSize: 10),
//               ),
//             ),
//           )
//         else
//           for (final src in sources) ...[
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: AppColors.border),
//                 color: AppColors.surface,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.table_chart_rounded,
//                         size: 12,
//                         color: AppColors.blue,
//                       ),
//                       const SizedBox(width: 5),
//                       Expanded(
//                         child: Text(
//                           src.name,
//                           style: const TextStyle(
//                             color: AppColors.text,
//                             fontSize: 11,
//                             fontWeight: FontWeight.w700,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       // Quick All / None buttons
//                       GestureDetector(
//                         onTap: () {
//                           for (final c in src.cols) {
//                             final k = '${src.id}::$c';
//                             if (!localSelected.contains(k)) onToggle(k);
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 7,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(6),
//                             color: AppColors.blue.withValues(alpha: 0.12),
//                             border: Border.all(
//                               color: AppColors.blue.withValues(alpha: 0.40),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: const [
//                               Icon(
//                                 Icons.done_all_rounded,
//                                 size: 10,
//                                 color: AppColors.blue,
//                               ),
//                               SizedBox(width: 3),
//                               Text(
//                                 'All',
//                                 style: TextStyle(
//                                   color: AppColors.blue,
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       GestureDetector(
//                         onTap: () {
//                           for (final c in src.cols) {
//                             final k = '${src.id}::$c';
//                             if (localSelected.contains(k)) onToggle(k);
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 7,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(6),
//                             color: AppColors.red.withValues(alpha: 0.08),
//                             border: Border.all(
//                               color: AppColors.red.withValues(alpha: 0.35),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: const [
//                               Icon(
//                                 Icons.close_rounded,
//                                 size: 10,
//                                 color: AppColors.red,
//                               ),
//                               SizedBox(width: 3),
//                               Text(
//                                 'None',
//                                 style: TextStyle(
//                                   color: AppColors.red,
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         '${src.cols.where((c) => localSelected.contains('${src.id}::$c')).length}'
//                         '/${src.cols.length}',
//                         style: const TextStyle(
//                           color: AppColors.textDim,
//                           fontSize: 9,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   Wrap(
//                     spacing: 4,
//                     runSpacing: 4,
//                     children: src.cols.map((col) {
//                       final k = '${src.id}::$col';
//                       final sel = localSelected.contains(k);
//                       return GestureDetector(
//                         onTap: () => onToggle(k),
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 120),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 7,
//                             vertical: 3,
//                           ),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(6),
//                             color: sel ? AppColors.blue : AppColors.bg,
//                             border: Border.all(
//                               color: sel ? AppColors.blue : AppColors.border2,
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               if (sel) ...[
//                                 const Icon(
//                                   Icons.check_rounded,
//                                   size: 9,
//                                   color: Colors.white,
//                                 ),
//                                 const SizedBox(width: 3),
//                               ],
//                               Text(
//                                 col,
//                                 style: TextStyle(
//                                   color: sel ? Colors.white : AppColors.textDim,
//                                   fontSize: 9,
//                                   fontFamily: AppTextStyles.monoFamily,
//                                   fontWeight: sel
//                                       ? FontWeight.w600
//                                       : FontWeight.w400,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                   // ── Per-source Unique Field table ──
//                   Builder(
//                     builder: (_) {
//                       final selCols = src.cols
//                           .where((c) => localSelected.contains('${src.id}::$c'))
//                           .toList();
//                       if (selCols.isEmpty) return const SizedBox.shrink();
//                       return Column(
//                         children: [
//                           const SizedBox(height: 8),
//                           Container(
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(7),
//                               border: Border.all(color: AppColors.border),
//                             ),
//                             child: Column(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 5,
//                                   ),
//                                   decoration: const BoxDecoration(
//                                     borderRadius: BorderRadius.vertical(
//                                       top: Radius.circular(7),
//                                     ),
//                                     color: AppColors.bg,
//                                     border: Border(
//                                       bottom: BorderSide(
//                                         color: AppColors.border,
//                                       ),
//                                     ),
//                                   ),
//                                   child: const Row(
//                                     children: [
//                                       Icon(
//                                         Icons.edit_rounded,
//                                         size: 9,
//                                         color: AppColors.textMuted,
//                                       ),
//                                       SizedBox(width: 5),
//                                       Expanded(
//                                         child: Text(
//                                           'Column',
//                                           style: TextStyle(
//                                             color: AppColors.textMuted,
//                                             fontSize: 9,
//                                             fontWeight: FontWeight.w700,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 70,
//                                         child: Text(
//                                           'Unique Field',
//                                           textAlign: TextAlign.center,
//                                           style: TextStyle(
//                                             color: AppColors.amber,
//                                             fontSize: 9,
//                                             fontWeight: FontWeight.w700,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 ...selCols.asMap().entries.map((e) {
//                                   final i = e.key;
//                                   final col = e.value;
//                                   final k = '${src.id}::$col';
//                                   final isLast = i == selCols.length - 1;
//                                   return Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 10,
//                                       vertical: 4,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       borderRadius: isLast
//                                           ? const BorderRadius.vertical(
//                                               bottom: Radius.circular(7),
//                                             )
//                                           : null,
//                                       border: isLast
//                                           ? null
//                                           : const Border(
//                                               bottom: BorderSide(
//                                                 color: AppColors.border,
//                                                 width: 0.8,
//                                               ),
//                                             ),
//                                       color: i.isEven
//                                           ? AppColors.surface
//                                           : AppColors.surface2.withValues(
//                                               alpha: 0.5,
//                                             ),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         const Icon(
//                                           Icons.circle,
//                                           size: 5,
//                                           color: AppColors.textDim,
//                                         ),
//                                         const SizedBox(width: 6),
//                                         Expanded(
//                                           child: Text(
//                                             col,
//                                             style: const TextStyle(
//                                               color: AppColors.textDim,
//                                               fontSize: 9,
//                                               fontFamily:
//                                                   AppTextStyles.monoFamily,
//                                             ),
//                                             overflow: TextOverflow.ellipsis,
//                                           ),
//                                         ),
//                                         SizedBox(
//                                           width: 70,
//                                           child: Checkbox(
//                                             value:
//                                                 localUniqueFields[k] ?? false,
//                                             onChanged: (v) =>
//                                                 onUniqueFieldChanged(
//                                                   k,
//                                                   v ?? false,
//                                                 ),
//                                             materialTapTargetSize:
//                                                 MaterialTapTargetSize
//                                                     .shrinkWrap,
//                                             visualDensity:
//                                                 VisualDensity.compact,
//                                             activeColor: AppColors.amber,
//                                             side: const BorderSide(
//                                               color: AppColors.border2,
//                                               width: 1.2,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 }),
//                               ],
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             if (src != sources.last) const SizedBox(height: 6),
//           ],
//       ],
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';

class DynUniColSelectionCard extends StatelessWidget {
  final List<PipelineNode> sources;
  final Set<String> localSelected; // 'nodeId::colName'
  final Map<String, bool> localUniqueFields;
  final ValueChanged<String> onToggle;
  final void Function(String key, bool val) onUniqueFieldChanged;

  const DynUniColSelectionCard({super.key, 
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
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.blue.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.blue.withValues(alpha: 0.40),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.done_all_rounded,
                                size: 10,
                                color: AppColors.blue,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'All',
                                style: TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.red.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.close_rounded,
                                size: 10,
                                color: AppColors.red,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'None',
                                style: TextStyle(
                                  color: AppColors.red,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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





