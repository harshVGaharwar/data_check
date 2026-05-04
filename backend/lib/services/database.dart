import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// In-memory data store — replace with real DB later
class Database {
  static final Database _instance = Database._();
  factory Database() => _instance;
  Database._();

  final _uuid = const Uuid();

  // ── Users ──
  final Map<String, User> users = {
    'USR-001': User(
        id: 'USR-001', username: 'admin', password: 'admin123', role: 'admin'),
    'USR-002': User(
        id: 'USR-002',
        username: 'harsh',
        password: 'harsh123',
        role: 'developer'),
    'USR-003': User(
        id: 'USR-003', username: 'demo', password: 'demo123', role: 'viewer'),
  };

  // ── Active tokens ──
  // Dev tokens pre-registered so backend restarts don't invalidate sessions
  final Map<String, String> tokens = {
    'dev-token-admin': 'USR-001',
    'dev-token-harsh': 'USR-002',
    'dev-token-demo': 'USR-003',
  };

  // ── Templates by Department ID ──
  final Map<int, List<Map<String, dynamic>>> templatesByDept = {
    1: [
      // Finance
      {
        'templateId': 1,
        'templateName': 'GL Reconciliation',
        'department': 'Finance',
        'frequency': 'Monthly',
        'sourceCount': 3,
        'numberOfOutputs': 2,
        'normalVolume': 500,
        'peakVolume': 1000,
        'priority': 'High',
        'benefitType': 'Efficiency',
        'benefitAmount': 5000,
        'outputFormats': ['CSV', 'Excel']
      },
      {
        'templateId': 2,
        'templateName': 'P&L Report',
        'department': 'Finance',
        'frequency': 'Monthly',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 200,
        'peakVolume': 400,
        'priority': 'High',
        'benefitType': 'Reporting',
        'benefitAmount': 3000,
        'outputFormats': ['Excel']
      },
      {
        'templateId': 3,
        'templateName': 'Budget Variance',
        'department': 'Finance',
        'frequency': 'Quarterly',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 100,
        'peakVolume': 200,
        'priority': 'Medium',
        'benefitType': 'CostSaving',
        'benefitAmount': 2000,
        'outputFormats': ['CSV']
      },
      {
        'templateId': 4,
        'templateName': 'Cash Flow',
        'department': 'Finance',
        'frequency': 'Weekly',
        'sourceCount': 2,
        'numberOfOutputs': 2,
        'normalVolume': 300,
        'peakVolume': 600,
        'priority': 'High',
        'benefitType': 'Compliance',
        'benefitAmount': 4000,
        'outputFormats': ['CSV', 'Excel']
      },
      {
        'templateId': 5,
        'templateName': 'Trial Balance',
        'department': 'Finance',
        'frequency': 'Monthly',
        'sourceCount': 1,
        'numberOfOutputs': 1,
        'normalVolume': 150,
        'peakVolume': 300,
        'priority': 'Medium',
        'benefitType': 'Reporting',
        'benefitAmount': 1500,
        'outputFormats': ['Excel']
      },
    ],
    2: [
      // Operations
      {
        'templateId': 6,
        'templateName': 'Daily MIS',
        'department': 'Operations',
        'frequency': 'Daily',
        'sourceCount': 3,
        'numberOfOutputs': 2,
        'normalVolume': 1000,
        'peakVolume': 2000,
        'priority': 'High',
        'benefitType': 'Efficiency',
        'benefitAmount': 6000,
        'outputFormats': ['CSV']
      },
      {
        'templateId': 7,
        'templateName': 'Branch Performance',
        'department': 'Operations',
        'frequency': 'Monthly',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 300,
        'peakVolume': 600,
        'priority': 'Medium',
        'benefitType': 'Reporting',
        'benefitAmount': 2500,
        'outputFormats': ['Excel']
      },
      {
        'templateId': 8,
        'templateName': 'Transaction Summary',
        'department': 'Operations',
        'frequency': 'Daily',
        'sourceCount': 1,
        'numberOfOutputs': 1,
        'normalVolume': 5000,
        'peakVolume': 8000,
        'priority': 'High',
        'benefitType': 'Compliance',
        'benefitAmount': 3500,
        'outputFormats': ['CSV']
      },
      {
        'templateId': 9,
        'templateName': 'SLA Report',
        'department': 'Operations',
        'frequency': 'Weekly',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 200,
        'peakVolume': 400,
        'priority': 'Medium',
        'benefitType': 'Efficiency',
        'benefitAmount': 2000,
        'outputFormats': ['Excel']
      },
    ],
    3: [
      // Marketing
      {
        'templateId': 10,
        'templateName': 'Campaign Report',
        'department': 'Marketing',
        'frequency': 'Weekly',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 200,
        'peakVolume': 400,
        'priority': 'Medium',
        'benefitType': 'Revenue',
        'benefitAmount': 8000,
        'outputFormats': ['CSV', 'Excel']
      },
      {
        'templateId': 11,
        'templateName': 'Customer Segment',
        'department': 'Marketing',
        'frequency': 'Monthly',
        'sourceCount': 3,
        'numberOfOutputs': 2,
        'normalVolume': 500,
        'peakVolume': 1000,
        'priority': 'High',
        'benefitType': 'Revenue',
        'benefitAmount': 12000,
        'outputFormats': ['Excel']
      },
    ],
    4: [
      // IT
      {
        'templateId': 12,
        'templateName': 'System Health',
        'department': 'IT',
        'frequency': 'Daily',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 500,
        'peakVolume': 1000,
        'priority': 'High',
        'benefitType': 'Efficiency',
        'benefitAmount': 3000,
        'outputFormats': ['CSV']
      },
      {
        'templateId': 13,
        'templateName': 'API Metrics',
        'department': 'IT',
        'frequency': 'Daily',
        'sourceCount': 1,
        'numberOfOutputs': 1,
        'normalVolume': 2000,
        'peakVolume': 5000,
        'priority': 'High',
        'benefitType': 'Efficiency',
        'benefitAmount': 2000,
        'outputFormats': ['CSV']
      },
      {
        'templateId': 14,
        'templateName': 'Uptime Report',
        'department': 'IT',
        'frequency': 'Weekly',
        'sourceCount': 1,
        'numberOfOutputs': 1,
        'normalVolume': 100,
        'peakVolume': 200,
        'priority': 'Low',
        'benefitType': 'Compliance',
        'benefitAmount': 1000,
        'outputFormats': ['Excel']
      },
    ],
    5: [
      // HR
      {
        'templateId': 15,
        'templateName': 'Headcount Report',
        'department': 'HR',
        'frequency': 'Monthly',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 100,
        'peakVolume': 200,
        'priority': 'Medium',
        'benefitType': 'Efficiency',
        'benefitAmount': 1500,
        'outputFormats': ['Excel']
      },
      {
        'templateId': 16,
        'templateName': 'Payroll Summary',
        'department': 'HR',
        'frequency': 'Monthly',
        'sourceCount': 2,
        'numberOfOutputs': 2,
        'normalVolume': 200,
        'peakVolume': 400,
        'priority': 'High',
        'benefitType': 'Compliance',
        'benefitAmount': 2000,
        'outputFormats': ['CSV', 'Excel']
      },
      {
        'templateId': 17,
        'templateName': 'Attrition Report',
        'department': 'HR',
        'frequency': 'Quarterly',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 50,
        'peakVolume': 100,
        'priority': 'Medium',
        'benefitType': 'Reporting',
        'benefitAmount': 1000,
        'outputFormats': ['Excel']
      },
    ],
    6: [
      // Risk
      {
        'templateId': 18,
        'templateName': 'NPA Report',
        'department': 'Risk',
        'frequency': 'Monthly',
        'sourceCount': 3,
        'numberOfOutputs': 2,
        'normalVolume': 500,
        'peakVolume': 1000,
        'priority': 'High',
        'benefitType': 'Compliance',
        'benefitAmount': 10000,
        'outputFormats': ['CSV', 'Excel']
      },
      {
        'templateId': 19,
        'templateName': 'Exposure Report',
        'department': 'Risk',
        'frequency': 'Weekly',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 300,
        'peakVolume': 600,
        'priority': 'High',
        'benefitType': 'Compliance',
        'benefitAmount': 7000,
        'outputFormats': ['Excel']
      },
    ],
    7: [
      // Compliance
      {
        'templateId': 20,
        'templateName': 'AML Report',
        'department': 'Compliance',
        'frequency': 'Daily',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 1000,
        'peakVolume': 2000,
        'priority': 'High',
        'benefitType': 'Compliance',
        'benefitAmount': 15000,
        'outputFormats': ['CSV']
      },
      {
        'templateId': 21,
        'templateName': 'KYC Tracker',
        'department': 'Compliance',
        'frequency': 'Weekly',
        'sourceCount': 2,
        'numberOfOutputs': 1,
        'normalVolume': 500,
        'peakVolume': 1000,
        'priority': 'High',
        'benefitType': 'Compliance',
        'benefitAmount': 8000,
        'outputFormats': ['CSV', 'Excel']
      },
      {
        'templateId': 22,
        'templateName': 'Audit Trail',
        'department': 'Compliance',
        'frequency': 'Daily',
        'sourceCount': 1,
        'numberOfOutputs': 1,
        'normalVolume': 2000,
        'peakVolume': 4000,
        'priority': 'High',
        'benefitType': 'Compliance',
        'benefitAmount': 5000,
        'outputFormats': ['CSV']
      },
    ],
    8: [
      // Treasury
      {
        'templateId': 23,
        'templateName': 'Liquidity Report',
        'department': 'Treasury',
        'frequency': 'Daily',
        'sourceCount': 2,
        'numberOfOutputs': 2,
        'normalVolume': 300,
        'peakVolume': 600,
        'priority': 'High',
        'benefitType': 'Compliance',
        'benefitAmount': 6000,
        'outputFormats': ['CSV', 'Excel']
      },
      {
        'templateId': 24,
        'templateName': 'FX Exposure',
        'department': 'Treasury',
        'frequency': 'Weekly',
        'sourceCount': 3,
        'numberOfOutputs': 1,
        'normalVolume': 200,
        'peakVolume': 400,
        'priority': 'High',
        'benefitType': 'Revenue',
        'benefitAmount': 9000,
        'outputFormats': ['Excel']
      },
    ],
  };

