part of '../output_node_body.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNIMAILING SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _UniMailingSection extends StatefulWidget {
  final PipelineController ctrl;
  final List<PipelineNode> sourceNodes;
  const _UniMailingSection({required this.ctrl, required this.sourceNodes});

  @override
  State<_UniMailingSection> createState() => _UniMailingSectionState();
}

class _UniMailingSectionState extends State<_UniMailingSection> {
  late int _customCount;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onCtrlChange);
    _customCount = _deriveCustomCount();
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
    final srcNodes = widget.sourceNodes
        .where((n) => n.selectedCols.isNotEmpty)
        .toList();
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
        // Mandatory fields
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 10, color: AppColors.red),
            const SizedBox(width: 4),
            const Text(
              'MANDATORY FIELDS',
              style: TextStyle(
                color: AppColors.red,
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
            children: _kMandatoryFields.asMap().entries.map((e) {
              final idx = e.key;
              final field = e.value;
              final isLast = idx == _kMandatoryFields.length - 1;
              final current = ctrl.uniMailingMandatory[field] ?? '';
              final isMapped = avail.keys.contains(current);
              return _UniMappingRow(
                label: field,
                labelColor: AppColors.red,
                currentKey: isMapped ? current : null,
                availableKeys: avail.keys,
                colLabels: avail.labels,
                isLast: isLast,
                isRequired: true,
                isMapped: isMapped,
                onChanged: (v) => ctrl.setUniMailingMandatory(field, v ?? ''),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

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
              'CUSTOM COLUMNS (C1–C50)',
              style: TextStyle(
                color: AppColors.violet,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: AppColors.violet.withValues(alpha: 0.08),
              ),
              child: const Text(
                'optional',
                style: TextStyle(
                  color: AppColors.violet,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            if (_customCount < 50)
              GestureDetector(
                onTap: () => setState(() => _customCount++),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.violet.withValues(alpha: 0.10),
                    border: Border.all(
                      color: AppColors.violet.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 11,
                        color: AppColors.violet,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Add C${_customCount + 1}',
                        style: const TextStyle(
                          color: AppColors.violet,
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
                return _UniMappingRow(
                  label: key,
                  labelColor: AppColors.violet,
                  currentKey: isMapped ? current : null,
                  availableKeys: avail.keys,
                  colLabels: avail.labels,
                  isLast: isLast,
                  isRequired: false,
                  isMapped: isMapped,
                  onChanged: (v) => ctrl.setUniMailingCustom(key, v ?? ''),
                  onDelete: isLast
                      ? () {
                          ctrl.setUniMailingCustom(key, '');
                          setState(() => _customCount--);
                        }
                      : null,
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIMAILING MAPPING ROW
// ─────────────────────────────────────────────────────────────────────────────

class _UniMappingRow extends StatelessWidget {
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

  const _UniMappingRow({
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
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
                color: isMapped
                    ? labelColor.withValues(alpha: 0.04)
                    : AppColors.bg,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: DropdownButton<String?>(
                value: currentKey,
                hint: Text(
                  isRequired ? '— required —' : '— optional —',
                  style: TextStyle(
                    color: isRequired
                        ? AppColors.red.withValues(alpha: 0.65)
                        : AppColors.textMuted,
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                isExpanded: true,
                isDense: true,
                underline: const SizedBox.shrink(),
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 14,
                  color: isMapped ? labelColor : AppColors.textDim,
                ),
                onChanged: onChanged,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      '— clear —',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  ...availableKeys.map(
                    (k) => DropdownMenuItem<String?>(
                      value: k,
                      child: Text(
                        colLabels[k] ?? k,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 9,
                          fontFamily: AppTextStyles.monoFamily,
                        ),
                      ),
                    ),
                  ),
                ],
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
