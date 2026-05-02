import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class TemplateCreationViewPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const TemplateCreationViewPage({super.key, required this.data});

  Map<String, dynamic> get _template {
    final templateArr = (data['Template'] as List?) ?? const [];
    if (templateArr.isNotEmpty && templateArr.first is Map) {
      return (templateArr.first as Map).map(
        (k, v) => MapEntry(k.toString(), v),
      );
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> get _outputFormats {
    return ((data['OutputFormats'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  List<Map<String, dynamic>> get _approvals {
    return ((data['Approvals'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  String _v(String key, {String fallback = '—'}) {
    final value = _template[key];
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final outputFormatNames = _outputFormats
        .map((e) => e['FormatName']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    final approvalNames = _approvals
        .map((e) => e['Approval_Type']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final selectedOutput = outputFormatNames.isEmpty
        ? ''
        : outputFormatNames.first.toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.text),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/HDFC_Bank_Logo.svg.png',
              height: 36,
              fit: BoxFit.contain,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          const SizedBox(width: 4),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.user?.user;
              final name = user?.name ?? '';
              final empCode = user?.employeeCode ?? '';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          empCode,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF004C8F).withValues(alpha: 0.1),
                        border: Border.all(
                          color: const Color(0xFF004C8F).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF004C8F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Logout',
                      child: InkWell(
                        onTap: () async {
                          final nav = Navigator.of(context);
                          await context.read<AuthProvider>().logout();
                          nav.pushReplacementNamed('/login');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.red.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 16),
              _card(
                title: 'General Information',
                icon: Icons.info_outline_rounded,
                child: Column(
                  children: [
                    _three(
                      _field('Template Name *', _v('TemplateName')),
                      _field('Department *', _v('Department')),
                      _field('Frequency *', _v('Frequency')),
                    ),
                    _three(
                      _field('Priority', _v('Priority')),
                      _field('Normal Volume', _v('NormalVolume')),
                      _field('Peak Volume', _v('PeakVolume')),
                    ),
                    _three(
                      _field('Source Count *', _v('SourceCount')),
                      _field('Source Type *', _v('SourceList')),
                      _field('Number of Outputs *', _v('NumberOfOutputs')),
                    ),
                    _three(
                      _field('Benefit Type', _v('BenefitType')),
                      _field('Benefit Amount (₹)', _v('BenefitAmount')),
                      _field('Benefit in TAT', _v('BenefitInTat')),
                    ),
                    _three(
                      _field('Go Live Date', _v('GoLiveDate')),
                      _field('Deactivate Date', _v('DeactivateDate')),
                      _field('SPOC Person *', _v('SpocPerson')),
                    ),
                    _three(
                      _field('SPOC Manager', _v('SpocManager')),
                      _field('Unit Head', _v('UnitHead')),
                      const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                title: 'Output Format',
                icon: Icons.output_rounded,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _togglePill(
                      label: 'Unimailing',
                      selected: selectedOutput == 'unimailing',
                    ),
                    _togglePill(
                      label: 'User Defined',
                      selected:
                          selectedOutput == 'user defined' ||
                          selectedOutput == 'user_defined',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                title: 'Approval List',
                icon: Icons.verified_user_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: approvalNames.isEmpty
                      ? [_tag('—', false)]
                      : approvalNames.map((e) => _tag(e, true)).toList(),
                ),
              ),
              const SizedBox(height: 14),
              _card(
                title: 'Approval File Upload',
                icon: Icons.attach_file_rounded,
                child: Column(
                  children: _approvals.isEmpty
                      ? [_fileRow('—', 'No file')]
                      : _approvals.map((a) {
                          final name =
                              a['Approval_Type']?.toString().trim().isNotEmpty ==
                                  true
                              ? a['Approval_Type'].toString()
                              : 'Approval';
                          final file =
                              a['ApprovalFile']?.toString().trim().isNotEmpty ==
                                  true
                              ? a['ApprovalFile'].toString()
                              : 'No file';
                          return _fileRow(name, file);
                        }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.blue.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.add_circle_outline_rounded,
            color: AppColors.blue,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Template',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              Text(
                'View submitted template data',
                style: TextStyle(fontSize: 12, color: AppColors.textDim),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.blue.withValues(alpha: 0.1),
                ),
                child: Icon(icon, size: 18, color: AppColors.blue),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _three(Widget a, Widget b, Widget c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
          const SizedBox(width: 10),
          Expanded(child: c),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          readOnly: true,
          maxLines: 1,
          style: const TextStyle(fontSize: 13, color: AppColors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _togglePill({required String label, required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: selected
            ? AppColors.blue.withValues(alpha: 0.12)
            : AppColors.surface2,
        border: Border.all(
          color: selected ? AppColors.blue : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: selected ? AppColors.blue : AppColors.textDim,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.blue : AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: selected
            ? const Color(0xFFECFDF3)
            : AppColors.surface2,
        border: Border.all(
          color: selected ? const Color(0xFF10B981) : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? const Color(0xFF059669) : AppColors.textDim,
        ),
      ),
    );
  }

  Widget _fileRow(String approvalName, String fileName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        color: const Color(0xFFECFDF5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approvalName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