  // ── Source Types ──
  final List<Map<String, dynamic>> sourceTypes = [
    {'id': 1, 'sourceName': '1 - Manual', 'sourceValue': 'manual'},
    {'id': 2, 'sourceName': '2 - QRS', 'sourceValue': 'qrs'},
    {'id': 3, 'sourceName': '2 - FC', 'sourceValue': 'fc'},
    {'id': 4, 'sourceName': '2 - lasersoft', 'sourceValue': 'ls'},
  ];

  // ── Operations ──
  final List<Map<String, dynamic>> operations = [
    {
      'id': 1,
      'operationName': '1 - All from First ',
      'operationValue': 'left_join'
    },
    {
      'id': 2,
      'operationName': '2 - Matches only',
      'operationValue': 'inner_join'
    },
    {
      'id': 3,
      'operationName': '3 - All from second',
      'operationValue': 'right_join'
    },
    {'id': 4, 'operationName': '4 - All', 'operationValue': 'union'},
  ];

  // ── Approval List ──
  final List<Map<String, dynamic>> approvalList = [
    {
      'id': 1,
      'approvalName': 'Unit Head',
      'createdBy': 'Admin',
      'createdOn': '0001-01-01T00:00:00',
    },
    {
      'id': 2,
      'approvalName': 'UAT Sign Off',
      'createdBy': 'Admin',
      'createdOn': '0001-01-01T00:00:00',
    },
    {
      'id': 3,
      'approvalName': 'Marketing',
      'createdBy': 'Admin',
      'createdOn': '0001-01-01T00:00:00',
    },
    {
      'id': 4,
      'approvalName': 'BCU Head',
      'createdBy': 'Admin',
      'createdOn': '0001-01-01T00:00:00',
    },
    {
      'id': 5,
      'approvalName': 'CCU Head Approval',
      'createdBy': 'Admin',
      'createdOn': '0001-01-01T00:00:00',
    },
    {
      'id': 6,
      'approvalName': 'Functional Head Approval',
      'createdBy': 'Admin',
      'createdOn': '0001-01-01T00:00:00',
    },
    {
      'id': 7,
      'approvalName': 'SMS Whitelisting',
      'createdBy': 'Admin',
      'createdOn': '0001-01-01T00:00:00',
    },
  ];

