// import 'package:flutter/material.dart';
// import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/uni_mailing_shared.dart';
// import 'package:vizualizer/core/theme/app_theme.dart';

// class StaticKeyMappingCard extends StatelessWidget {
//   final Map<String, String> workingMandatory;
//   final Map<String, String> workingCustom;
//   final int customCount;
//   final List<String> availableKeys;
//   final Map<String, String> colLabels;
//   final void Function(String field, String? val) onMandatoryChanged;
//   final void Function(String slot, String? val) onCustomChanged;
//   final VoidCallback onAddCustom;
//   final VoidCallback onRemoveCustom;

//   const StaticKeyMappingCard({super.key,
//     required this.workingMandatory,
//     required this.workingCustom,
//     required this.customCount,
//     required this.availableKeys,
//     required this.colLabels,
//     required this.onMandatoryChanged,
//     required this.onCustomChanged,
//     required this.onAddCustom,
//     required this.onRemoveCustom,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Step B header
//         Row(
//           children: [
//             const Icon(
//               Icons.settings_rounded,
//               size: 11,
//               color: AppColors.amber,
//             ),
//             const SizedBox(width: 4),
//             const Text(
//               'STEP B — STATIC MAPPING',
//               style: TextStyle(
//                 color: AppColors.amber,
//                 fontSize: 9,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 0.6,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 6),

//         // 7 UniMailing fields (all optional)
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
//                 letterSpacing: 0.5,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 5),
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
//               final cur = workingMandatory[field] ?? '';
//               final isMapped = cur.isNotEmpty && availableKeys.contains(cur);
//               return UniMappingRow(
//                 label: field,
//                 labelColor: AppColors.violet,
//                 currentKey: isMapped ? cur : null,
//                 availableKeys: availableKeys,
//                 colLabels: colLabels,
//                 isLast: isLast,
//                 isRequired: false,
//                 isMapped: isMapped,
//                 onChanged: (v) => onMandatoryChanged(field, v),
//               );
//             }).toList(),
//           ),
//         ),
//         const SizedBox(height: 10),

//         // Custom columns — Column 1 mandatory, rest required if added
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
//                 letterSpacing: 0.5,
//               ),
//             ),
//             const Spacer(),
//             if (customCount < 50)
//               GestureDetector(
//                 onTap: onAddCustom,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 5,
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
//                         'Add Column ${customCount + 1}',
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
//         const SizedBox(height: 5),
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: Column(
//             children: List.generate(customCount, (i) {
//               final slot = i + 1;
//               final key = 'C$slot';
//               final cur = workingCustom[key] ?? '';
//               final isMapped = cur.isNotEmpty && availableKeys.contains(cur);
//               final isLast = slot == customCount;
//               return UniMappingRow(
//                 label: 'Column $slot',
//                 labelColor: AppColors.violet,
//                 currentKey: isMapped ? cur : null,
//                 availableKeys: availableKeys,
//                 colLabels: colLabels,
//                 isLast: isLast,
//                 isRequired: true,
//                 isMapped: isMapped,
//                 onChanged: (v) => onCustomChanged(key, v),
//                 onDelete: isLast && slot > 1 ? onRemoveCustom : null,
//               );
//             }),
//           ),
//         ),
//       ],
//     );
//   }
// }








import 'package:flutter/material.dart';
import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/uni_mailing_shared.dart';
import 'package:vizualizer/core/theme/app_theme.dart';

class StaticKeyMappingCard extends StatelessWidget {
  final Map<String, String> workingMandatory;
  final Map<String, String> workingCustom;
  final int customCount;
  final List<String> availableKeys;
  final Map<String, String> colLabels;
  final void Function(String field, String? val) onMandatoryChanged;
  final void Function(String slot, String? val) onCustomChanged;
  final VoidCallback onAddCustom;
  final VoidCallback onRemoveCustom;

  const StaticKeyMappingCard({super.key,
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

        // 7 UniMailing fields (all optional)
        Row(
          children: [
            const Icon(Icons.email_outlined, size: 10, color: AppColors.violet),
            const SizedBox(width: 4),
            const Text(
              'UNIMAILING FIELDS',
              style: TextStyle(
                color: AppColors.violet,
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
            children: kMandatoryFields.asMap().entries.map((e) {
              final idx = e.key;
              final field = e.value;
              final isLast = idx == kMandatoryFields.length - 1;
              final cur = workingMandatory[field] ?? '';
              final isMapped = cur.isNotEmpty && availableKeys.contains(cur);
              return UniMappingRow(
                label: field,
                labelColor: AppColors.violet,
                currentKey: isMapped ? cur : null,
                availableKeys: availableKeys,
                colLabels: colLabels,
                isLast: isLast,
                isRequired: false,
                isMapped: isMapped,
                onChanged: (v) => onMandatoryChanged(field, v),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Custom columns — Column 1 mandatory, rest required if added
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
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (customCount < 50)
              GestureDetector(
                onTap: onAddCustom,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
                        'Add Column ${customCount + 1}',
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
        const SizedBox(height: 5),
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
              return UniMappingRow(
                label: 'Column $slot',
                labelColor: AppColors.violet,
                currentKey: isMapped ? cur : null,
                availableKeys: availableKeys,
                colLabels: colLabels,
                isLast: isLast,
                isRequired: true,
                isMapped: isMapped,
                onChanged: (v) => onCustomChanged(key, v),
                onDelete: isLast && slot > 1 ? onRemoveCustom : null,
              );
            }),
          ),
        ),
      ],
    );
  }
}

