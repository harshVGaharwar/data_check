part of 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node_body.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNIMAILING SECTION
// ─────────────────────────────────────────────────────────────────────────────

class UniMailingSection extends StatefulWidget {
  final PipelineController ctrl;
  final List<PipelineNode> sourceNodes;
  const UniMailingSection({super.key, required this.ctrl, required this.sourceNodes});

  @override
  State<UniMailingSection> createState() => UniMailingSectionState();
}

class UniMailingSectionState extends State<UniMailingSection> {
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

  ({
List<String> keys, Map<String, String> labels}) _buildAvailable() {
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
            children: kMandatoryFields.asMap().entries.map((e) {
              final idx = e.key;
              final field = e.value;
              final isLast = idx == kMandatoryFields.length - 1;
              final current = ctrl.uniMailingMandatory[field] ?? '';
              final isMapped = avail.keys.contains(current);
              return UniMappingRow(
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
                return UniMappingRow(
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