  // ── Source Master Records ──
  final List<Map<String, dynamic>> manualUploads = [];

  final List<Map<String, dynamic>> sourceMasterList = [
    {
      'id': 10,
      'name': 'unimailing',
      'sourceType': "1",
      'appName': 'MyApplication',
      'itgrc': 1,
      'dbVault': 'VaultDB',
      'createdBy': 'admin_user',
      'createdOn': '0001-01-01T00:00:00',
      'department_id': 1,
    },
    {
      'id': 12,
      'name': 'unimailing2',
      'sourceType': "1",
      'appName': 'MyApplication',
      'itgrc': 1,
      'dbVault': 'VaultDB',
      'createdBy': 'admin_user',
      'createdOn': '0001-01-01T00:00:00',
      'department_id': 1,
    },
    {
      'id': 13,
      'name': 'test',
      'sourceType': "2",
      'appName': 'MyApplication',
      'itgrc': 1,
      'dbVault': 'VaultDB',
      'createdBy': 'admin_user',
      'createdOn': '0001-01-01T00:00:00',
      'department_id': 2,
    },
    {
      'id': 14,
      'name': 'test',
      'sourceType': "3",
      'appName': 'MyApplication',
      'itgrc': 1,
      'dbVault': 'VaultDB',
      'createdBy': 'admin_user',
      'createdOn': '0001-01-01T00:00:00',
      'department_id': 2,
    },
  ];

