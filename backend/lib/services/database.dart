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
    'USR-001': User(id: 'USR-001', username: 'admin', password: 'admin123', role: 'admin'),
    'USR-002': User(id: 'USR-002', username: 'harsh', password: 'harsh123', role: 'developer'),
    'USR-003': User(id: 'USR-003', username: 'demo', password: 'demo123', role: 'viewer'),
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
    1: [ // Finance
      {'templateId': 1, 'templateName': 'GL Reconciliation',  'department': 'Finance',     'frequency': 'Monthly',   'sourceCount': 3, 'numberOfOutputs': 2, 'normalVolume': 500,  'peakVolume': 1000, 'priority': 'High',   'benefitType': 'Efficiency', 'benefitAmount': 5000, 'outputFormats': ['CSV', 'Excel']},
      {'templateId': 2, 'templateName': 'P&L Report',          'department': 'Finance',     'frequency': 'Monthly',   'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 200,  'peakVolume': 400,  'priority': 'High',   'benefitType': 'Reporting',  'benefitAmount': 3000, 'outputFormats': ['Excel']},
      {'templateId': 3, 'templateName': 'Budget Variance',     'department': 'Finance',     'frequency': 'Quarterly', 'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 100,  'peakVolume': 200,  'priority': 'Medium', 'benefitType': 'CostSaving', 'benefitAmount': 2000, 'outputFormats': ['CSV']},
      {'templateId': 4, 'templateName': 'Cash Flow',           'department': 'Finance',     'frequency': 'Weekly',    'sourceCount': 2, 'numberOfOutputs': 2, 'normalVolume': 300,  'peakVolume': 600,  'priority': 'High',   'benefitType': 'Compliance', 'benefitAmount': 4000, 'outputFormats': ['CSV', 'Excel']},
      {'templateId': 5, 'templateName': 'Trial Balance',       'department': 'Finance',     'frequency': 'Monthly',   'sourceCount': 1, 'numberOfOutputs': 1, 'normalVolume': 150,  'peakVolume': 300,  'priority': 'Medium', 'benefitType': 'Reporting',  'benefitAmount': 1500, 'outputFormats': ['Excel']},
    ],
    2: [ // Operations
      {'templateId': 6, 'templateName': 'Daily MIS',           'department': 'Operations',  'frequency': 'Daily',     'sourceCount': 3, 'numberOfOutputs': 2, 'normalVolume': 1000, 'peakVolume': 2000, 'priority': 'High',   'benefitType': 'Efficiency', 'benefitAmount': 6000, 'outputFormats': ['CSV']},
      {'templateId': 7, 'templateName': 'Branch Performance',  'department': 'Operations',  'frequency': 'Monthly',   'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 300,  'peakVolume': 600,  'priority': 'Medium', 'benefitType': 'Reporting',  'benefitAmount': 2500, 'outputFormats': ['Excel']},
      {'templateId': 8, 'templateName': 'Transaction Summary', 'department': 'Operations',  'frequency': 'Daily',     'sourceCount': 1, 'numberOfOutputs': 1, 'normalVolume': 5000, 'peakVolume': 8000, 'priority': 'High',   'benefitType': 'Compliance', 'benefitAmount': 3500, 'outputFormats': ['CSV']},
      {'templateId': 9, 'templateName': 'SLA Report',          'department': 'Operations',  'frequency': 'Weekly',    'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 200,  'peakVolume': 400,  'priority': 'Medium', 'benefitType': 'Efficiency', 'benefitAmount': 2000, 'outputFormats': ['Excel']},
    ],
    3: [ // Marketing
      {'templateId': 10, 'templateName': 'Campaign Report',    'department': 'Marketing',   'frequency': 'Weekly',    'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 200,  'peakVolume': 400,  'priority': 'Medium', 'benefitType': 'Revenue',    'benefitAmount': 8000, 'outputFormats': ['CSV', 'Excel']},
      {'templateId': 11, 'templateName': 'Customer Segment',   'department': 'Marketing',   'frequency': 'Monthly',   'sourceCount': 3, 'numberOfOutputs': 2, 'normalVolume': 500,  'peakVolume': 1000, 'priority': 'High',   'benefitType': 'Revenue',    'benefitAmount': 12000,'outputFormats': ['Excel']},
    ],
    4: [ // IT
      {'templateId': 12, 'templateName': 'System Health',      'department': 'IT',          'frequency': 'Daily',     'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 500,  'peakVolume': 1000, 'priority': 'High',   'benefitType': 'Efficiency', 'benefitAmount': 3000, 'outputFormats': ['CSV']},
      {'templateId': 13, 'templateName': 'API Metrics',        'department': 'IT',          'frequency': 'Daily',     'sourceCount': 1, 'numberOfOutputs': 1, 'normalVolume': 2000, 'peakVolume': 5000, 'priority': 'High',   'benefitType': 'Efficiency', 'benefitAmount': 2000, 'outputFormats': ['CSV']},
      {'templateId': 14, 'templateName': 'Uptime Report',      'department': 'IT',          'frequency': 'Weekly',    'sourceCount': 1, 'numberOfOutputs': 1, 'normalVolume': 100,  'peakVolume': 200,  'priority': 'Low',    'benefitType': 'Compliance', 'benefitAmount': 1000, 'outputFormats': ['Excel']},
    ],
    5: [ // HR
      {'templateId': 15, 'templateName': 'Headcount Report',   'department': 'HR',          'frequency': 'Monthly',   'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 100,  'peakVolume': 200,  'priority': 'Medium', 'benefitType': 'Efficiency', 'benefitAmount': 1500, 'outputFormats': ['Excel']},
      {'templateId': 16, 'templateName': 'Payroll Summary',    'department': 'HR',          'frequency': 'Monthly',   'sourceCount': 2, 'numberOfOutputs': 2, 'normalVolume': 200,  'peakVolume': 400,  'priority': 'High',   'benefitType': 'Compliance', 'benefitAmount': 2000, 'outputFormats': ['CSV', 'Excel']},
      {'templateId': 17, 'templateName': 'Attrition Report',   'department': 'HR',          'frequency': 'Quarterly', 'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 50,   'peakVolume': 100,  'priority': 'Medium', 'benefitType': 'Reporting',  'benefitAmount': 1000, 'outputFormats': ['Excel']},
    ],
    6: [ // Risk
      {'templateId': 18, 'templateName': 'NPA Report',         'department': 'Risk',        'frequency': 'Monthly',   'sourceCount': 3, 'numberOfOutputs': 2, 'normalVolume': 500,  'peakVolume': 1000, 'priority': 'High',   'benefitType': 'Compliance', 'benefitAmount': 10000,'outputFormats': ['CSV', 'Excel']},
      {'templateId': 19, 'templateName': 'Exposure Report',    'department': 'Risk',        'frequency': 'Weekly',    'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 300,  'peakVolume': 600,  'priority': 'High',   'benefitType': 'Compliance', 'benefitAmount': 7000, 'outputFormats': ['Excel']},
    ],
    7: [ // Compliance
      {'templateId': 20, 'templateName': 'AML Report',         'department': 'Compliance',  'frequency': 'Daily',     'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 1000, 'peakVolume': 2000, 'priority': 'High',   'benefitType': 'Compliance', 'benefitAmount': 15000,'outputFormats': ['CSV']},
      {'templateId': 21, 'templateName': 'KYC Tracker',        'department': 'Compliance',  'frequency': 'Weekly',    'sourceCount': 2, 'numberOfOutputs': 1, 'normalVolume': 500,  'peakVolume': 1000, 'priority': 'High',   'benefitType': 'Compliance', 'benefitAmount': 8000, 'outputFormats': ['CSV', 'Excel']},
      {'templateId': 22, 'templateName': 'Audit Trail',        'department': 'Compliance',  'frequency': 'Daily',     'sourceCount': 1, 'numberOfOutputs': 1, 'normalVolume': 2000, 'peakVolume': 4000, 'priority': 'High',   'benefitType': 'Compliance', 'benefitAmount': 5000, 'outputFormats': ['CSV']},
    ],
    8: [ // Treasury
      {'templateId': 23, 'templateName': 'Liquidity Report',   'department': 'Treasury',    'frequency': 'Daily',     'sourceCount': 2, 'numberOfOutputs': 2, 'normalVolume': 300,  'peakVolume': 600,  'priority': 'High',   'benefitType': 'Compliance', 'benefitAmount': 6000, 'outputFormats': ['CSV', 'Excel']},
      {'templateId': 24, 'templateName': 'FX Exposure',        'department': 'Treasury',    'frequency': 'Weekly',    'sourceCount': 3, 'numberOfOutputs': 1, 'normalVolume': 200,  'peakVolume': 400,  'priority': 'High',   'benefitType': 'Revenue',    'benefitAmount': 9000, 'outputFormats': ['Excel']},
    ],
  };

  // ── Source Types ──
  final List<Map<String, dynamic>> sourceTypes = [
    {'id': 1, 'sourceName': 'Database',      'sourceValue': 'DB'},
    {'id': 2, 'sourceName': 'Manual Upload', 'sourceValue': 'MANUAL'},
    {'id': 3, 'sourceName': 'Finacle Core',  'sourceValue': 'FC'},
    {'id': 4, 'sourceName': 'Laser Banking', 'sourceValue': 'LASER'},
  ];

  // ── Operations ──
  final List<Map<String, dynamic>> operations = [
    {'id': 1, 'operationName': 'Equals',                 'operationValue': '='},
    {'id': 2, 'operationName': 'Not Equals',             'operationValue': '!='},
    {'id': 3, 'operationName': 'Greater Than',           'operationValue': '>'},
    {'id': 4, 'operationName': 'Less Than',              'operationValue': '<'},
    {'id': 5, 'operationName': 'Greater Than or Equal',  'operationValue': '>='},
    {'id': 6, 'operationName': 'Less Than or Equal',     'operationValue': '<='},
    {'id': 7, 'operationName': 'Contains',               'operationValue': 'contains'},
    {'id': 8, 'operationName': 'Starts With',            'operationValue': 'starts with'},
  ];

  // ── Approval List ──
  final List<String> approvalList = [
    'Unit Head',
    'UAT Sign Off',
    'Marketing',
    'BCU Head',
    'CCU Head Approval',
    'Functional Head Approval',
    'SMS Whitelisting',
  ];

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
  final Map<String, Map<String, dynamic>> sourceConfigs = {};

  // ── Helpers ──
  String newId(String prefix) => '$prefix-${_uuid.v4().substring(0, 8).toUpperCase()}';

  User? findUserByUsername(String username) {
    try { return users.values.firstWhere((u) => u.username == username); } catch (_) { return null; }
  }

  User? findUserByToken(String token) {
    final userId = tokens[token];
    if (userId == null) return null;
    return users[userId];
  }
}
