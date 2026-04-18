import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/master_models.dart';
import '../models/template_info.dart';
import '../providers/auth_provider.dart';
import '../services/master_data_service.dart';

class ManualUploadPage extends StatefulWidget {
  const ManualUploadPage({super.key});

  @override
  State<ManualUploadPage> createState() => _ManualUploadPageState();
}

class _ManualUploadPageState extends State<ManualUploadPage> {
  Map<String, int> _deptMap = {};
  bool _deptLoading = true;

  List<ManualTemplateInfo> _templates = [];
  bool _templateLoading = false;

  String? _selectedDept;
  ManualTemplateInfo? _selectedTemplate;

  List<SourceListItem> _sources = [];
  bool _sourceLoading = false;

  // Per-slot file map keyed by slot index (0-based, up to manualCount)
  final Map<int, PlatformFile> _slotFiles = {};

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final auth = context.read<AuthProvider>();
    if (!auth.initialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return mounted && !context.read<AuthProvider>().initialized;
      });
    }
    if (!mounted) return;
    final service = context.read<MasterDataService>();
    final map = await service.getDepartmentMap();
    if (!mounted) return;
    setState(() {
      _deptMap = map;
      _deptLoading = false;
    });
  }

  Future<void> _onDeptSelected(String dept) async {
    setState(() {
      _selectedDept = dept;
      _selectedTemplate = null;
      _templates = [];
      _templateLoading = true;
      _sources = [];
      _slotFiles.clear();
    });

    final deptId = _deptMap[dept];
    if (deptId == null) {
      setState(() => _templateLoading = false);
      return;
    }

    final service = context.read<MasterDataService>();
    final templates = await service.getManualTemplatesByDept(deptId);
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _templateLoading = false;
    });
  }

  Future<void> _onTemplateSelected(ManualTemplateInfo template) async {
    final deptId = _deptMap[_selectedDept];
    setState(() {
      _selectedTemplate = template;
      _sources = [];
      _slotFiles.clear();
      _sourceLoading = true;
    });

    if (deptId != null) {
      final service = context.read<MasterDataService>();
      final sources = await service.getSourceList(
        deptId: deptId,
        templateId: template.templateId,
      );
      if (!mounted) return;
      setState(() => _sources = sources);
    }
    if (mounted) setState(() => _sourceLoading = false);
  }

  Future<void> _pickFileForSlot(int slotIndex) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls', 'txt', 'json'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _slotFiles[slotIndex] = result.files.first;
    });
  }

  void _removeFileForSlot(int slotIndex) {
    setState(() => _slotFiles.remove(slotIndex));
  }

  Future<void> _save() async {
    if (_selectedDept == null) {
      _showSnack('Please select a department.', isError: true);
      return;
    }
    if (_selectedTemplate == null) {
      _showSnack('Please select a template.', isError: true);
      return;
    }
    if ((_selectedTemplate?.manualCount ?? 0) == 0) {
      _showSnack('No manual uploads required for this template.', isError: true);
      return;
    }
    if (_slotFiles.isEmpty) {
      _showSnack('Please attach at least one file.', isError: true);
      return;
    }

    final deptId = _deptMap[_selectedDept!]!;
    final templateId = _selectedTemplate!.templateId;
    final createdBy = context.read<AuthProvider>().user?.user.employeeCode ?? '';

    final entries = _slotFiles.entries.map((e) {
      final sourceId = e.key < _sources.length ? _sources[e.key].id : e.key;
      return {
        'Template_id': '$templateId',
        'department_id': '$deptId',
        'source_id': '$sourceId',
        'filename': e.value.name,
        'createdBy': createdBy,
      };
    }).toList();

    setState(() => _saving = true);
    final result = await context.read<MasterDataService>().uploadManualData(entries: entries);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      _showSuccessDialog(reqId: result.reqId);
    } else {
      _showSnack(result.message.isNotEmpty ? result.message : 'Upload failed.', isError: true);
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
              child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 38),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload Successful',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Text(
              '${_slotFiles.length} file${_slotFiles.length == 1 ? '' : 's'} uploaded for ${_selectedTemplate?.templateName ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.green.withValues(alpha: 0.06),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.green.withValues(alpha: 0.12),
                        ),
                        child: const Text('Success', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (reqId > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Request ID', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text('#$reqId', style: const TextStyle(color: AppColors.green, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _resetForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedDept = null;
      _selectedTemplate = null;
      _templates = [];
      _sources = [];
      _slotFiles.clear();
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSelectionCard(),
              if (_selectedTemplate != null) ...[
                const SizedBox(height: 16),
                _buildSourcesCard(),
              ],
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.blue.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.upload_file_rounded,
            color: AppColors.blue,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Manual Upload',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Select department & template, then upload files per source',
              style: TextStyle(fontSize: 12, color: AppColors.textDim),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('SELECTION', Icons.tune_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _labelledDropdown(
                  label: 'Department',
                  hint: '— Select Department —',
                  value: _selectedDept,
                  items: _deptMap.keys.toList(),
                  loading: _deptLoading,
                  onChanged: (v) {
                    if (v != null) _onDeptSelected(v);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _labelledDropdown(
                  label: 'Template',
                  hint: _selectedDept == null
                      ? '— Select Department first —'
                      : '— Select Template —',
                  value: _selectedTemplate?.templateName,
                  items: _templates.map((t) => t.templateName).toList(),
                  loading: _templateLoading,
                  enabled: _selectedDept != null && !_templateLoading,
                  onChanged: (v) {
                    if (v == null) return;
                    _onTemplateSelected(
                      _templates.firstWhere((t) => t.templateName == v),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesCard() {
    final count = _selectedTemplate?.manualCount ?? 0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle('UPLOAD FILES', Icons.attach_file_rounded),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.blue.withValues(alpha: 0.1),
                ),
                child: Text(
                  '$count file${count == 1 ? '' : 's'} required',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_sourceLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            LayoutBuilder(
              builder: (ctx, constraints) {
                const gap = 12.0;
                final cardW = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: List.generate(
                    count,
                    (i) => SizedBox(width: cardW, child: _buildSlotCard(i)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(int index) {
    final file = _slotFiles[index];
    final sName = index < _sources.length
        ? _sources[index].name
        : 'File ${index + 1}';
    final hasFile = file != null;
    final ext = hasFile ? (file.extension ?? '').toLowerCase() : '';
    final extColor = _extColor(ext);
    final sizeLabel = hasFile
        ? (file.size < 1024
              ? '${file.size} B'
              : file.size < 1024 * 1024
              ? '${(file.size / 1024).toStringAsFixed(1)} KB'
              : '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB')
        : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFile
              ? AppColors.blue.withValues(alpha: 0.5)
              : AppColors.border2,
          width: hasFile ? 1.5 : 1,
        ),
        color: hasFile
            ? AppColors.blue.withValues(alpha: 0.03)
            : AppColors.surface,
        boxShadow: hasFile
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasFile
                        ? AppColors.blue.withValues(alpha: 0.12)
                        : AppColors.bg,
                    border: Border.all(
                      color: hasFile
                          ? AppColors.blue.withValues(alpha: 0.3)
                          : AppColors.border2,
                    ),
                  ),
                  child: Center(
                    child: hasFile
                        ? const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: AppColors.blue,
                          )
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDim,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: hasFile ? AppColors.text : AppColors.textDim,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        hasFile ? 'File attached' : 'No file uploaded',
                        style: TextStyle(
                          fontSize: 10,
                          color: hasFile ? AppColors.blue : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasFile)
                  GestureDetector(
                    onTap: () => _removeFileForSlot(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.red.withValues(alpha: 0.08),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: AppColors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Divider ──
          Divider(
            height: 1,
            color: hasFile
                ? AppColors.blue.withValues(alpha: 0.12)
                : AppColors.border,
          ),
          // ── Upload zone / File info ──
          if (hasFile)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: extColor.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text(
                        ext.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: extColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          sizeLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _pickFileForSlot(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border2),
                        color: AppColors.bg,
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => _pickFileForSlot(index),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border2,
                    style: BorderStyle.solid,
                  ),
                  color: AppColors.bg,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 24,
                      color: AppColors.blue.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Click to upload file',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'CSV, XLSX, XLS, TXT, JSON',
                      style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _extColor(String ext) {
    switch (ext) {
      case 'csv':
        return AppColors.green;
      case 'xlsx':
      case 'xls':
        return AppColors.blue;
      case 'json':
        return AppColors.amber;
      default:
        return AppColors.slate;
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.upload, size: 18),
        label: Text(
          _saving ? 'Uploading...' : 'Save',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.blue.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.blue),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTextStyles.sectionLabel.copyWith(color: AppColors.blue),
        ),
      ],
    );
  }

  Widget _labelledDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool loading = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        loading
            ? _loadingField()
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: enabled ? AppColors.border2 : AppColors.border,
                  ),
                  color: enabled ? AppColors.surface : AppColors.bg,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: items.contains(value) ? value : null,
                    hint: Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(fontSize: 13, color: AppColors.text),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: enabled ? AppColors.textDim : AppColors.textMuted,
                    ),
                    items: items
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: enabled ? onChanged : null,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _loadingField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        color: AppColors.bg,
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textDim,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Loading...',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