  // ── Manual Upload Templates (by dept ID) ──
  final Map<int, List<Map<String, dynamic>>> manualTemplatesByDept = {
    1: [
      {
        'templateId': 0,
        'templateName': '--Select--',
        'department': null,
        'sourceCount': 0,
        'manualCount': 0
      },
      {
        'templateId': 1,
        'templateName': 'GL Reconciliation',
        'department': 'Finance',
        'sourceCount': 3,
        'manualCount': 1
      },
      {
        'templateId': 2,
        'templateName': 'P&L Report',
        'department': 'Finance',
        'sourceCount': 2,
        'manualCount': 1
      },
    ],
    2: [
      {
        'templateId': 0,
        'templateName': '--Select--',
        'department': null,
        'sourceCount': 0,
        'manualCount': 0
      },
      {
        'templateId': 5,
        'templateName': 'Ops Daily Report',
        'department': 'Operations',
        'sourceCount': 2,
        'manualCount': 1
      },
    ],
    4: [
      {
        'templateId': 0,
        'templateName': '--Select--',
        'department': null,
        'sourceCount': 0,
        'manualCount': 0
      },
      {
        'templateId': 9,
        'templateName': 'IT Asset Register',
        'department': 'IT',
        'sourceCount': 1,
        'manualCount': 1
      },
    ],
    5: [
      {
        'templateId': 0,
        'templateName': '--Select--',
        'department': null,
        'sourceCount': 0,
        'manualCount': 0
      },
      {
        'templateId': 11,
        'templateName': '11 - asdsa',
        'department': null,
        'sourceCount': 0,
        'manualCount': 2
      },
      {
        'templateId': 12,
        'templateName': '12 - 2 manual 2 QRS',
        'department': null,
        'sourceCount': 0,
        'manualCount': 2
      },
      {
        'templateId': 13,
        'templateName': '13 - temp1',
        'department': null,
        'sourceCount': 0,
        'manualCount': 4
      },
      {
        'templateId': 15,
        'templateName': '15 - Msodi',
        'department': null,
        'sourceCount': 0,
        'manualCount': 3
      },
      {
        'templateId': 16,
        'templateName': '16 - Template1',
        'department': null,
        'sourceCount': 0,
        'manualCount': 2
      },
      {
        'templateId': 17,
        'templateName': '17 - Template1',
        'department': null,
        'sourceCount': 0,
        'manualCount': 2
      },
      {
        'templateId': 19,
        'templateName': '19 - Template3',
        'department': null,
        'sourceCount': 0,
        'manualCount': 2
      },
      {
        'templateId': 22,
        'templateName': '22 - temp1',
        'department': null,
        'sourceCount': 0,
        'manualCount': 2
      },
      {
        'templateId': 24,
        'templateName': '24 - temp10',
        'department': null,
        'sourceCount': 0,
        'manualCount': 2
      },
    ],
  };

