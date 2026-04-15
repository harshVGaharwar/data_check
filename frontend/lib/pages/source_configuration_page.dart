import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/master_data_service.dart';

class SourceConfigurationPage extends StatefulWidget {
  const SourceConfigurationPage({super.key});

  @override
  State<SourceConfigurationPage> createState() =>
      _SourceConfigurationPageState();
}

class _SourceConfigurationPageState extends State<SourceConfigurationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _sourceTypeCtrl = TextEditingController();
  final _itgrcCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _dbVaultCtrl = TextEditingController();

  bool _submitted = false;
  bool _saving = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 10,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _sourceTypeCtrl.dispose();
    _itgrcCtrl.dispose();
    _nameCtrl.dispose();
    _dbVaultCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitted = true);

    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      return;
    }

    final itgrc = int.tryParse(_itgrcCtrl.text.trim()) ?? 0;
    final user = context.read<AuthProvider>().user?.user;
    final createdBy = user?.employeeCode ?? user?.name ?? 'unknown';

    setState(() => _saving = true);

    final service = context.read<MasterDataService>();
    final result = await service.addSourceMaster(
      sourceType: _sourceTypeCtrl.text.trim(),
      appName: '',
      itgrc: itgrc,
      name: _nameCtrl.text.trim(),
      dbVault: _dbVaultCtrl.text.trim(),
      createdBy: createdBy,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isNotEmpty
                ? result.message
                : 'Failed to save. Please try again.',
          ),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.green,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Source Added',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_nameCtrl.text.trim()} has been added successfully.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _resetForm();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Add Another',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _sourceTypeCtrl.clear();
    _itgrcCtrl.clear();
    _nameCtrl.clear();
    _dbVaultCtrl.clear();
    setState(() => _submitted = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          _shakeCtrl.isAnimating
              ? _shakeAnim.value *
                    ((_shakeCtrl.value * 10).toInt().isEven ? 1 : -1)
              : 0,
          0,
        ),
        child: child,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.violet.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.storage_rounded,
                          color: AppColors.violet,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Source Configuration',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              'Register a new data source in the master list',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Form card ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Source Details', Icons.dns_rounded),
                        const SizedBox(height: 16),

                        // Row 1: Source Type + ITGRC
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _field(
                                label: 'Source Type *',
                                hint: 'e.g. DB, File, API, Oracle',
                                controller: _sourceTypeCtrl,
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? 'Source type is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _field(
                                label: 'ITGRC *',
                                hint: 'Enter ITGRC reference number',
                                controller: _itgrcCtrl,

                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  if (v?.trim().isEmpty ?? true) {
                                    return 'ITGRC is required';
                                  }
                                  if (int.tryParse(v!.trim()) == null) {
                                    return 'Must be a number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 2: Name + DB Vault
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _field(
                                label: 'Name *',
                                hint: 'Enter source display name',
                                controller: _nameCtrl,
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? 'Name is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _field(
                                label: 'DB Vault *',
                                hint: 'Enter DB vault identifier',
                                controller: _dbVaultCtrl,
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? 'DB Vault is required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Save button ──
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        _saving ? 'Saving...' : 'Save Source',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.violet,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.violet.withValues(
                          alpha: 0.5,
                        ),
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.violet),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
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
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autovalidateMode: _submitted
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
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
              borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
