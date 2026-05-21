part of 'sidebar.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// JOIN PALETTE ITEM — locked until all source nodes are confirmed
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _JoinPaletteItem extends StatefulWidget {
  final PipelineController ctrl;
  const _JoinPaletteItem({required this.ctrl});

  @override
  State<_JoinPaletteItem> createState() => _JoinPaletteItemState();
}

class _JoinPaletteItemState extends State<_JoinPaletteItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  bool _lastUnlocked = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _lastUnlocked = widget.ctrl.shouldAnimateJoin;
    if (_lastUnlocked) _pulseCtrl.repeat(reverse: true);
  }

  void _syncAnimation(bool shouldAnimate) {
    if (shouldAnimate && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!shouldAnimate && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
    _lastUnlocked = shouldAnimate;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.ctrl.allSourceNodesConfirmed;
    final shouldAnimate = widget.ctrl.shouldAnimateJoin;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAnimation(shouldAnimate);
    });
    const type = NodeType.join;
    const color = AppColors.blue;

    Widget content({double glowAlpha = 0, double borderAlpha = 1}) => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unlocked
              ? color.withValues(alpha: 0.4 + borderAlpha * 0.6)
              : AppColors.border2,
          width: unlocked ? 1.8 : 1.0,
        ),
        color: unlocked
            ? color.withValues(alpha: 0.04 + glowAlpha * 0.08)
            : AppColors.surface2,
        boxShadow: unlocked && glowAlpha > 0
            ? [
                BoxShadow(
                  color: color.withValues(alpha: glowAlpha * 0.35),
                  blurRadius: 8 + glowAlpha * 10,
                  spreadRadius: glowAlpha * 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: color.withValues(
                alpha: unlocked ? 0.12 + glowAlpha * 0.1 : 0.07,
              ),
            ),
            child: Icon(
              unlocked ? type.icon : Icons.lock_outline_rounded,
              color: unlocked ? color : AppColors.textMuted,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    color: unlocked ? AppColors.text : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  unlocked ? '✦ Ready to drag' : 'Confirm all sources first',
                  style: TextStyle(
                    color: unlocked
                        ? color.withValues(alpha: 0.8)
                        : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Icon(
                Icons.arrow_forward_rounded,
                color: color.withValues(alpha: 0.4 + _pulseAnim.value * 0.6),
                size: 14,
              ),
            ),
        ],
      ),
    );

    if (!unlocked) {
      return GestureDetector(
        onTap: () {
          final sources = widget.ctrl.nodes
              .where((n) => n.type.isSource)
              .toList();
          final required = widget.ctrl.requiredSourceCount;
          final confirmed = sources
              .where((n) => n.confirmState == NodeConfirmState.confirmed)
              .length;
          final String msg;
          if (required > 0 && sources.length < required) {
            msg =
                'Add all $required required source nodes first'
                ' (${sources.length}/$required added).';
          } else {
            msg =
                'Configure all source nodes first'
                ' ($confirmed/${sources.length} confirmed).';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.orange),
          );
        },
        child: Opacity(opacity: 0.5, child: content()),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) => Draggable<DragNodeData>(
        data: DragNodeData(type),
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: content()),
        child: content(
          glowAlpha: _pulseAnim.value,
          borderAlpha: _pulseAnim.value,
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STEP HIGHLIGHT — animated glowing border + bg around a sidebar section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _StepHighlight extends AnimatedWidget {
  final Color color;
  final Widget child;

  const _StepHighlight({
    required Animation<double> animation,
    required this.color,
    required this.child,
  }) : super(listenable: animation);

  Animation<double> get _anim => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final t = _anim.value;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: t * 0.6), width: 1.5),
        boxShadow: t > 0.1
            ? [
                BoxShadow(
                  color: color.withValues(alpha: t * 0.25),
                  blurRadius: 6,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TEMPLATE CONFIG BADGE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _TemplateConfigBadge extends StatelessWidget {
  final String templateType;
  final List<String> outputFormats;

  const _TemplateConfigBadge({
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
              _ConfigRow(
                icon: typeIcon,
                header: 'Template Type',
                value: typeLabel,
                color: typeColor,
                isFirst: true,
              ),
              Divider(height: 1, color: AppColors.border),
              if (formatLabel.isNotEmpty)
                _ConfigRow(
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIG ROW — single row inside TemplateConfigBadge card
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ConfigRow extends StatelessWidget {
  final IconData icon;
  final String header;
  final String value;
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _ConfigRow({
    required this.icon,
    required this.header,
    required this.value,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(10) : Radius.zero,
          bottom: isLast ? const Radius.circular(10) : Radius.zero,
        ),
        color: color.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// OUTPUT KEY SELECTOR — Dynamic UniMailing flow
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _OutputKeySelector extends StatelessWidget {
  final PipelineController ctrl;
  final void Function(String key, PipelineController ctrl) onOutputKeySelected;

  const _OutputKeySelector({
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
          disabledItems: ctrl.savedOutputKeyConfigs.keys.toSet(),
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
