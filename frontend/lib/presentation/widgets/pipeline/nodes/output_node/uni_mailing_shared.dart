// import 'package:flutter/material.dart';
// import 'package:vizualizer/core/theme/app_theme.dart';
// import 'package:vizualizer/presentation/widgets/common/searchable_dropdown.dart';

// const kMandatoryFields = [
//   'Mail To',
//   'Mail CC',
//   'Mail BCC',
//   'Subject',
//   'Attachment',
//   'SMS To',
//   'Barcode',
// ];

// class UniMappingRow extends StatelessWidget {
//   final String label;
//   final Color labelColor;
//   final String? currentKey;
//   final List<String> availableKeys;
//   final Map<String, String> colLabels;
//   final bool isLast;
//   final bool isRequired;
//   final bool isMapped;
//   final ValueChanged<String?> onChanged;
//   final VoidCallback? onDelete;

//   const UniMappingRow({
//     super.key,
//     required this.label,
//     required this.labelColor,
//     required this.currentKey,
//     required this.availableKeys,
//     required this.colLabels,
//     required this.isLast,
//     required this.isRequired,
//     required this.isMapped,
//     required this.onChanged,
//     this.onDelete,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final borderColor = !isMapped && isRequired
//         ? AppColors.red.withValues(alpha: 0.45)
//         : isMapped
//         ? labelColor.withValues(alpha: 0.28)
//         : AppColors.border2;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         borderRadius: isLast
//             ? const BorderRadius.vertical(bottom: Radius.circular(8))
//             : null,
//         border: isLast
//             ? null
//             : const Border(
//                 bottom: BorderSide(color: AppColors.border, width: 0.8),
//               ),
//         color: isMapped
//             ? labelColor.withValues(alpha: 0.03)
//             : AppColors.surface,
//       ),
//       child: Row(
//         children: [
//           Container(
//             constraints: const BoxConstraints(minWidth: 60),
//             padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(5),
//               color: isMapped
//                   ? labelColor.withValues(alpha: 0.12)
//                   : AppColors.surface2,
//               border: Border.all(
//                 color: isMapped
//                     ? labelColor.withValues(alpha: 0.28)
//                     : AppColors.border2,
//               ),
//             ),
//             child: Text(
//               label,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: isMapped ? labelColor : AppColors.textMuted,
//                 fontSize: 9,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//           const SizedBox(width: 6),
//           const Icon(
//             Icons.arrow_forward_rounded,
//             size: 10,
//             color: AppColors.textMuted,
//           ),
//           const SizedBox(width: 6),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(6),
//                 border: Border.all(color: borderColor),
//                 color: isMapped
//                     ? labelColor.withValues(alpha: 0.04)
//                     : AppColors.bg,
//               ),
//               child: SearchableDropdownField(
//                 height: 28,
//                 items: availableKeys.map((k) => colLabels[k] ?? k).toList(),
//                 value: currentKey != null
//                     ? (colLabels[currentKey!] ?? currentKey)
//                     : null,
//                 hint: isRequired ? '— required —' : '— optional —',
//                 onChanged: (displayLabel) {
//                   if (displayLabel == null) {
//                     onChanged(null);
//                     return;
//                   }
//                   final key = availableKeys.firstWhere(
//                     (k) => (colLabels[k] ?? k) == displayLabel,
//                     orElse: () => displayLabel,
//                   );
//                   onChanged(key);
//                 },
//               ),
//             ),
//           ),
//           const SizedBox(width: 6),
//           if (onDelete != null)
//             GestureDetector(
//               onTap: onDelete,
//               child: const Icon(
//                 Icons.remove_circle_outline_rounded,
//                 size: 15,
//                 color: AppColors.red,
//               ),
//             )
//           else
//             Container(
//               width: 6,
//               height: 6,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: isMapped ? AppColors.green : AppColors.red,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/presentation/widgets/common/searchable_dropdown.dart';

const kMandatoryFields = [
  'Mail To',
  'Mail CC',
  'Mail BCC',
  'Subject',
  'Attachment',
  'SMS To',
  'Barcode',
];

class UniMappingRow extends StatelessWidget {
  final String label;
  final Color labelColor;
  final String? currentKey;
  final List<String> availableKeys;
  final Map<String, String> colLabels;
  final bool isLast;
  final bool isRequired;
  final bool isMapped;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onDelete;

  const UniMappingRow({
    super.key,
    required this.label,
    required this.labelColor,
    required this.currentKey,
    required this.availableKeys,
    required this.colLabels,
    required this.isLast,
    required this.isRequired,
    required this.isMapped,
    required this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = !isMapped && isRequired
        ? AppColors.red.withValues(alpha: 0.45)
        : isMapped
        ? labelColor.withValues(alpha: 0.28)
        : AppColors.border2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(8))
            : null,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.8),
              ),
        color: isMapped
            ? labelColor.withValues(alpha: 0.03)
            : AppColors.surface,
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: isMapped
                  ? labelColor.withValues(alpha: 0.12)
                  : AppColors.surface2,
              border: Border.all(
                color: isMapped
                    ? labelColor.withValues(alpha: 0.28)
                    : AppColors.border2,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isMapped ? labelColor : AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 10,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
                color: isMapped
                    ? labelColor.withValues(alpha: 0.04)
                    : AppColors.bg,
              ),
              child: SearchableDropdownField(
                height: 28,
                items: availableKeys.map((k) => colLabels[k] ?? k).toList(),
                value: currentKey != null
                    ? (colLabels[currentKey!] ?? currentKey)
                    : null,
                hint: isRequired ? '— required —' : '— optional —',
                onChanged: (displayLabel) {
                  if (displayLabel == null) {
                    onChanged(null);
                    return;
                  }
                  final key = availableKeys.firstWhere(
                    (k) => (colLabels[k] ?? k) == displayLabel,
                    orElse: () => displayLabel,
                  );
                  onChanged(key);
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (onDelete != null)
            GestureDetector(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogCtx) => Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 360,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 26,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Top banner ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 26),
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.06),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.red.withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 24,
                                      color: AppColors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Delete Column?",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Body ──
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Warning box
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 14),
                                          decoration: BoxDecoration(
                                            color: AppColors.amberDim,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: AppColors.amber
                                                  .withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.warning_amber_rounded,
                                                size: 16,
                                                color: AppColors.amber,
                                              ),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Text(
                                                  "This action cannot be undone.",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.text,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Amber left strip
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 4,
                                            color: AppColors.amber,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  const Text(
                                    "Are you sure you want to delete this column?",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textDim,
                                      height: 1.5,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // ── Buttons ──
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.of(dialogCtx).pop(false),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            side: const BorderSide(
                                                color: AppColors.border2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              Navigator.of(dialogCtx).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16),
                                          label: const Text(
                                            "Delete",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                if (confirmed == true) {
                  onDelete!();
                }
              },
              child: const Icon(
                Icons.remove_circle_outline_rounded,
                size: 15,
                color: AppColors.red,
              ),
            )
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMapped ? AppColors.green : AppColors.red,
              ),
            ),
        ],
      ),
    );
  }
}
