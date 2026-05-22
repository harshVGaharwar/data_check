import 'package:flutter/material.dart';
import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/uni_mailing_shared.dart';
import 'package:vizualizer/core/theme/app_theme.dart';

class DynamicKeyMappingCard extends StatelessWidget {
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

  const DynamicKeyMappingCard({super.key, 
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
              UniMappingRow(
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
              UniMappingRow(
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
                return UniMappingRow(
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