  // ── Source List (by dept + template) ──
  final Map<String, List<Map<String, dynamic>>> sourceListByDeptTemplate = {
    '1_1': [
      {'id': 0, 's_Name': '--Select--'},
      {'id': 1, 's_Name': 'Finacle Core'},
      {'id': 2, 's_Name': 'Oracle GL'},
    ],
    '1_2': [
      {'id': 0, 's_Name': '--Select--'},
      {'id': 3, 's_Name': 'SAP FI'},
    ],
    '2_5': [
      {'id': 0, 's_Name': '--Select--'},
      {'id': 4, 's_Name': 'Ops DB'},
    ],
    '4_9': [
      {'id': 0, 's_Name': '--Select--'},
      {'id': 5, 's_Name': 'Asset DB'},
    ],
    '7_15': [
      {'id': 0, 's_Name': '--Select--'},
      {'id': 97, 's_Name': 'source1'},
      {'id': 98, 's_Name': 'source2'},
      {'id': 99, 's_Name': 'source3'},
    ],
  };

  // ── Departments ──
  final List<Department> departments = [
    Department(id: 1, name: 'Finance'),
    Department(id: 2, name: 'Operations'),
    Department(id: 3, name: 'Marketing'),
    Department(id: 4, name: 'IT'),
    Department(id: 5, name: 'HR'),
    Department(id: 6, name: 'Risk'),
    Department(id: 7, name: 'Compliance'),
    Department(id: 8, name: 'Treasury'),
  ];

  // ── Templates ──
  final Map<String, Template> templates = {};

  // ── Pipeline Configs ──
  final Map<String, PipelineConfig> pipelineConfigs = {};

