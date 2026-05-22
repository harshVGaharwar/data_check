import 'package:flutter/material.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/presentation/widgets/common/searchable_dropdown.dart';

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

  const UniMappingRow({super.key, 
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
                value: currentKey != null ? (colLabels[currentKey!] ?? currentKey) : null,
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
              onTap: onDelete,
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
