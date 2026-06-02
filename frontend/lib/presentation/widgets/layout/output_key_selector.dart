
import 'package:flutter/material.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/presentation/widgets/common/searchable_dropdown.dart';

class OutputKeySelector extends StatelessWidget {
  final PipelineController ctrl;
  final void Function(String key, PipelineController ctrl) onOutputKeySelected;

  const OutputKeySelector({super.key, 
    required this.ctrl,
    required this.onOutputKeySelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = ctrl.dynamicUniMailingOutputKeys;
    final selected = ctrl.selectedOutputKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('OUTPUT KEY', style: AppTextStyles.sectionLabel),
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SearchableDropdownField(
          value: (selected.isEmpty || !items.contains(selected))
              ? null
              : selected,
          hint: '— Select Output Key —',
          items: items,
          disabledItems: ctrl.sequentiallyDisabledOutputKeys,
          leadingBuilder: (item) {
            final isDone = ctrl.savedOutputKeyConfigs.containsKey(item);
            return Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 13,
              color: isDone ? AppColors.green : AppColors.textDim,
            );
          },
          onChanged: (v) {
            if (v == null) return;
            ctrl.setSelectedOutputKey(v);
            onOutputKeySelected(v, ctrl);
          },
        ),
      ],
    );
  }
}
