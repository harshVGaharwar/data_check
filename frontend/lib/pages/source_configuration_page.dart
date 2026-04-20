import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/master_models.dart';
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

  // Source Type dropdown state
  List<SourceTypeItem> _sourceTypes = [];
  bool _sourceTypesLoading = true;
  SourceTypeItem? _selectedSourceType;
  final _sourceLayerLink = LayerLink();
  final _sourceTriggerKey = GlobalKey();
  OverlayEntry? _sourceOverlayEntry;

  // Text fields
  final _sourceNameCtrl =
      TextEditingController(); // "Source Name" → API key: Name
  final _appNameCtrl =
      TextEditingController(); // "App Name"    → API key: AppName
  final _itgrcCtrl = TextEditingController();
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
    _loadSourceTypes();
  }

  void _loadSourceTypes() async {
    final service = context.read<MasterDataService>();
    final types = await service.getSourceTypes();
    if (mounted) {
      setState(() {
        _sourceTypes = types;
        _sourceTypesLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _closeSourceDropdown();
    _sourceNameCtrl.dispose();
    _appNameCtrl.dispose();
    _itgrcCtrl.dispose();
    _dbVaultCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Overlay helpers ────────────────────────────────────────────────────────

  void _openSourceDropdown() {
    _closeSourceDropdown();
    final renderBox =
        _sourceTriggerKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 280.0;

    _sourceOverlayEntry = OverlayEntry(
      builder: (_) => _SourceTypeDropdownOverlay(
        layerLink: _sourceLayerLink,
        items: _sourceTypes,
        selected: _selectedSourceType,
        dropdownWidth: width,
        onDismiss: _closeSourceDropdown,
        onSelect: (item) {
          setState(() => _selectedSourceType = item);
          _closeSourceDropdown();
        },
      ),
    );
    Overlay.of(context).insert(_sourceOverlayEntry!);
    setState(() {});
  }

  void _closeSourceDropdown() {
    _sourceOverlayEntry?.remove();
    _sourceOverlayEntry = null;
    if (mounted) setState(() {});
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _submitted = true);

    if (_selectedSourceType == null) {
      _shakeCtrl.forward(from: 0);
      return;
    }

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
      sourceTypeId: _selectedSourceType!.id.toString(),
      appName: _appNameCtrl.text.trim(),
      itgrc: itgrc,
      name: _sourceNameCtrl.text.trim(),
      dbVault: _dbVaultCtrl.text.trim(),
      createdBy: createdBy,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      _showSuccessDialog(reqId: result.reqId);
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

  void _showSuccessDialog({required int reqId}) {
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
              'Source Added Successfully',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_sourceNameCtrl.text.trim()} has been added successfully.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 12),
            // ── API response card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.green.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.green.withValues(alpha: 0.12),
                        ),
                        child: const Text(
                          'Success',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (reqId > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Request ID',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '#$reqId',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
    _selectedSourceType = null;
    _sourceNameCtrl.clear();
    _appNameCtrl.clear();
    _itgrcCtrl.clear();
    _dbVaultCtrl.clear();
    setState(() => _submitted = false);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
                        color: AppColors.blue.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.storage_rounded,
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

                      // Row 1: Source Type dropdown + ITGRC
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _sourceTypeDropdownField()),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _field(
                              label: 'ITGRC *',
                              hint: 'Enter ITGRC reference number',
                              controller: _itgrcCtrl,

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

                      // Row 2: Source Name + App Name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              label: 'Source Name *',
                              hint: 'Enter source name',
                              controller: _sourceNameCtrl,
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? 'Source Name is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _field(
                              label: 'App Name *',
                              hint: 'Enter application name',
                              controller: _appNameCtrl,
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? 'App Name is required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 3: DB Vault
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const Expanded(child: SizedBox()),
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
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.blue.withValues(
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
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _sourceTypeDropdownField() {
    final isOpen = _sourceOverlayEntry != null;
    final hasError = _submitted && _selectedSourceType == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Source Type *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 6),
        CompositedTransformTarget(
          link: _sourceLayerLink,
          child: InkWell(
            key: _sourceTriggerKey,
            onTap: _sourceTypesLoading
                ? null
                : () => isOpen ? _closeSourceDropdown() : _openSourceDropdown(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOpen
                      ? AppColors.blue
                      : hasError
                      ? AppColors.red
                      : AppColors.border,
                  width: isOpen || hasError ? 1.5 : 1,
                ),
                color: AppColors.surface2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _sourceTypesLoading
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textDim,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _selectedSourceType?.sourceName ??
                                'Select source type',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedSourceType != null
                                  ? AppColors.text
                                  : AppColors.textMuted,
                            ),
                          ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: const [
                Icon(Icons.error_outline, size: 13, color: AppColors.red),
                SizedBox(width: 4),
                Text(
                  'Source Type is required',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
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
              borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
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

// ── Single-select searchable overlay ─────────────────────────────────────────

class _SourceTypeDropdownOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final List<SourceTypeItem> items;
  final SourceTypeItem? selected;
  final double dropdownWidth;
  final VoidCallback onDismiss;
  final void Function(SourceTypeItem) onSelect;

  const _SourceTypeDropdownOverlay({
    required this.layerLink,
    required this.items,
    required this.selected,
    required this.dropdownWidth,
    required this.onDismiss,
    required this.onSelect,
  });

  @override
  State<_SourceTypeDropdownOverlay> createState() =>
      _SourceTypeDropdownOverlayState();
}

class _SourceTypeDropdownOverlayState
    extends State<_SourceTypeDropdownOverlay> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SourceTypeItem> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items
        .where(
          (i) =>
              i.sourceName.toLowerCase().contains(q) ||
              i.sourceValue.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tap outside to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        // Dropdown card anchored below trigger
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 46),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
              child: Container(
                width: widget.dropdownWidth,
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search source types...',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 16,
                            color: AppColors.textDim,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.violet,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    // Item list
                    Flexible(
                      child: _filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No results found',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDim,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                              itemBuilder: (_, i) {
                                final item = _filtered[i];
                                final isSel = widget.selected?.id == item.id;
                                return InkWell(
                                  onTap: () => widget.onSelect(item),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSel
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          size: 18,
                                          color: isSel
                                              ? AppColors.violet
                                              : AppColors.textDim,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.sourceName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isSel
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                  color: isSel
                                                      ? AppColors.violet
                                                      : AppColors.text,
                                                ),
                                              ),
                                              if (item.sourceValue.isNotEmpty)
                                                Text(
                                                  item.sourceValue,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textDim,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
