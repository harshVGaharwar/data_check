import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class WelcomePage extends StatefulWidget {
  final void Function(int index) onNavigate;
  const WelcomePage({super.key, required this.onNavigate});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>().user?.user;

    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // 1 — KPI tiles
            _KpiRow(),
            SizedBox(height: 20),
            // 2 — Horizontal data flow
            _DataFlowCard(),
            SizedBox(height: 16),
            // 3 — Recent template configurations
            _RecentConfigCard(),
            SizedBox(height: 16),
            // 4 — Upload breakdown
            _UploadBreakdownCard(),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── 1. KPI Row ────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  static const _kpis = [
    _KpiData(
      'Total Templates',
      '24',
      Icons.layers_rounded,
      AppColors.blue,
      AppColors.blueDim,
      '+3 this month',
    ),
    _KpiData(
      'Manual Uploads',
      '147',
      Icons.upload_file_rounded,
      AppColors.violet,
      Color(0xFFEDE9FE),
      '+12 this week',
    ),
    _KpiData(
      'Auto Generated',
      '89',
      Icons.auto_fix_high_rounded,
      AppColors.cyan,
      Color(0xFFCFFAFE),
      '+5 today',
    ),
    _KpiData(
      'Success',
      '201',
      Icons.check_circle_outline_rounded,
      AppColors.green,
      AppColors.greenDim,
      '92.0% rate',
    ),
    _KpiData(
      'Failed',
      '12',
      Icons.cancel_outlined,
      AppColors.red,
      Color(0xFFFEE2E2),
      '5.5% rate',
    ),
    _KpiData(
      'Pending Review',
      '8',
      Icons.pending_actions_rounded,
      AppColors.amber,
      AppColors.amberDim,
      'Awaiting QA',
    ),
  ];

  const _KpiRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 5 * 12) / 6;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < _kpis.length; i++)
              SizedBox(
                width: cardWidth,
                child: _KpiCard(
                  data: _kpis[i],
                  delay: Duration(milliseconds: i * 70),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final String sub;
  const _KpiData(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.bg,
    this.sub,
  );
}

class _KpiCard extends StatefulWidget {
  final _KpiData data;
  final Duration delay;
  const _KpiCard({required this.data, required this.delay});

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hovered ? d.bg : AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _hovered
                    ? d.color.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: d.color.withValues(alpha: 0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: d.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(d.icon, color: d.color, size: 15),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: double.tryParse(d.value) ?? 0,
                      ),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOut,
                      builder: (_, val, __) => Text(
                        val.toInt().toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: d.color,
                          fontFamily: AppTextStyles.monoFamily,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  d.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.sub,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 2. Data Flow (horizontal) ─────────────────────────────────────────────────

class _FlowStepData {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final Color bg;
  const _FlowStepData({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.bg,
  });
}

class _DataFlowCard extends StatelessWidget {
  static const _steps = [
    _FlowStepData(
      icon: Icons.storage_rounded,
      label: 'Source\nConfiguration',
      desc: 'Register DB, Manual,\nQRS, FC & Laser',
      color: AppColors.blue,
      bg: AppColors.blueDim,
    ),
    _FlowStepData(
      icon: Icons.layers_rounded,
      label: 'Template\nCreation',
      desc: 'Schema, SPOC,\napprovals & schedule',
      color: AppColors.violet,
      bg: Color(0xFFEDE9FE),
    ),
    _FlowStepData(
      icon: Icons.account_tree_rounded,
      label: 'Template\nConfiguration',
      desc: 'Drag-and-drop nodes\n& join mappings',
      color: AppColors.cyan,
      bg: Color(0xFFCFFAFE),
    ),
    _FlowStepData(
      icon: Icons.upload_file_rounded,
      label: 'Manual\nUpload',
      desc: 'Upload per-slot\ndata files',
      color: AppColors.amber,
      bg: AppColors.amberDim,
    ),
    _FlowStepData(
      icon: Icons.fact_check_rounded,
      label: 'QA\nChecker',
      desc: 'Review, approve\nor reject output',
      color: AppColors.green,
      bg: AppColors.greenDim,
    ),
    _FlowStepData(
      icon: Icons.bar_chart_rounded,
      label: 'Reports &\nAnalytics',
      desc: 'Status, success\nrates & metrics',
      color: Color(0xFF6366F1),
      bg: Color(0xFFEEF2FF),
    ),
  ];

  const _DataFlowCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.blueDim,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  color: AppColors.blue,
                  size: 13,
                ),
              ),
              const SizedBox(width: 8),
              const Text('DATA FLOW', style: AppTextStyles.sectionLabel),
              const SizedBox(width: 8),
              const Text(
                '·',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 8),
              const Text(
                'How DATA FUSION works',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // horizontal flow
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  Expanded(
                    child: _HorizontalFlowStep(step: i + 1, data: _steps[i]),
                  ),
                  if (i < _steps.length - 1) const _HorizontalConnector(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalFlowStep extends StatefulWidget {
  final int step;
  final _FlowStepData data;
  const _HorizontalFlowStep({required this.step, required this.data});

  @override
  State<_HorizontalFlowStep> createState() => _HorizontalFlowStepState();
}

class _HorizontalFlowStepState extends State<_HorizontalFlowStep> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _hovered ? d.bg : Colors.transparent,
          border: Border.all(
            color: _hovered
                ? d.color.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // icon circle with step badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: d.bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: d.color.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                              color: d.color.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(d.icon, color: d.color, size: 22),
                ),
                // step number badge
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: d.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.step}',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // label
            Text(
              d.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            // description
            Text(
              d.desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalConnector extends StatelessWidget {
  const _HorizontalConnector();

  @override
  Widget build(BuildContext context) {
    // vertically centred at the icon circle midpoint (52/2 + 10 padding = 36)
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 1.5, color: AppColors.border),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          Container(width: 10, height: 1.5, color: AppColors.border),
        ],
      ),
    );
  }
}

// ── 3. Recent Template Configurations ────────────────────────────────────────

class _ActivityData {
  final String id;
  final String dept;
  final String status;
  final String time;
  final Color statusColor;
  const _ActivityData(
    this.id,
    this.dept,
    this.status,
    this.time,
    this.statusColor,
  );
}

class _RecentConfigCard extends StatefulWidget {
  static const _rows = [
    _ActivityData(
      'TMP-2024-001',
      'Finance',
      'Success',
      '2h ago',
      AppColors.green,
    ),
    _ActivityData(
      'TMP-2024-009',
      'Risk Mgmt',
      'Processing',
      '4h ago',
      AppColors.amber,
    ),
    _ActivityData(
      'TMP-2024-012',
      'Retail Banking',
      'Success',
      '6h ago',
      AppColors.green,
    ),
    _ActivityData(
      'TMP-2024-015',
      'Treasury',
      'Failed',
      '8h ago',
      AppColors.red,
    ),
    _ActivityData(
      'TMP-2024-018',
      'Operations',
      'Pending',
      '1d ago',
      AppColors.slate,
    ),
    _ActivityData(
      'TMP-2024-021',
      'Compliance',
      'Success',
      '1d ago',
      AppColors.green,
    ),
  ];

  const _RecentConfigCard();

  @override
  State<_RecentConfigCard> createState() => _RecentConfigCardState();
}

class _RecentConfigCardState extends State<_RecentConfigCard> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.blueDim,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.blue,
                  size: 13,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'RECENT TEMPLATE CONFIGURATIONS',
                style: AppTextStyles.sectionLabel,
              ),
              const Spacer(),
              const _LiveDot(),
              const SizedBox(width: 4),
              const Text(
                'Live',
                style: TextStyle(fontSize: 10, color: AppColors.textDim),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('REQUEST ID', style: AppTextStyles.tableHeader),
              ),
              Expanded(
                flex: 3,
                child: Text('DEPARTMENT', style: AppTextStyles.tableHeader),
              ),
              Expanded(
                flex: 2,
                child: Text('STATUS', style: AppTextStyles.tableHeader),
              ),
              Expanded(
                flex: 2,
                child: Text('TIME', style: AppTextStyles.tableHeader),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 4),
          for (var i = 0; i < _RecentConfigCard._rows.length; i++)
            MouseRegion(
              // onEnter: (_) => setState(() => _hoveredIndex = i),
              // onExit: (_) => setState(() {
              //   if (_hoveredIndex == i) _hoveredIndex = -1;
              // }),
              child: _ConfigRow(
                data: _RecentConfigCard._rows[i],
                isHovered: _hoveredIndex == i,
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: _pulse.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final _ActivityData data;
  final bool isHovered;
  const _ConfigRow({required this.data, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final d = data;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isHovered ? AppColors.bg : Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              d.id,
              style: const TextStyle(
                fontFamily: AppTextStyles.monoFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              d.dept,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textDim),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: d.statusColor.withValues(
                    alpha: isHovered ? 0.18 : 0.1,
                  ),
                ),
                child: Text(
                  d.status,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: d.statusColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              d.time,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. Upload Breakdown ───────────────────────────────────────────────────────

class _UploadBreakdownCard extends StatelessWidget {
  static const _bars = [
    _BarData('DB Sync', 0.72, 72, AppColors.blue),
    _BarData('Manual', 0.58, 58, AppColors.violet),
    _BarData('QRS', 0.35, 35, AppColors.cyan),
    _BarData('FC', 0.44, 44, AppColors.amber),
    _BarData('Laser', 0.22, 22, AppColors.green),
  ];

  const _UploadBreakdownCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.greenDim,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.stacked_bar_chart_rounded,
                  color: AppColors.green,
                  size: 13,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'UPLOAD BREAKDOWN BY SOURCE TYPE',
                style: AppTextStyles.sectionLabel,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: _bars
                .map(
                  (b) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _AnimatedBar(data: b),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BarData {
  final String label;
  final double fraction;
  final int count;
  final Color color;
  const _BarData(this.label, this.fraction, this.count, this.color);
}

class _AnimatedBar extends StatelessWidget {
  final _BarData data;
  const _AnimatedBar({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textDim,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${data.count}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: data.color,
                fontFamily: AppTextStyles.monoFamily,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: data.fraction),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
          builder: (_, value, __) => Stack(
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.border,
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [data.color.withValues(alpha: 0.7), data.color],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(data.fraction * 100).toInt()}% of total',
          style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
