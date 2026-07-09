import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/core/utils/functions.dart';
import 'package:vizualizer/data/models/login_response.dart';
import 'package:vizualizer/data/models/template_request.dart';
import 'package:vizualizer/data/services/storage_service.dart';
import 'package:vizualizer/presentation/providers/auth_provider.dart';
import 'package:vizualizer/presentation/providers/template_provider.dart';
import 'package:vizualizer/data/models/master_models.dart';
import 'package:vizualizer/data/services/master_data_service.dart';

class TemplateCreationPage extends StatefulWidget {
  final VoidCallback? onClose;

  const TemplateCreationPage({super.key, this.onClose});

  @override
  State<TemplateCreationPage> createState() => _TemplateCreationPageState();
}

class _TemplateCreationPageState extends State<TemplateCreationPage>
    with TickerProviderStateMixin {
  final _model = TemplateRequest();
  final _scrollCtrl = ScrollController();
  bool _submitted = false;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _normalVolCtrl = TextEditingController();
  final _peakVolCtrl = TextEditingController();
  final _benefitAmtCtrl = TextEditingController();
  final _tatCtrl = TextEditingController();
  final _spocCtrl = TextEditingController();
  final _spocMgrCtrl = TextEditingController();
  final _unitHeadCtrl = TextEditingController();

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  String? selectedFormat;

  List<DepartmentItem> _departments = [];
  bool _deptLoading = true;
  bool _deptError = false;
  List<ApprovalItem> _approvalOptions = [];
  bool _approvalLoading = true;
  bool _approvalError = false;
  List<SourceMasterItem> _sourceMasterList = [];
  List<FrequencyListItem> _frequencyList = [];
  bool _sourceMasterLoading = true;
  bool _sourceMasterError = false;
  bool _frequencyListLoading = true;
  bool _frequencyListError = false;

  // Source-type multi-select overlay
  final _sourceLayerLink = LayerLink();
  final _sourceTriggerKey = GlobalKey();
  OverlayEntry? _sourceOverlayEntry;

  // Benefit-type multi-select overlay
  List<String> _selectedBenefitTypes = [];
  final _benefitLayerLink = LayerLink();
  final _benefitTriggerKey = GlobalKey();
  OverlayEntry? _benefitOverlayEntry;
  // static const _frequencies = [
  //   'Daily',
  //   'Weekly',
  //   'Bi-Weekly',
  //   'Monthly',
  //   'Quarterly',
  //   'Yearly',
  //   'On-Demand',
  // ];
  static const _benefitTypes = [
    'Cost Saving',
    'Revenue Generation',
    'Efficiency Improvement',
    'Risk Reduction',
    'Compliance',
    'Other',
  ];
  static const _priorities = ['Low', 'Medium', 'High', 'Critical'];
  static const _outputFormats = [
    'Unimailing',
    //  'User Defined'
  ];
  static const _sourceCountOptions = [
    // '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];
  static const _numOutputOptions = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];
  // static const _templateTypeOptions = [
  //   '1 - Static'
  //   // , '2 - Dynamic'
  // ];
  List<String> _templateTypeOptions = [];
  TemplateType? _selectedTemplateType;
  List<TemplateType> _templateTypeList = [];

  // Per-approval file uploads: { "Unit Head": "approval_uh.pdf", ... }
  final Map<String, String> _approvalFiles = {};
  // Raw bytes for each approval file
  final Map<String, List<int>> _approvalFileBytes = {};

  @override
  void initState() {
    super.initState();
    print("PAGE INIT: ${DateTime.now()}");
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 12,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeCtrl);
    _loadDepartments();
    _loadApprovals();
    _loadSourceMasterList();
    _loadFrequencyList();
    _loadTemplateTypes();
  }

  Future<void> _waitForAuth() async {
    final auth = context.read<AuthProvider>();
    int attempts = 0;

    while (!auth.initialized && attempts < 40) {
      // max 2 seconds
      await Future.delayed(Duration(milliseconds: 50));
      attempts++;
    }
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _deptLoading = true;
      _deptError = false;
    });
    // await _waitForAuth();
    if (!mounted) return;
    final service = context.read<MasterDataService>();
    final depts = await service.getDepartments();
    if (mounted) {
      setState(() {
        _departments = depts;
        _deptLoading = false;
        _deptError = depts.isEmpty;
      });
    }
  }

  Future<void> _loadApprovals() async {
    setState(() {
      _approvalLoading = true;
      _approvalError = false;
    });
    await _waitForAuth();
    if (!mounted) return;
    final service = context.read<MasterDataService>();
    final approvals = await service.getApprovalList();
    if (mounted) {
      setState(() {
        _approvalOptions = approvals;
        _approvalLoading = false;
        _model.approvals = approvals.map((a) => a.name).toList();
        _approvalError = approvals.isEmpty;
      });
    }
  }

  Future<void> _loadSourceMasterList() async {
    setState(() {
      _sourceMasterLoading = true;
      _sourceMasterError = false;
    });
    await _waitForAuth();
    if (!mounted) return;
    final service = context.read<MasterDataService>();
    final list = await service.getSourceMasterList();
    if (mounted) {
      setState(() {
        _sourceMasterList = list;
        _sourceMasterLoading = false;
        _sourceMasterError = list.isEmpty;
      });
    }
  }

  Future<void> _loadFrequencyList() async {
    setState(() {
      _frequencyListLoading = true;
      _frequencyListError = false;
    });
    await _waitForAuth();
    if (!mounted) return;
    final service = context.read<MasterDataService>();
    final frequency = await service.getFrequencyList();
    if (mounted) {
      setState(() {
        _frequencyList = frequency;
        _frequencyListLoading = false;
        _frequencyListError = frequency.isEmpty;
      });
    }
  }

  void _loadTemplateTypes() async {
    final session = await StorageService().loadSession();
    final types = session?.user.templateType ?? [];

    setState(() {
      _templateTypeList = types; // ✅ store objects
      _templateTypeOptions = types
          .map((t) => t.name)
          .toList(); // ✅ dropdown sees names only
    });
  }

  @override
  void dispose() {
    _closeSourceDropdown();
    _closeBenefitDropdown();
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _normalVolCtrl.dispose();
    _peakVolCtrl.dispose();
    _benefitAmtCtrl.dispose();
    _tatCtrl.dispose();
    _spocCtrl.dispose();
    _spocMgrCtrl.dispose();
    _unitHeadCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _openSourceDropdown() {
    _closeSourceDropdown();
    final renderBox =
        _sourceTriggerKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 280.0;
    final initialSelected = Set<int>.from(
      _model.sourceList.map((m) => m['id'] as int),
    );

    _sourceOverlayEntry = OverlayEntry(
      builder: (_) => _SourceMultiSelectOverlay(
        layerLink: _sourceLayerLink,
        items: _sourceMasterList,
        initialSelected: initialSelected,
        dropdownWidth: width,
        onDismiss: _closeSourceDropdown,
        onDone: (selected) {
          setState(() {
            final filterd = _sourceMasterList
                .where((s) => selected.contains(s.id))
                .toList();
            _model.sourceList = filterd.map((s) => s.toJson()).toList();
            _model.sourceListName = filterd.map((s) => s.name).join(',');
            if (!_model.isDynamic) {
              _model.templateType = '1 - Static';
              selectedFormat = null;
              _model.outputFormats = [];
              _model.numberOfOutputs = 0;
              _model.dynamicOutputs = [];
            }
          });
          _closeSourceDropdown();
        },
      ),
    );
    Overlay.of(context).insert(_sourceOverlayEntry!);
    setState(() {}); // refresh arrow rotation
  }

  void _closeSourceDropdown() {
    _sourceOverlayEntry?.remove();
    _sourceOverlayEntry = null;
    if (mounted) setState(() {});
  }

  void _openBenefitDropdown() {
    _closeBenefitDropdown();
    final renderBox =
        _benefitTriggerKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 280.0;

    _benefitOverlayEntry = OverlayEntry(
      builder: (_) => _BenefitMultiSelectOverlay(
        layerLink: _benefitLayerLink,
        items: _benefitTypes,
        initialSelected: Set<String>.from(_selectedBenefitTypes),
        dropdownWidth: width,
        onDismiss: _closeBenefitDropdown,
        onDone: (selected) {
          setState(() {
            _selectedBenefitTypes = _benefitTypes
                .where((t) => selected.contains(t))
                .toList();
          });
          _closeBenefitDropdown();
        },
      ),
    );
    Overlay.of(context).insert(_benefitOverlayEntry!);
    setState(() {});
  }

  void _closeBenefitDropdown() {
    _benefitOverlayEntry?.remove();
    _benefitOverlayEntry = null;
    if (mounted) setState(() {});
  }

  void _syncModel() {
    _model.templateName = _nameCtrl.text.trim();
    _model.normalVolume = int.tryParse(_normalVolCtrl.text) ?? 0;
    _model.peakVolume = int.tryParse(_peakVolCtrl.text) ?? 0;
    _model.benefitType = _selectedBenefitTypes.join(',');
    _model.benefitAmount = double.tryParse(_benefitAmtCtrl.text) ?? 0;
    _model.benefitInTAT = _tatCtrl.text.trim();
    _model.spocPerson = _spocCtrl.text.trim();
    _model.spocManager = _spocMgrCtrl.text.trim();
    _model.unitHead = _unitHeadCtrl.text.trim();
    _model.approvalFiles = Map<String, String>.from(_approvalFiles);
    _model.createdBy =
        context.read<AuthProvider>().user?.user.employeeCode ?? '';
  }

  bool get _allApprovalFilesUploaded =>
      _model.approvals.isNotEmpty &&
      _model.approvals.every((a) => _approvalFiles.containsKey(a));

  void _save() async {
    if (_saving) return;
    _syncModel();
    setState(() => _submitted = true);

    final List<String> missingSections = [
      if (!_model.isGeneralInfoValid) 'General Info',
      if (!_model.isOutputFormatValid) 'Output Format',
      if (!_model.isDynamicOutputsValid) 'Dynamic Outputs',
      if (!_model.isApprovalValid) 'Approvals (select type)',
      if (_model.isApprovalValid && !_allApprovalFilesUploaded)
        'Approvals (upload files)',

      // ✅ Final correct rule
      if (_model.frequencyIs3 && !_model.hasMandatorySourceId1)
        'Please select one source type as manual as you have selected frequency on-demand',
    ];

    if (missingSections.isNotEmpty) {
      _shakeCtrl.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incomplete: ${missingSections.join(' · ')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );

      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      return;
    }

    // ✅ Continue saving
    setState(() => _saving = true);

    final provider = context.read<TemplateProvider>();
    final success = await provider.saveTemplate(
      _model,
      fileBytes: _approvalFileBytes,
      fileNames: _approvalFiles,
    );

    if (mounted) setState(() => _saving = false);

    if (mounted && success) {
      final reqId = context.read<TemplateProvider>().reqId;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => SuccessDialog(
          reqId: reqId,
          onDone: () {
            Navigator.of(ctx).pop();
            _resetForm();
          },
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Save failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    // ✅ Keep selected approvals ONLY
    final oldApprovals = List<String>.from(_model.approvals);

    _model.reset(); // this clears everything

    // ✅ Restore approvals selection
    _model.approvals = oldApprovals;

    // ✅ Clear uploaded file names + file bytes
    _approvalFiles.clear();
    _approvalFileBytes.clear();

    // ✅ Clear all text fields
    for (final c in [
      _nameCtrl,
      _normalVolCtrl,
      _peakVolCtrl,
      _benefitAmtCtrl,
      _tatCtrl,
      _spocCtrl,
      _spocMgrCtrl,
      _unitHeadCtrl,
    ]) {
      c.clear();
    }

    selectedFormat = null;

    setState(() {
      _selectedBenefitTypes = [];
      _submitted = false;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) => Transform.translate(
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
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF004C8F).withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF004C8F),
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
                            'Fill in all required sections to create a template',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // A) General Information
                _sectionCard(
                  title: 'General Information',
                  icon: Icons.info_outline,
                  hasError: _submitted && !_model.isGeneralInfoValid,
                  child: Column(
                    children: [
                      _row([
                        _tf(
                          'Template Name *',
                          _nameCtrl,
                          'Enter template name',
                        ),
                        _deptLoading
                            ? _loadingField('Department *')
                            : _deptError
                            ? _errorField('Department *', _loadDepartments)
                            : SearchableStringDropdown(
                                label: 'Department *',
                                items: _departments.map((d) => d.name).toList(),
                                value:
                                    _departments
                                        .where(
                                          (d) =>
                                              d.id.toString() ==
                                              _model.department,
                                        )
                                        .firstOrNull
                                        ?.name ??
                                    '',
                                onChanged: (v) {
                                  final dept = _departments.firstWhere(
                                    (d) => d.name == v,
                                  );
                                  setState(() {
                                    _model.department = dept.id.toString();
                                    _model.departmentName = dept.name;
                                  });
                                },
                              ),
                        _frequencyListLoading
                            ? _loadingField('Frequency *')
                            : _frequencyListError
                            ? _errorField('Frequency *', _loadFrequencyList)
                            : SearchableStringDropdown(
                                label: 'Frequency *',
                                items: _frequencyList
                                    .map((f) => f.name)
                                    .toList(),
                                value:
                                    _frequencyList
                                        .where(
                                          (f) =>
                                              f.id.toString() ==
                                              _model.frequency,
                                        )
                                        .firstOrNull
                                        ?.name ??
                                    '',
                                onChanged: (v) {
                                  final frequency = _frequencyList.firstWhere(
                                    (f) => f.name == v,
                                  );
                                  setState(() {
                                    _model.frequency = frequency.id.toString();
                                    _model.frequencyName = frequency.name;
                                  });
                                },
                              ),
                      ]),
                      const SizedBox(height: 10),
                      _row([
                        SearchableStringDropdown(
                          label: 'Priority',
                          items: _priorities,
                          value: _model.priority,
                          onChanged: (v) => setState(() => _model.priority = v),
                        ),
                        _tf('Normal Volume', _normalVolCtrl, '0', num: true),
                        _tf('Peak Volume', _peakVolCtrl, '0', num: true),
                      ]),
                      const SizedBox(height: 10),
                      _row([
                        _benefitTypeMultiSelect(),
                        _tf(
                          'Benefit Amount (₹)',
                          _benefitAmtCtrl,
                          '0',
                          num: true,
                        ),
                        _tf(
                          'Benefit in TAT',
                          _tatCtrl,
                          'e.g. 2 hours',
                          num: true,
                        ),
                      ]),
                      const SizedBox(height: 10),
                      _row([
                        _dp(
                          'Go Live Date',
                          _model.goLiveDate,
                          (v) => setState(() => _model.goLiveDate = v),
                          firstDate: DateTime.now(),
                        ),
                        _dp(
                          'Deactivate Date',
                          _model.deactivateDate,
                          (v) => setState(() => _model.deactivateDate = v),
                          firstDate: _model.goLiveDate.isNotEmpty
                              ? DateTime.parse(_model.goLiveDate)
                              : null,
                          enabled: _model.goLiveDate.isNotEmpty,
                        ),
                        _tf('SPOC Person *', _spocCtrl, 'Enter name'),
                      ]),
                      const SizedBox(height: 10),
                      _row([
                        _tf('SPOC Manager', _spocMgrCtrl, 'Enter name'),
                        _tf('Unit Head', _unitHeadCtrl, 'Enter name'),
                        const SizedBox(),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // B) Output Format
                _sectionCard(
                  title: 'Output Format *',
                  icon: Icons.output_rounded,
                  hasError: _submitted && !_model.isOutputFormatValid,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Template Type + Number of Outputs ──
                      _row([
                        SearchableStringDropdown(
                          label: 'Template Type *',
                          items: _templateTypeOptions,
                          value: _model.templateTypeName,
                          // onChanged: (v) => setState(() {
                          //   _model.templateType = v;
                          //   if (v == '2 - Dynamic') {
                          //     selectedFormat = 'Unimailing';
                          //     _model.outputFormats = ['Unimailing'];
                          //   } else {
                          //     selectedFormat = null;
                          //     _model.outputFormats = [];
                          //     _model.numberOfOutputs = 0;
                          //   }
                          // }),
                          // onChanged: (v) => setState(() {
                          //   _model.templateType = v;

                          //   if (v == '2 - Dynamic') {
                          //     selectedFormat = 'Unimailing';
                          //     _model.outputFormats = ['Unimailing'];
                          //     // Clear General Info source fields
                          //     _model.sourceCount = 0;
                          //     _model.sourceList = [];
                          //     _model.sourceListName = '';
                          //   } else {
                          //     selectedFormat = null;
                          //     _model.outputFormats = [];
                          //     _model.numberOfOutputs = 0;
                          //     _model.dynamicOutputs = [];
                          //   }
                          // }),
                          onChanged: (v) {
                            final selected = _templateTypeList.firstWhere(
                              (t) => t.name == v,
                            );

                            setState(() {
                              _selectedTemplateType = selected;
                              _model.selectedTemplateType = selected;
                              _model.templateType = selected.id.toString();
                              _model.templateTypeName = selected.name;
                            });

                            if (selected.id == 3) {
                              // ✅ Dynamic
                              selectedFormat = 'Unimailing';
                              _model.outputFormats = ['Unimailing'];
                              _model.sourceCount = 0;
                              _model.sourceList = [];
                              _model.sourceListName = '';
                            } else if (selected.id == 2) {
                              // ✅ Static
                              selectedFormat = null;
                              _model.outputFormats = [];
                              _model.numberOfOutputs = 0;
                              _model.dynamicOutputs = [];
                            }
                          },
                        ),
                        if (_selectedTemplateType?.id == 3)
                          SearchableStringDropdown(
                            label: 'Dynamic Count *',
                            items: _numOutputOptions,
                            value: _model.numberOfOutputs > 0
                                ? '${_model.numberOfOutputs}'
                                : '',
                            onChanged: (v) => setState(() {
                              _model.numberOfOutputs = int.tryParse(v) ?? 0;

                              _model.dynamicOutputs = List.generate(
                                _model.numberOfOutputs,
                                (_) => DynamicOutputModel(),
                              );
                            }),
                          )
                        else
                          const SizedBox(),
                        const SizedBox(),
                      ]),
                      if (_submitted &&
                          (_model.templateType.isEmpty ||
                              (_selectedTemplateType?.id == 3 &&
                                  _model.numberOfOutputs == 0)))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_model.templateType.isEmpty)
                                _err('Please select a template type'),
                              if (_selectedTemplateType?.id == 3 &&
                                  _model.numberOfOutputs == 0)
                                _err('Please select number of outputs'),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.border),

                      if (_selectedTemplateType?.id == 2) ...[
                        const SizedBox(height: 16),
                        _row([
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SearchableStringDropdown(
                                label: 'Source Count *',
                                items: _sourceCountOptions,
                                value: _model.sourceCount > 0
                                    ? '${_model.sourceCount}'
                                    : '',
                                onChanged: (v) => setState(() {
                                  _model.sourceCount = int.tryParse(v) ?? 0;
                                }),
                              ),
                              if (_submitted && _model.sourceCount == 0)
                                _err('Source Count is required'),
                            ],
                          ),
                          _sourceMasterMultiSelect(),
                          const SizedBox(),
                        ]),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.border),
                      ],
                      if (_selectedTemplateType?.id == 3 &&
                          _model.dynamicOutputs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        // Static 1 — always first
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Static 1',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _row([
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SearchableStringDropdown(
                                      label: 'Source Count *',
                                      items: _sourceCountOptions,
                                      value: _model.sourceCount > 0
                                          ? '${_model.sourceCount}'
                                          : '',
                                      onChanged: (v) => setState(
                                        () => _model.sourceCount =
                                            int.tryParse(v) ?? 0,
                                      ),
                                    ),
                                    if (_submitted && _model.sourceCount == 0)
                                      _err('Source Count is required'),
                                  ],
                                ),
                                _sourceMasterMultiSelect(),
                                const SizedBox(),
                              ]),
                            ],
                          ),
                        ),
                        // Dynamic 1..N
                        Column(
                          children: List.generate(
                            _model.dynamicOutputs.length,
                            (index) {
                              final item = _model.dynamicOutputs[index];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dynamic ${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _row([
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SearchableStringDropdown(
                                            label: 'Source Count *',
                                            items: _sourceCountOptions,
                                            value: item.sourceCount > 0
                                                ? '${item.sourceCount}'
                                                : '',
                                            onChanged: (v) {
                                              setState(() {
                                                item.sourceCount =
                                                    int.tryParse(v) ?? 0;
                                              });
                                            },
                                          ),
                                          if (_submitted &&
                                              item.sourceCount == 0)
                                            _err('Source Count is required'),
                                        ],
                                      ),
                                      DynamicSourceTypeWidget(
                                        sourceMasterList: _sourceMasterList,
                                        selectedList: item.sourceList,
                                        submitted: _submitted,
                                        onChanged: (list) {
                                          setState(() {
                                            item.sourceList = list;
                                          });
                                        },
                                      ),
                                      const SizedBox(),
                                    ]),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Format chips ──
                      if (_model.templateType.isEmpty)
                        const Text(
                          'Select a template type above to choose output format',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        )
                      else ...[
                        const Text(
                          'Select at least one output format',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDim,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedTemplateType?.id == 3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(
                                0xFF004C8F,
                              ).withValues(alpha: 0.08),
                              border: Border.all(
                                color: const Color(0xFF004C8F),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.radio_button_checked,
                                  size: 18,
                                  color: Color(0xFF004C8F),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Unimailing',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF004C8F),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 13,
                                  color: const Color(
                                    0xFF004C8F,
                                  ).withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _outputFormats.map((f) {
                              final sel = selectedFormat == f;
                              return InkWell(
                                onTap: () => setState(() {
                                  selectedFormat = f;
                                  _model.outputFormats = [f];
                                }),
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: sel
                                        ? const Color(
                                            0xFF004C8F,
                                          ).withValues(alpha: 0.08)
                                        : AppColors.surface2,
                                    border: Border.all(
                                      color: sel
                                          ? const Color(0xFF004C8F)
                                          : AppColors.border,
                                      width: sel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        sel
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 18,
                                        color: sel
                                            ? const Color(0xFF004C8F)
                                            : AppColors.textDim,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        f,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w300,
                                          color: sel
                                              ? const Color(0xFF004C8F)
                                              : AppColors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        if (_submitted && _model.outputFormats.isEmpty)
                          _err('Please select at least one output format'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // C) Approval List
                _sectionCard(
                  title: 'Approval List *',
                  icon: Icons.approval_outlined,
                  hasError: _submitted && !_model.isApprovalValid,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const Text(
                      //   'Upload required approvals',
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     color: AppColors.textDim,
                      //   ),
                      // ),
                      // const SizedBox(height: 12),
                      if (_approvalLoading)
                        const Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textDim,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Loading approvals...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        )
                      else if (_approvalError)
                        GestureDetector(
                          onTap: _loadApprovals,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 14,
                                color: AppColors.red,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Failed to load. Tap to retry',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.red,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: AppColors.red,
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _approvalOptions.map((a) {
                            final sel = _model.approvals.contains(a.name);
                            return InkWell(
                              // onTap: () => setState(() {
                              //   if (sel) {
                              //     _model.approvals.remove(a.name);
                              //     _approvalFiles.remove(a.name);
                              //     _approvalFileBytes.remove(a.name);
                              //   } else {
                              //     _model.approvals.add(a.name);
                              //   }
                              // }),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: sel
                                      ? AppColors.green.withValues(alpha: 0.08)
                                      : AppColors.surface2,
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.green
                                        : AppColors.border,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      sel
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 16,
                                      color: sel
                                          ? AppColors.green
                                          : AppColors.textDim,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      a.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: sel
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: sel
                                            ? AppColors.green
                                            : AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      if (_submitted && !_model.isApprovalValid)
                        _err('Please select at least one approval'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // E) Approval File Upload (per approval)
                if (_model.approvals.isNotEmpty)
                  _sectionCard(
                    title: 'Approval File Upload *',
                    icon: Icons.attach_file_rounded,
                    hasError: _submitted && !_allApprovalFilesUploaded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload approval document for each selected approval',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDim,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._model.approvals.map((approval) {
                          final uploaded = _approvalFiles.containsKey(approval);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: uploaded
                                  ? AppColors.green.withValues(alpha: 0.04)
                                  : AppColors.surface2,
                              border: Border.all(
                                color: uploaded
                                    ? AppColors.green.withValues(alpha: 0.2)
                                    : (_submitted && !uploaded
                                          ? AppColors.red.withValues(alpha: 0.3)
                                          : AppColors.border),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  uploaded
                                      ? Icons.check_circle
                                      : Icons.upload_file_rounded,
                                  size: 18,
                                  color: uploaded
                                      ? AppColors.green
                                      : AppColors.textDim,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        approval,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: uploaded
                                              ? AppColors.green
                                              : AppColors.text,
                                        ),
                                      ),
                                      if (uploaded)
                                        Text(
                                          _approvalFiles[approval]!,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textDim,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (uploaded) ...[
                                  InkWell(
                                    onTap: () => _pickForApproval(approval),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: const Text(
                                        'Replace',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDim,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => setState(() {
                                      _approvalFiles.remove(approval);
                                      _approvalFileBytes.remove(approval);
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.red.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ),
                                ] else
                                  InkWell(
                                    onTap: () => _pickForApproval(approval),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: const Color(
                                          0xFF004C8F,
                                        ).withValues(alpha: 0.08),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF004C8F,
                                          ).withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: const Text(
                                        'Upload',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF004C8F),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        if (_submitted && !_allApprovalFilesUploaded)
                          _err(
                            'Please upload files for all selected approvals',
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),

                // Action buttons: Close | Clear | Save Template
                Row(
                  children: [
                    // Close
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _saving
                              ? null
                              : () => widget.onClose?.call(),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDim,
                            side: const BorderSide(color: AppColors.border2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Clear
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _resetForm,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.amber,
                            side: BorderSide(
                              color: AppColors.amber.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Save Template
                    Expanded(
                      flex: 2,
                      child: SizedBox(
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
                              : const Icon(
                                  Icons.save_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _saving ? 'Saving...' : 'Save Template',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004C8F),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(
                              0xFF004C8F,
                            ).withValues(alpha: 0.6),
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    bool hasError = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? AppColors.red : AppColors.border,
          width: hasError ? 1.5 : 1,
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: hasError
                      ? AppColors.red.withValues(alpha: 0.08)
                      : const Color(0xFF004C8F).withValues(alpha: 0.08),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: hasError ? AppColors.red : const Color(0xFF004C8F),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: hasError ? AppColors.red : AppColors.text,
                ),
              ),
              if (hasError) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.red.withValues(alpha: 0.1),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _row(List<Widget> c) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: c
        .map(
          (w) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: w,
            ),
          ),
        )
        .toList(),
  );

  Widget _loadingField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            color: AppColors.surface2,
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
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
        ),
      ],
    );
  }

  Widget _errorField(String label, VoidCallback onRetry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
              color: AppColors.red.withValues(alpha: 0.04),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: AppColors.red,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Failed to load. Tap to retry',
                    style: TextStyle(fontSize: 12, color: AppColors.red),
                  ),
                ),
                Icon(Icons.refresh_rounded, size: 14, color: AppColors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //TODO
  Widget _tf(
    String label,
    TextEditingController ctrl,
    String hint, {
    bool num = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextField(
            controller: ctrl,
            keyboardType: num ? TextInputType.number : TextInputType.text,
            inputFormatters: num
                ? [
                    FilteringTextInputFormatter.digitsOnly, // ✅ numbers only
                  ]
                : [
                    NoSpecialCharsFormatter(), // ✅ blocks all special characters
                  ],
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                
                color: AppColors.textMuted,
                fontSize: 12,
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF004C8F),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.surface2,
            ),
          ),
        ),
      ],
    );
  }

  //TODO
  Widget _dp(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    DateTime? firstDate,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: InkWell(
              onTap: enabled
                  ? () async {
                      final today = DateTime.now();

                      // ✅ initialDate must ALWAYS be >= firstDate
                      DateTime initialDate;

                      if (firstDate != null) {
                        // if go-live is in past, use today as initial
                        initialDate = firstDate.isBefore(today)
                            ? today
                            : firstDate;
                      } else {
                        initialDate = today;
                      }

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: firstDate ?? DateTime(2020),
                        lastDate: DateTime(2035),
                      );

                      if (picked != null) {
                        onChanged(
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}",
                        );
                      }
                    }
                  : null,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  color: AppColors.surface2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.isEmpty ? 'Select date' : value,
                        style: TextStyle(
                          fontSize: 12,
                          color: value.isEmpty
                              ? AppColors.textMuted
                              : AppColors.text,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Source Type multi-select dropdown ──
  Widget _sourceMasterMultiSelect() {
    final hasError =
        _submitted && _model.sourceList.isEmpty && !_model.isDynamic;
    final isOpen = _sourceOverlayEntry != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Source Type *', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        CompositedTransformTarget(
          link: _sourceLayerLink,
          child: InkWell(
            key: _sourceTriggerKey,
            onTap: _sourceMasterLoading
                ? null
                : _sourceMasterError
                ? _loadSourceMasterList
                : () => isOpen ? _closeSourceDropdown() : _openSourceDropdown(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _sourceMasterError
                      ? AppColors.red.withValues(alpha: 0.4)
                      : isOpen
                      ? const Color(0xFF004C8F)
                      : hasError
                      ? AppColors.red
                      : AppColors.border,
                  width: isOpen || hasError ? 1.5 : 1,
                ),
                color: _sourceMasterError
                    ? AppColors.red.withValues(alpha: 0.04)
                    : AppColors.surface2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _sourceMasterLoading
                        ? const Row(
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          )
                        : _sourceMasterError
                        ? Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 12,
                                color: AppColors.red,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Failed to load. Tap to retry',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.red,
                                ),
                              ),
                            ],
                          )
                        : _model.sourceList.isEmpty
                        ? const Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          )
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: _model.sourceList.map((m) {
                              final name = (m['name'] as String? ?? '').trim();
                              final type = m['sourceType']?.toString() ?? '';
                              final label = name.isNotEmpty ? name : type;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: const Color(
                                    0xFF004C8F,
                                  ).withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF004C8F,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF004C8F),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(width: 4),
                  _sourceMasterError
                      ? Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: AppColors.red,
                        )
                      : AnimatedRotation(
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
        if (hasError) _err('Source Type is required'),
      ],
    );
  }

  // ── Benefit Type multi-select dropdown ──
  Widget _benefitTypeMultiSelect() {
    final isOpen = _benefitOverlayEntry != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Benefit Type *', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        CompositedTransformTarget(
          link: _benefitLayerLink,
          child: InkWell(
            key: _benefitTriggerKey,
            onTap: () =>
                isOpen ? _closeBenefitDropdown() : _openBenefitDropdown(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOpen ? const Color(0xFF004C8F) : AppColors.border,
                  width: isOpen ? 1.5 : 1,
                ),
                color: AppColors.surface2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _selectedBenefitTypes.isEmpty
                        ? const Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          )
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: _selectedBenefitTypes.map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: const Color(
                                    0xFF004C8F,
                                  ).withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF004C8F,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF004C8F),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(width: 4),
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
      ],
    );
  }

  Widget _err(String msg) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 300),
    builder: (_, v, child) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, 4 * (1 - v)), child: child),
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.red),
          const SizedBox(width: 6),
          Text(
            msg,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  void _pickForApproval(String approval) async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (r != null && r.files.single.bytes != null) {
      setState(() {
        _approvalFiles[approval] = r.files.single.name;
        _approvalFileBytes[approval] = r.files.single.bytes!.toList();
      });
    }
  }
}

// ── Multi-select overlay ──────────────────────────────────────────────────────

class _SourceMultiSelectOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final List<SourceMasterItem> items;
  final Set<int> initialSelected;
  final double dropdownWidth;
  final VoidCallback onDismiss;
  final void Function(Set<int>) onDone;

  const _SourceMultiSelectOverlay({
    required this.layerLink,
    required this.items,
    required this.initialSelected,
    required this.dropdownWidth,
    required this.onDismiss,
    required this.onDone,
  });

  @override
  State<_SourceMultiSelectOverlay> createState() =>
      _SourceMultiSelectOverlayState();
}