  // ── Source Configs ──
  // Keyed by "templateId_deptId". Pre-seeded for dev-mode testing.
  final Map<String, Map<String, dynamic>> sourceConfigs = {
    // ── P&L Report (templateId=2, dept Finance=1) — 2 sources, join, output ──
    '2_1': {
      'TemplateId': 2,
      'createdBy': 'ADM001',
      'Sources': [
        {
          'TemplateId': 2,
          'SourceId': '10',
          'SourceName': 'S1',
          'SourceType': '1',
          'Department': '1',
          'Template': 'P&L Report',
          'Separator': ',',
          'ColumnFile': 'dummy_data.csv',
          'QueryFile': '',
          'Columns': 'id,template_name,department,source_type,operation,'
              'approval_status,config_file,pipeline_format,token,'
              'created_at,updated_at',
          'SelectedColumns': 'approval_status',
          'SourceSeqNo': null,
        },
        {
          'TemplateId': 2,
          'SourceId': '13',
          'SourceName': 'S2',
          'SourceType': '2',
          'Department': '1',
          'Template': 'P&L Report',
          'Separator': ',',
          'ColumnFile': 'dummy_data.csv',
          'QueryFile': 'valid_query_with.txt',
          'Columns': 'id,template_name,department,source_type,operation,'
              'approval_status,config_file,pipeline_format,token,'
              'created_at,updated_at',
          'SelectedColumns': 'created_at',
          'SourceSeqNo': null,
        },
      ],
      'JoinMappings': [
        {
          'Id': 0,
          'TemplateId': 2,
          'Department': '1',
          'JoinNodeId': 'n4',
          'LeftSourceId': 'n1',
          'LeftSourceName': 'S1',
          'LeftColumn': 'template_name',
          'JoinType': 'left_join',
          'RightSourceId': 'n3',
          'RightSourceName': 'S2',
          'RightColumn': 'template_name',
          'CreatedOn': '2026-04-29T00:00:00',
        },
        {
          'Id': 1,
          'TemplateId': 2,
          'Department': '1',
          'JoinNodeId': 'n4',
          'LeftSourceId': 'n3',
          'LeftSourceName': 'S2',
          'LeftColumn': 'template_name',
          'JoinType': 'left_join',
          'RightSourceId': 'n1',
          'RightSourceName': 'S1',
          'RightColumn': 'template_name',
          'CreatedOn': '2026-04-29T00:00:00',
        },
      ],
      'Edges': [
        {'template_id': 2, 'department': '1', 'From': 'n1', 'To': 'n4'},
        {'template_id': 2, 'department': '1', 'From': 'n3', 'To': 'n4'},
      ],
      'connectedSources': [
        {
          'TemplateId': 2,
          'Department': '1',
          'JoinNodeId': 'n4',
          'SourceId': 'n1'
        },
        {
          'TemplateId': 2,
          'Department': '1',
          'JoinNodeId': 'n4',
          'SourceId': 'n3'
        },
      ],
      'outputColumns': [
        {
          'template_id': 2,
          'department': '1',
          'sourceid': '1',
          'sourceName': 'S1',
          'SourceColName': 'approval_status',
          'ColumnName': 'ASD',
        },
        {
          'template_id': 2,
          'department': '1',
          'sourceid': '2',
          'sourceName': 'S2',
          'SourceColName': 'created_at',
          'ColumnName': 'ASD',
        },
      ],
    },
    // ── Budget Variance (templateId=3, dept Finance=1) — 2 sources ──
    '3_1': {
      'TemplateId': 3,
      'createdBy': 'ADM001',
      'Sources': [
        {
          'TemplateId': 3,
          'SourceId': '10',
          'SourceName': 'BudgetSrc',
          'SourceType': '1',
          'Department': '1',
          'Template': 'Budget Variance',
          'Separator': ',',
          'ColumnFile': 'budget.csv',
          'QueryFile': '',
          'Columns': 'id,period,budget_amount,actual_amount,variance,dept',
          'SelectedColumns': 'variance',
          'SourceSeqNo': null,
        },
        {
          'TemplateId': 3,
          'SourceId': '13',
          'SourceName': 'ActualSrc',
          'SourceType': '2',
          'Department': '1',
          'Template': 'Budget Variance',
          'Separator': ',',
          'ColumnFile': 'actuals.csv',
          'QueryFile': '',
          'Columns': 'id,period,budget_amount,actual_amount,variance,dept',
          'SelectedColumns': 'actual_amount',
          'SourceSeqNo': null,
        },
      ],
      'JoinMappings': [
        {
          'Id': 0,
          'TemplateId': 3,
          'Department': '1',
          'JoinNodeId': 'n4',
          'LeftSourceId': 'n1',
          'LeftSourceName': 'BudgetSrc',
          'LeftColumn': 'period',
          'JoinType': 'inner_join',
          'RightSourceId': 'n3',
          'RightSourceName': 'ActualSrc',
          'RightColumn': 'period',
          'CreatedOn': '2026-04-29T00:00:00',
        },
      ],
      'Edges': [
        {'template_id': 3, 'department': '1', 'From': 'n1', 'To': 'n4'},
        {'template_id': 3, 'department': '1', 'From': 'n3', 'To': 'n4'},
      ],
      'connectedSources': [
        {
          'TemplateId': 3,
          'Department': '1',
          'JoinNodeId': 'n4',
          'SourceId': 'n1'
        },
        {
          'TemplateId': 3,
          'Department': '1',
          'JoinNodeId': 'n4',
          'SourceId': 'n3'
        },
      ],
      'outputColumns': [
        {
          'template_id': 3,
          'department': '1',
          'sourceid': '1',
          'sourceName': 'BudgetSrc',
          'SourceColName': 'variance',
          'ColumnName': 'Variance',
        },
      ],
    },
  };

  // ── Helpers ──
  String newId(String prefix) =>
      '$prefix-${_uuid.v4().substring(0, 8).toUpperCase()}';

  User? findUserByUsername(String username) {
    try {
      return users.values.firstWhere((u) => u.username == username);
    } catch (_) {
      return null;
    }
  }

  User? findUserByToken(String token) {
    final userId = tokens[token];
    if (userId == null) return null;
    return users[userId];
  }
}
