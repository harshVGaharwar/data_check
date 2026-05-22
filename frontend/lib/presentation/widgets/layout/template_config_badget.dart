import 'package:flutter/material.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/presentation/widgets/layout/config_row.dart';

class TemplateConfigBadge extends StatelessWidget {
  final String templateType;
  final List<String> outputFormats;

  const TemplateConfigBadge({super.key, 
    required this.templateType,
    required this.outputFormats,
  });

  @override
  Widget build(BuildContext context) {
    final isStatic =
        templateType.toLowerCase().contains('static') ||
        templateType == '1' ||
        templateType == '2';
    final typeLabel = isStatic ? 'Static' : 'Dynamic';
    final typeColor = isStatic ? AppColors.green : AppColors.blue;
    final typeIcon = isStatic ? Icons.lock_outline_rounded : Icons.sync_rounded;

    final isUniMailing = outputFormats.any(
      (f) => f.toLowerCase().contains('unimailing'),
    );
    final isUserDefined = outputFormats.any(
      (f) => f.toLowerCase().replaceAll(' ', '').contains('userdefined'),
    );

    final formatLabel = isUniMailing
        ? 'UniMailing'
        : isUserDefined
        ? 'User Defined'
        : outputFormats.where((f) => f.isNotEmpty).join(', ');
    final formatColor = isUniMailing
        ? AppColors.amber
        : isUserDefined
        ? AppColors.violet
        : AppColors.textDim;
    final formatIcon = isUniMailing
        ? Icons.email_rounded
        : isUserDefined
        ? Icons.tune_rounded
        : Icons.description_rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TEMPLATE CONFIG', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              ConfigRow(
                icon: typeIcon,
                header: 'Template Type',
                value: typeLabel,
                color: typeColor,
                isFirst: true,
              ),
              Divider(height: 1, color: AppColors.border),
              if (formatLabel.isNotEmpty)
                ConfigRow(
                  icon: formatIcon,
                  header: 'Output Format',
                  value: formatLabel,
                  color: formatColor,
                  isLast: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}