class _SourceMultiSelectOverlayState extends State<_SourceMultiSelectOverlay> {
  late Set<int> _selected;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SourceMasterItem> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items
        .where(
          (i) =>
              i.displayName.toLowerCase().contains(q) ||
              i.appName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent backdrop — tap outside to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        // Dropdown card anchored below the trigger
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
              child: Container(
                width: widget.dropdownWidth,
                constraints: const BoxConstraints(maxHeight: 340),
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
                              color: Color(0xFF004C8F),
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
                                final sel = _selected.contains(item.id);
                                return InkWell(
                                  onTap: () => setState(() {
                                    if (sel) {
                                      _selected.remove(item.id);
                                    } else {
                                      _selected.add(item.id);
                                    }
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          sel
                                              ? Icons.check_box_rounded
                                              : Icons
                                                    .check_box_outline_blank_rounded,
                                          size: 18,
                                          color: sel
                                              ? const Color(0xFF004C8F)
                                              : AppColors.textDim,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.displayName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: sel
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                  color: sel
                                                      ? const Color(0xFF004C8F)
                                                      : AppColors.text,
                                                ),
                                              ),
                                              if (item.appName.isNotEmpty)
                                                Text(
                                                  item.appName,
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
                    const Divider(height: 1, color: AppColors.border),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selected.length} selected',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textDim,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => widget.onDone(_selected),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004C8F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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

class DynamicSourceTypeWidget extends StatefulWidget {
  final List<SourceMasterItem> sourceMasterList;

  final List<Map<String, dynamic>> selectedList;

  final Function(List<Map<String, dynamic>>) onChanged;

  final bool loading;
  final bool error;
  final bool submitted;
  final VoidCallback? onRetry;

  const DynamicSourceTypeWidget({
    super.key,
    required this.sourceMasterList,
    required this.selectedList,
    required this.onChanged,
    this.loading = false,
    this.error = false,
    this.submitted = false,
    this.onRetry,
  });

  @override
  State<DynamicSourceTypeWidget> createState() =>
      _DynamicSourceTypeWidgetState();
}

class _DynamicSourceTypeWidgetState extends State<DynamicSourceTypeWidget> {
  final LayerLink _layerLink = LayerLink();

  final GlobalKey _triggerKey = GlobalKey();

  OverlayEntry? _overlayEntry;

  bool get _isOpen => _overlayEntry != null;

  void _openDropdown() {
    _closeDropdown();

    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;

    final width = renderBox?.size.width ?? 280.0;

    final initialSelected = Set<int>.from(
      widget.selectedList.map((m) => m['id'] as int),
    );

    _overlayEntry = OverlayEntry(
      builder: (_) => _SourceMultiSelectOverlay(
        layerLink: _layerLink,
        items: widget.sourceMasterList,
        initialSelected: initialSelected,
        dropdownWidth: width,
        onDismiss: _closeDropdown,
        onDone: (selected) {
          final filtered = widget.sourceMasterList
              .where((s) => selected.contains(s.id))
              .toList();

          widget.onChanged(filtered.map((e) => e.toJson()).toList());

          _closeDropdown();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    setState(() {});
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.submitted && widget.selectedList.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Source Type *', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            key: _triggerKey,
            onTap: widget.loading
                ? null
                : widget.error
                ? widget.onRetry
                : () => _isOpen ? _closeDropdown() : _openDropdown(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.error
                      ? AppColors.red.withValues(alpha: 0.4)
                      : _isOpen
                      ? const Color(0xFF004C8F)
                      : hasError
                      ? AppColors.red
                      : AppColors.border,
                  width: _isOpen || hasError ? 1.5 : 1,
                ),
                color: widget.error
                    ? AppColors.red.withValues(alpha: 0.04)
                    : AppColors.surface2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: widget.loading
                        ? const Row(
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          )
                        : widget.error
                        ? Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 12,
                                color: AppColors.red,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Failed to load. Tap to retry',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.red,
                                ),
                              ),
                            ],
                          )
                        : widget.selectedList.isEmpty
                        ? const Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          )
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: widget.selectedList.map((m) {
                              final name = (m['name'] as String? ?? '').trim();

                              final type = m['sourceType']?.toString() ?? '';

                              final label = name.isNotEmpty ? name : type;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: const Color(
                                    0xFF004C8F,
                                  ).withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF004C8F,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF004C8F),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(width: 4),
                  widget.error
                      ? Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: AppColors.red,
                        )
                      : AnimatedRotation(
                          turns: _isOpen ? 0.5 : 0,
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
        if (hasError) _err('Source Type is required'),
      ],
    );
  }

  Widget _err(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.red),
          const SizedBox(width: 6),
          Text(
            msg,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Benefit Type multi-select overlay (string-based) ─────────────────────────

class _BenefitMultiSelectOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final List<String> items;
  final Set<String> initialSelected;
  final double dropdownWidth;
  final VoidCallback onDismiss;
  final void Function(Set<String>) onDone;

  const _BenefitMultiSelectOverlay({
    required this.layerLink,
    required this.items,
    required this.initialSelected,
    required this.dropdownWidth,
    required this.onDismiss,
    required this.onDone,
  });

  @override
  State<_BenefitMultiSelectOverlay> createState() =>
      _BenefitMultiSelectOverlayState();
}

class _BenefitMultiSelectOverlayState
    extends State<_BenefitMultiSelectOverlay> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
              child: Container(
                width: widget.dropdownWidth,
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: AppColors.border),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: widget.items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (_, i) {
                          final item = widget.items[i];
                          final sel = _selected.contains(item);
                          return InkWell(
                            onTap: () => setState(() {
                              if (sel) {
                                _selected.remove(item);
                              } else {
                                _selected.add(item);
                              }
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    sel
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    size: 18,
                                    color: sel
                                        ? const Color(0xFF004C8F)
                                        : AppColors.textDim,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: sel
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: sel
                                            ? const Color(0xFF004C8F)
                                            : AppColors.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selected.length} selected',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textDim,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => widget.onDone(_selected),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004C8F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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

// ── Searchable single-select dropdown ─────────────────────────────────────────

class SearchableStringDropdown extends StatefulWidget {
  final String label;
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;

  const SearchableStringDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SearchableStringDropdown> createState() =>
      SearchableStringDropdownState();
}

class SearchableStringDropdownState extends State<SearchableStringDropdown> {
  final _layerLink = LayerLink();
  final _triggerKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  bool get _isOpen => _overlayEntry != null;

  void _open() {
    _close();
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 280.0;

    _overlayEntry = OverlayEntry(
      builder: (_) => StringSearchOverlay(
        layerLink: _layerLink,
        items: widget.items,
        selected: widget.value,
        dropdownWidth: width,
        onDismiss: _close,
        onSelect: (v) {
          widget.onChanged(v);
          _close();
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            key: _triggerKey,
            onTap: _isOpen ? _close : _open,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isOpen ? const Color(0xFF004C8F) : AppColors.border,
                  width: _isOpen ? 1.5 : 1,
                ),
                color: AppColors.surface2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value.isEmpty ? 'Select' : widget.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.value.isEmpty
                            ? AppColors.textMuted
                            : AppColors.text,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
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
      ],
    );
  }
}

class StringSearchOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final List<String> items;
  final String selected;
  final double dropdownWidth;
  final VoidCallback onDismiss;
  final ValueChanged<String> onSelect;

  const StringSearchOverlay({
    super.key,
    required this.layerLink,
    required this.items,
    required this.selected,
    required this.dropdownWidth,
    required this.onDismiss,
    required this.onSelect,
  });

  @override
  State<StringSearchOverlay> createState() => _StringSearchOverlayState();
}

class _StringSearchOverlayState extends State<StringSearchOverlay> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((s) => s.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
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
                          hintText: 'Search...',
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
                              color: Color(0xFF004C8F),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
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
                                final isSel = widget.selected == item;
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
                                              ? const Color(0xFF004C8F)
                                              : AppColors.textDim,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSel
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isSel
                                                  ? const Color(0xFF004C8F)
                                                  : AppColors.text,
                                            ),
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

// ─────────────────────────────────────────────────────────────────────────────

class SuccessDialog extends StatefulWidget {
  final VoidCallback onDone;
  final String? reqId;
  const SuccessDialog({super.key, required this.onDone, this.reqId});
  @override
  State<SuccessDialog> createState() => SuccessDialogState();
}

class SuccessDialogState extends State<SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_ctrl);
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.green.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Data Saved Successfully!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Template has been saved successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textDim),
                  ),
                  if (widget.reqId != null && widget.reqId!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.green.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Request ID:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDim,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '#${widget.reqId}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: widget.onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004C8F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
