import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/models/master_models.dart';
import 'package:vizualizer/services/master_data_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

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
  DashboardDetails? _dashboardDetails;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _loadDashboard();
  }

  Future<void> _waitForAuth() async {
    final auth =
        context.read<AuthProvider>(); // Replace with your actual provider type
    if (!auth.initialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return mounted && !context.read<AuthProvider>().initialized;
      });
    }
  }

  Future<void> _loadDashboard() async {
    await _waitForAuth();
    if (!mounted) return;

    final service = context
        .read<MasterDataService>(); // Replace with your actual service type
    final dashboardData = await service.getDashboardCount();

    if (mounted) {
      setState(() {
        _dashboardDetails = dashboardData; // Store the fetched data
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1 — KPI tiles
            _KpiRow(
              dashboardData: _dashboardDetails?.dashboardCount ?? [],
            ),
            SizedBox(height: 20),
            // 2 — Horizontal data flow
            _DataFlowCard(),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _UserInstructionCard()),
                SizedBox(width: 16),
                Expanded(child: _AdminInstructionCard()),
              ],
            ),
            // // 3 — Recent template configurations
            // _RecentConfigCard(),
            // SizedBox(height: 16),
            // // 4 — Upload breakdown
            // _UploadBreakdownCard(),
            // SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── 1. KPI Row ────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final List<DashboardCount> dashboardData;
  // static const _kpis = [
  //   _KpiData(
  //     'Total Templates',
  //     '24',
  //     Icons.layers_rounded,
  //     AppColors.blue,
  //     AppColors.blueDim,
  //     '+3 this month',
  //   ),
  //   _KpiData(
  //     'Manual Uploads',
  //     '147',
  //     Icons.upload_file_rounded,
  //     AppColors.violet,
  //     Color(0xFFEDE9FE),
  //     '+12 this week',
  //   ),
  //   _KpiData(
  //     'Pending Review',
  //     '8',
  //     Icons.pending_actions_rounded,
  //     AppColors.amber,
  //     AppColors.amberDim,
  //     'Awaiting Approval',
  //   ),
  //   _KpiData(
  //     'Auto Generated',
  //     '89',
  //     Icons.auto_fix_high_rounded,
  //     AppColors.cyan,
  //     Color(0xFFCFFAFE),
  //     '+5 today',
  //   ),
  //   _KpiData(
  //     'Success',
  //     '201',
  //     Icons.check_circle_outline_rounded,
  //     AppColors.green,
  //     AppColors.greenDim,
  //     '92.0% rate',
  //   ),
  //   _KpiData(
  //     'Failed',
  //     '12',
  //     Icons.cancel_outlined,
  //     AppColors.red,
  //     Color(0xFFFEE2E2),
  //     '5.5% rate',
  //   ),
  // ];
  const _KpiRow({Key? key, required this.dashboardData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 5 * 12) / 6;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < dashboardData.length; i++)
              SizedBox(
                width: cardWidth,
                child: _KpiCard(
                  data: _KpiData(
                      dashboardData[i].label,
                      dashboardData[i].count,
                      dashboardData[i].icon,
                      dashboardData[i].darkColor,
                      dashboardData[i].lightColor,
                      ''),
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
  final String count;
  final String icon;
  final String darkColor;
  final String lightColor;
  final String sub;
  const _KpiData(
    this.label,
    this.count,
    this.icon,
    this.darkColor,
    this.lightColor,
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

  late int darkColor;
  late int lightColor;
  late int iconId;
  int parseIcon(String code) {
    code = code.replaceAll("0x", "");
    return int.parse(code, radix: 16);
  }

  int parseColor(String hex) {
    hex = hex.replaceAll("#", "").replaceAll("0x", "");

    // API sends 6-digit hex → add FF
    if (hex.length == 6) {
      hex = "FF$hex";
    }

    return int.parse(hex, radix: 16);
  }

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

    darkColor = parseColor(widget.data.darkColor);
    lightColor = parseColor(widget.data.lightColor);
    iconId = parseIcon(widget.data.icon);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              color: _hovered ? Color(lightColor!) : AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _hovered
                    ? Color(darkColor!).withValues(alpha: 0.4)
                    : AppColors.border,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: Color(darkColor!).withValues(alpha: 0.14),
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
                        color: Color(darkColor!).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.layers_rounded,
                          color: Color(darkColor), size: 15),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: double.tryParse(widget.data.count) ?? 0,
                      ),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOut,
                      builder: (_, val, __) => Text(
                        val.toInt().toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(darkColor),
                          fontFamily: AppTextStyles.monoFamily,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.data.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                // const SizedBox(height: 2),
                // Text(
                //   d.sub,
                //   style: const TextStyle(
                //     fontSize: 9.5,
                //     color: AppColors.textMuted,
                //   ),
                // ),
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
  final String team;
  final Color color;
  final Color bg;
  const _FlowStepData({
    required this.icon,
    required this.label,
    required this.desc,
    required this.team,
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
      team: 'Admin Team',
      color: AppColors.blue,
      bg: AppColors.blueDim,
    ),
    _FlowStepData(
      icon: Icons.layers_rounded,
      label: 'Template\nCreation',
      desc: 'Schema, SPOC,\napprovals & schedule',
      team: 'Admin Team',
      color: AppColors.violet,
      bg: Color(0xFFEDE9FE),
    ),
    _FlowStepData(
      icon: Icons.account_tree_rounded,
      label: 'Template\nConfiguration',
      desc: 'Drag-and-drop nodes\n& join mappings',
      team: 'Admin Team',
      color: AppColors.cyan,
      bg: Color(0xFFCFFAFE),
    ),
    _FlowStepData(
      icon: Icons.upload_file_rounded,
      label: 'Manual\nUpload',
      desc: 'Upload per-slot\ndata files',
      team: 'Authorized User Team',
      color: AppColors.amber,
      bg: AppColors.amberDim,
    ),
    _FlowStepData(
      icon: Icons.fact_check_rounded,
      label: 'QA\nChecker',
      desc: 'Review, approve\nor reject output',
      team: 'Authorized Operation Team',
      color: AppColors.green,
      bg: AppColors.greenDim,
    ),
    _FlowStepData(
      icon: Icons.bar_chart_rounded,
      label: 'Reports &\nAnalytics',
      desc: 'Status, success\nrates & metrics',
      team: 'User and Admin Team',
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
            color:
                _hovered ? d.color.withValues(alpha: 0.3) : Colors.transparent,
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
            Text(
              d.team,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.text,
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
          Container(width: 10, height: 3.5, color: AppColors.border),
          const Icon(
            Icons.chevron_right_rounded,
            size: 56,
            color: AppColors.textMuted,
          ),
          Container(width: 10, height: 3.5, color: AppColors.border),
        ],
      ),
    );
  }
}

class _UserInstructionCard extends StatelessWidget {
  const _UserInstructionCard();

  static const _points = [
    "Upload manual data files as per the template schedule.",
    "Ensure file naming conventions strictly follow the configured rules.",
    "Validate uploaded data using the QA Checker before submission.",
    "Monitor submission status in Reports & Analytics.",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
            children: const [
              Icon(Icons.person_rounded, size: 18, color: AppColors.blue),
              SizedBox(width: 8),
              Text("USER INSTRUCTIONS", style: AppTextStyles.sectionLabel),
            ],
          ),
          const SizedBox(height: 18),
          for (var p in _points) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    p,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.text,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _AdminInstructionCard extends StatelessWidget {
  const _AdminInstructionCard();

  static const _points = [
    "Configure data sources and maintain template versioning.",
    "Review and approve new template requests from users.",
    "Monitor system health, failed uploads, and processing delays.",
    "Oversee analytics dashboards and manage user access roles.",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
            children: const [
              Icon(Icons.admin_panel_settings_rounded,
                  size: 18, color: AppColors.violet),
              SizedBox(width: 8),
              Text("ADMIN INSTRUCTIONS", style: AppTextStyles.sectionLabel),
            ],
          ),
          const SizedBox(height: 18),
          for (var p in _points) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    p,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.text,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
