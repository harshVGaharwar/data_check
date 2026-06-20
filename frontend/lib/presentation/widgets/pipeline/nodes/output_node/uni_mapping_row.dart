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
  // When non-null, the label badge becomes an editable text field.
  final ValueChanged<String>? onLabelChanged;
  // Placeholder shown in the editable badge when the label is blank.
  final String? labelHint;

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
    this.onLabelChanged,
    this.labelHint,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = !isMapped && isRequired
        ? AppColors.red.withValues(alpha: 0.45)
        : isMapped
        ? labelColor.withValues(alpha: 0.28)
        : AppColors.border2;

    final badgeBgColor = isMapped
        ? labelColor.withValues(alpha: 0.12)
        : AppColors.surface2;
    final badgeBorderColor = isMapped
        ? labelColor.withValues(alpha: 0.28)
        : AppColors.border2;
    final badgeTextColor = isMapped ? labelColor : AppColors.textMuted;
    final badgeTextStyle = TextStyle(
      color: badgeTextColor,
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );

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
            // Editable badge needs a bounded width — a TextField cannot lay out
            // under the unbounded width a Row gives non-flex children.
            constraints: onLabelChanged == null
                ? const BoxConstraints(minWidth: 60)
                : const BoxConstraints(minWidth: 60, maxWidth: 110),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: badgeBgColor,
              border: Border.all(color: badgeBorderColor),
            ),
            child: onLabelChanged == null
                ? Text(
                    label,
                    textAlign: TextAlign.center,
                    style: badgeTextStyle,
                  )
                : _EditableLabel(
                    label: label,
                    hint: labelHint,
                    textStyle: badgeTextStyle,
                    hintColor: badgeTextColor.withValues(alpha: 0.5),
                    onChanged: onLabelChanged!,
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
                hint: isRequired ? '— required —' : '— select —',
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

/// Compact, borderless text field styled to match the static label badge so the
/// row's look & feel is unchanged while allowing the label to be renamed.
class _EditableLabel extends StatefulWidget {
  final String label;
  final String? hint;
  final TextStyle textStyle;
  final Color hintColor;
  final ValueChanged<String> onChanged;

  const _EditableLabel({
    required this.label,
    required this.hint,
    required this.textStyle,
    required this.hintColor,
    required this.onChanged,
  });

  @override
  State<_EditableLabel> createState() => _EditableLabelState();
}

class _EditableLabelState extends State<_EditableLabel> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.label);
  }

  @override
  void didUpdateWidget(covariant _EditableLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when the external label changes (e.g. reset),
    // but don't fight the user while they're typing.
    if (widget.label != _controller.text && !_focusNode.hasFocus) {
      _controller.text = widget.label;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: TextAlign.center,
      style: widget.textStyle,
      cursorColor: widget.textStyle.color,
      cursorWidth: 1,
      cursorHeight: 11,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: widget.hint,
        hintStyle: widget.textStyle.copyWith(color: widget.hintColor),
      ),
    );
  }
}
