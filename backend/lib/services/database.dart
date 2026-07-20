import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// In-memory data store — replace with real DB later
class Database {
  static final Database _instance = Database._();
  factory Database() => _instance;

  static const _dynamicTemplatesPath = 'data/dynamic_templates.json';

  /// Tracks only runtime-added templates — persisted to disk
  final Map<int, List<Map<String, dynamic>>> _dynamicTemplates = {};

  Database._() {
    _loadDynamicTemplates();
  }

  void _loadDynamicTemplates() {
    try {
      final file = File(_dynamicTemplatesPath);
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final deptId = int.tryParse(entry.key);
        if (deptId == null) continue;
        final list = (entry.value as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _dynamicTemplates[deptId] = list;
        templatesByDept.putIfAbsent(deptId, () => []);
        templatesByDept[deptId]!.addAll(list);
      }
      print(
          '[DB] Loaded ${_dynamicTemplates.values.expand((l) => l).length} dynamic template(s)');
    } catch (e) {
      print('[DB] Could not load dynamic templates: $e');
    }
  }

  /// Adds a template entry to the in-memory map AND persists it to disk.
  void persistTemplate(int deptId, Map<String, dynamic> entry) {
    templatesByDept.putIfAbsent(deptId, () => []);
    templatesByDept[deptId]!.add(entry);
    _dynamicTemplates.putIfAbsent(deptId, () => []);
    _dynamicTemplates[deptId]!.add(entry);
    _saveDynamicTemplates();
  }

  void _saveDynamicTemplates() {
    try {
      final file = File(_dynamicTemplatesPath);
      file.parent.createSync(recursive: true);
      final jsonData = {
        for (final e in _dynamicTemplates.entries) e.key.toString(): e.value,
      };
      file.writeAsStringSync(jsonEncode(jsonData));
    } catch (e) {
      print('[DB] Failed to save dynamic templates: $e');
    }
  }

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
  // 3 cases: Static+UserDefined, Static+UniMailing, Dynamic+UniMailing
  final Map<int, List<Map<String, dynamic>>> templatesByDept = {
    1: [
      {
        "templateType": "2",
        "templateId": 3,
        "templateName": "3 - template 1 static",
        "department": null,
        "frequency": "1",
        "normalVolume": 0,
        "peakVolume": 0,
        "sourceCount": 2,
        "numberOfOutputs": 0,
        "benefitType": 0,
        "benefitAmount": 0,
        "benefitInTAT": null,
        "goLiveDate": null,
        "deactivateDate": null,
        "spocPerson": null,
        "spocManager": null,
        "unitHead": null,
        "priority": 0,
        "template": null,
        "outputFormats": [
          {"templateTempId": 3, "formatName": "Unimailing"}
        ],
        "approvals": null,
        "dynamicTemplate": [
          {
            "srno": 0,
            "id": 0,
            "sourceList": "1,2",
            "sourceCount": "2",
            "sourceListName": null,
            "templateId": 3,
            'sourceMasterList': [
              {
                'id': 1,
                'name': '1 - Finacle Core',
                'sourceType': '1',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '1',
                'type': '1',
                'template_id': null,
              },
              {
                'id': 2,
                'name': '2 - Oracle GL',
                'sourceType': '2',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '1',
                'type': '1',
                'template_id': null,
              },
            ],
            "sourceType": "1"
          }
        ],
        "jsonData": [
          {
            "TemplateId": 216,
            "TemplateType": 2,
            "DynamicId": 0,
            "templateMode": 0,
            "createdBy": "ADM001",
            "Sources": [
              {
                "TemplateId": 2,
                "SourceId": "10",
                "SourceName": "S1",
                "SourceType": "1",
                "Department": "1",
                "Template": "P&L Report",
                "Separator": ",",
                "ColumnFile": "dummy_data.csv",
                "QueryFile": "",
                "Columns":
                    "id,template_name,department,source_type,operation,approval_status,config_file,pipeline_format,token,created_at,updated_at",
                "SelectedColumns": "approval_status",
                "SourceSeqNo": "",
                "uniquefield": "true"
              },
              {
                "TemplateId": 2,
                "SourceId": "13",
                "SourceName": "S2",
                "SourceType": "2",
                "Department": "1",
                "Template": "P&L Report",
                "Separator": ",",
                "ColumnFile": "dummy_data.csv",
                "QueryFile": "valid_query_with.txt",
                "Columns":
                    "id,template_name,department,source_type,operation,approval_status,config_file,pipeline_format,token,created_at,updated_at",
                "SelectedColumns": "created_at",
                "SourceSeqNo": null,
                "uniquefield": ""
              }
            ],
            "JoinMappings": [
              {
                "Id": 0,
                "TemplateId": 2,
                "Department": "1",
                "JoinNodeId": "n4",
                "LeftSourceId": "n1",
                "LeftSourceName": "S1",
                "LeftColumn": "template_name",
                "JoinType": "left_join",
                "RightSourceId": "n3",
                "RightSourceName": "S2",
                "RightColumn": "template_name",
                "CreatedOn": "2026-04-29T00:00:00"
              },
              {
                "Id": 1,
                "TemplateId": 2,
                "Department": "1",
                "JoinNodeId": "n4",
                "LeftSourceId": "n3",
                "LeftSourceName": "S2",
                "LeftColumn": "template_name",
                "JoinType": "left_join",
                "RightSourceId": "n1",
                "RightSourceName": "S1",
                "RightColumn": "template_name",
                "CreatedOn": "2026-04-29T00:00:00"
              }
            ],
            "Edges": [
              {"template_id": 2, "department": "1", "From": "n1", "To": "n4"},
              {"template_id": 2, "department": "1", "From": "n3", "To": "n4"}
            ],
            "connectedSources": [
              {
                "TemplateId": 2,
                "Department": "1",
                "JoinNodeId": "n4",
                "SourceId": "n1"
              },
              {
                "TemplateId": 2,
                "Department": "1",
                "JoinNodeId": "n4",
                "SourceId": "n3"
              }
            ],
            "outputColumns": [
              {
                "template_id": 2,
                "department": "1",
                "sourceid": "1",
                "sourceName": "S1",
                "SourceColName": "approval_status",
                "ColumnName": "Mail To",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "1",
                "sourceid": "2",
                "sourceName": "S2",
                "SourceColName": "created_at",
                "ColumnName": "Mail CC",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "1",
                "sourceid": "2",
                "sourceName": "S2",
                "SourceColName": "created_at",
                "ColumnName": "Mail BCC",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "1",
                "sourceid": "2",
                "sourceName": "S2",
                "SourceColName": "created_at",
                "ColumnName": "Subject",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "1",
                "sourceid": "2",
                "sourceName": "S2",
                "SourceColName": "created_at",
                "ColumnName": "Attachment",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "1",
                "sourceid": "2",
                "sourceName": "S2",
                "SourceColName": "created_at",
                "ColumnName": "SMS To",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "1",
                "sourceid": "2",
                "sourceName": "S2",
                "SourceColName": "Barcode",
                "ColumnName": "Barcode",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "1",
                "sourceid": "2",
                "sourceName": "S2",
                "SourceColName": "asd",
                "ColumnName": "asr",
                "Priority": 0
              },
            ]
          }
        ],
        "departmentName": null,
        "sourceListNames": null,
        "sourceList": "1,2"
      },

      {
        "templateType": "2",
        "templateId": 3,
        "templateName": "3 - template 1 static for Frequency ",
        "department": null,
        "frequency": "3",
        "normalVolume": 0,
        "peakVolume": 0,
        "sourceCount": 2,
        "numberOfOutputs": 0,
        "benefitType": 0,
        "benefitAmount": 0,
        "benefitInTAT": null,
        "goLiveDate": null,
        "deactivateDate": null,
        "spocPerson": null,
        "spocManager": null,
        "unitHead": null,
        "priority": 0,
        "template": null,
        "outputFormats": [
          {"templateTempId": 3, "formatName": "Unimailing"}
        ],
        "approvals": null,
        "dynamicTemplate": [
          {
            "srno": 0,
            "id": 0,
            "sourceList": "1,2",
            "sourceCount": "2",
            "sourceListName": null,
            "templateId": 3,
            "sourceMasterList": [
              {
                'id': 1,
                'name': '1 - Finacle Core',
                'sourceType': '1',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '1',
                'type': '1',
                'template_id': null,
              },
              {
                'id': 2,
                'name': '2 - Oracle GL',
                'sourceType': '2',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '1',
                'type': '1',
                'template_id': null,
              },
            ],
            "sourceType": "1"
          }
        ],
        "jsonData": [
          {
            "TemplateId": 216,
            "TemplateType": 2,
            "DynamicId": 0,
            "templateMode": 0,
            "createdBy": "ADM001",
            "Sources": [
              {
                "TemplateId": 2,
                "SourceId": "10",
                "SourceName": "S1",
                "SourceType": "1",
                "Department": "1",
                "Template": "P&L Report",
                "Separator": ",",
                "ColumnFile": "dummy_data.csv",
                "QueryFile": "",
                "Columns":
                    "id,template_name,department,source_type,operation,approval_status,config_file,pipeline_format,token,created_at,updated_at",
                "SelectedColumns": "approval_status",
                "SourceSeqNo": "",
                "uniquefield": ""
              },
              {
                "TemplateId": 2,
                "SourceId": "13",
                "SourceName": "S2",
                "SourceType": "2",
                "Department": "1",
                "Template": "P&L Report",
                "Separator": ",",
                "ColumnFile": "dummy_data.csv",
                "QueryFile": "valid_query_with.txt",
                "Columns":
                    "id,template_name,department,source_type,operation,approval_status,config_file,pipeline_format,token,created_at,updated_at",
                "SelectedColumns": "created_at",
                "SourceSeqNo": null,
                "uniquefield": ""
              }
            ],
            "JoinMappings": [
              {
                "Id": 0,
                "TemplateId": 2,
                "Department": "1",
                "JoinNodeId": "n4",
                "LeftSourceId": "n1",
                "LeftSourceName": "S1",
                "LeftColumn": "template_name",
                "JoinType": "left_join",
                "RightSourceId": "n3",
                "RightSourceName": "S2",
                "RightColumn": "template_name",
                "CreatedOn": "2026-04-29T00:00:00"
              },
              {
                "Id": 1,
                "TemplateId": 2,
                "Department": "1",
                "JoinNodeId": "n4",
                "LeftSourceId": "n3",
                "LeftSourceName": "S2",
                "LeftColumn": "template_name",
                "JoinType": "left_join",
                "RightSourceId": "n1",
                "RightSourceName": "S1",
                "RightColumn": "template_name",
                "CreatedOn": "2026-04-29T00:00:00"
              }
            ],
            "Edges": [
              {"template_id": 2, "department": "1", "From": "n1", "To": "n4"},
              {"template_id": 2, "department": "1", "From": "n3", "To": "n4"}
            ],
            "connectedSources": [
              {
                "TemplateId": 2,
                "Department": "1",
                "JoinNodeId": "n4",
                "SourceId": "n1"
              },
              {
                "TemplateId": 2,
                "Department": "1",
                "JoinNodeId": "n4",
                "SourceId": "n3"
              }
            ],
            "outputColumns": [
              {
                "template_id": 2,
                "department": "1",
                "sourceid": "1",
                "sourceName": "S1",
                "SourceColName": "approval_status",
                "ColumnName": "ASD",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "1",
                "sourceid": "2",
                "sourceName": "S2",
                "SourceColName": "created_at",
                "ColumnName": "ASD",
                "Priority": 0
              }
            ]
          }
        ],
        "departmentName": null,
        "sourceListNames": null,
        "sourceList": "1,2"
      },
      // ── Case 3: Dynamic + UniMailing ──
      {
        'TemplateType': '3',
        'TemplateId': 57,
        'TemplateName': '57 - dynamic + unimailing',
        'Department': null,
        'Frequency': '3',
        'NormalVolume': 0,
        'PeakVolume': 0,
        'SourceCount': 0,
        'NumberOfOutputs': 0,
        'BenefitType': 0,
        'BenefitAmount': 0,
        'BenefitInTAT': null,
        'GoLiveDate': null,
        'DeactivateDate': null,
        'SpocPerson': null,
        'SpocManager': null,
        'UnitHead': null,
        'Priority': 0,
        // camelCase keys below match what the real external API returns
        'templateType': '3',
        'templateId': 57,
        'templateName': '57 - dynamic + unimailing',
        'outputFormats': [
          {'templateTempId': 57, 'formatName': 'Unimailing'},
        ],
        'dynamicTemplate': [
          {
            'srno': 0,
            'id': 0,
            'sourceList': '1',
            'sourceCount': '2',
            'sourceListName': null,
            'templateId': 57,
            'sourceMasterList': [
              {
                'id': 1,
                'name': '1 - Finacle Core',
                'sourceType': '1',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '1',
                'type': '1',
                'template_id': null,
              },
              {
                'id': 2,
                'name': '2 - Oracle GL',
                'sourceType': '2',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '1',
                'type': '1',
                'template_id': null,
              },
            ],
            'sourceType': '1',
          },
          {
            'srno': 10,
            'id': 21,
            'sourceList': '1,2',
            'sourceCount': '2',
            'sourceListName': null,
            'templateId': 57,
            'sourceMasterList': [
              {
                'id': 1,
                'name': '1 - Finacle Core',
                'sourceType': '1',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '1',
                'type': '3',
                'template_id': null,
              },
              {
                'id': 2,
                'name': '2 - Oracle GL',
                'sourceType': '2',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '1',
                'type': '3',
                'template_id': null,
              },
            ],
            'sourceType': '3',
          },
          {
            'srno': 11,
            'id': 22,
            'sourceList': '1',
            'sourceCount': '1',
            'sourceListName': null,
            'templateId': 57,
            'sourceMasterList': [
              {
                'id': 1,
                'name': '1 - Finacle Core',
                'sourceType': '1',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '1',
                'type': '3',
                'template_id': null,
              },
            ],
            'sourceType': '3',
          },
        ],
        'jsonData': [
          {
            "TemplateId": 2,
            "TemplateType": 3,
            "DymanicId": 0,
            "createdBy": "P2308",
            "templateMode": 0,
            "Sources": [
              {
                "TemplateId": 2,
                "SourceId": "1",
                "SourceName": "M1",
                "SourceType": "1",
                "Department": "7",
                "Template": "2 - Test Dynamic Temp",
                "Separator": ",",
                "ColumnFile": "manualfileheader.txt",
                "QueryFile": "",
                "Columns": "Account_Number",
                "SelectedColumns": "Account_Number",
                "SourceSeqNo": "1",
                "uniquefield": ""
              },
              {
                "TemplateId": 2,
                "SourceId": "3",
                "SourceName": "F1",
                "SourceType": "3",
                "Department": "7",
                "Template": "2 - Test Dynamic Temp",
                "Separator": ",",
                "ColumnFile": "queryfileheader.txt",
                "QueryFile": "queryfileinnerjoin.txt",
                "Columns":
                    "MAIL_TO,MAIL_CC,SUBJECT,ATTACHMENT,SMS_TO,BARCODE,Account_Number,Customer_Name,Column_3",
                "SelectedColumns":
                    "MAIL_TO,MAIL_CC,SUBJECT,ATTACHMENT,SMS_TO,BARCODE,Account_Number,Customer_Name,Column_3",
                "SourceSeqNo": "2",
                "uniquefield": ""
              }
            ],
            "JoinMappings": [
              {
                "Id": 0,
                "TemplateId": 2,
                "Department": "7",
                "JoinNodeId": "n3",
                "LeftSourceId": "n1",
                "LeftSourceName": "M1",
                "LeftColumn": "Account_Number",
                "JoinType": "inner_join",
                "RightSourceId": "n2",
                "RightSourceName": "F1",
                "RightColumn": "Column_3",
                "CreatedOn": "2026-07-06T00:00:00"
              }
            ],
            "Edges": [
              {"template_id": 2, "department": "7", "From": "n1", "To": "n3"},
              {"template_id": 2, "department": "7", "From": "n2", "To": "n3"},
              {"template_id": 2, "department": "7", "From": "n3", "To": "n6"}
            ],
            "connectedSources": [
              {
                "TemplateId": 2,
                "Department": "7",
                "JoinNodeId": "n3",
                "SourceId": "n1"
              },
              {
                "TemplateId": 2,
                "Department": "7",
                "JoinNodeId": "n3",
                "SourceId": "n2"
              }
            ],
            "outputColumns": [
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F1",
                "SourceColName": "MAIL_TO",
                "ColumnName": "Mail To",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F1",
                "SourceColName": "MAIL_CC",
                "ColumnName": "Mail CC",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F1",
                "SourceColName": "MAIL_CC",
                "ColumnName": "Mail BCC",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F1",
                "SourceColName": "SUBJECT",
                "ColumnName": "Subject",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F1",
                "SourceColName": "ATTACHMENT",
                "ColumnName": "Attachment",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F1",
                "SourceColName": "SMS_TO",
                "ColumnName": "SMS To",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F1",
                "SourceColName": "BARCODE",
                "ColumnName": "Barcode",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F1",
                "SourceColName": "Account_Number",
                "ColumnName": "Column 1",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F1",
                "SourceColName": "Customer_Name",
                "ColumnName": "Column 2",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F1",
                "SourceColName": "Column_3",
                "ColumnName": "Column 3",
                "Priority": 0
              }
            ],
            "Jsondata": null
          },
          {
            "TemplateId": 2,
            "TemplateType": 3,
            "DymanicId": 2,
            "createdBy": "P2308",
            "templateMode": 0,
            "Sources": [
              {
                "TemplateId": 2,
                "SourceId": "1",
                "SourceName": "M2",
                "SourceType": "1",
                "Department": "7",
                "Template": "2 - Test Dynamic Temp",
                "Separator": ",",
                "ColumnFile": "manualfileheader.txt",
                "QueryFile": "",
                "Columns": "Account_Number",
                "SelectedColumns": "Account_Number",
                "SourceSeqNo": "1",
                "uniquefield": ""
              },
              {
                "TemplateId": 2,
                "SourceId": "3",
                "SourceName": "F2",
                "SourceType": "3",
                "Department": "7",
                "Template": "2 - Test Dynamic Temp",
                "Separator": ",",
                "ColumnFile": "queryfileheader.txt",
                "QueryFile": "queryfile-in.txt",
                "Columns":
                    "MAIL_TO,MAIL_CC,SUBJECT,ATTACHMENT,SMS_TO,BARCODE,Account_Number,Customer_Name,Column_3",
                "SelectedColumns":
                    "MAIL_TO,MAIL_CC,SUBJECT,ATTACHMENT,SMS_TO,BARCODE,Account_Number,Customer_Name,Column_3",
                "SourceSeqNo": "2",
                "uniquefield": ""
              }
            ],
            "JoinMappings": [
              {
                "Id": 0,
                "TemplateId": 2,
                "Department": "7",
                "JoinNodeId": "n3",
                "LeftSourceId": "n1",
                "LeftSourceName": "M2",
                "LeftColumn": "Account_Number",
                "JoinType": null,
                "RightSourceId": "n2",
                "RightSourceName": "F2",
                "RightColumn": "Column_3",
                "CreatedOn": "2026-07-06T00:00:00"
              }
            ],
            "Edges": [
              {"template_id": 2, "department": "7", "From": "n1", "To": "n3"},
              {"template_id": 2, "department": "7", "From": "n2", "To": "n3"},
              {"template_id": 2, "department": "7", "From": "n3", "To": "n6"}
            ],
            "connectedSources": [
              {
                "TemplateId": 2,
                "Department": "7",
                "JoinNodeId": "n3",
                "SourceId": "n1"
              },
              {
                "TemplateId": 2,
                "Department": "7",
                "JoinNodeId": "n3",
                "SourceId": "n2"
              }
            ],
            "outputColumns": [
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "1",
                "sourceName": "M2",
                "SourceColName": "Account_Number",
                "ColumnName": "Column 0",
                "Priority": 0
              },
              {
                "template_id": 2,
                "department": "7",
                "sourceid": "3",
                "sourceName": "F2",
                "SourceColName": "Column_3",
                "ColumnName": "Column 1",
                "Priority": 0
              }
            ],
            "Jsondata": null
          }
        ],
        'DepartmentName': 'Finance',
        'departmentName': null,
        'SourceListNames': null,
        'sourceListNames': null,
        'sourceList': '1',
      },
    ],
    // depts 2–8 intentionally empty — all test cases are in dept 1
    // 2: [
    //   {
    //     'TemplateId': 6,
    //     'TemplateName': 'Daily MIS',
    //     'Department': '2',
    //     'Frequency': 'Daily',
    //     'NormalVolume': 1000,
    //     'PeakVolume': 2000,
    //     'SourceCount': 3,
    //     'BenefitType': 'Efficiency',
    //     'BenefitAmount': 6000,
    //     'BenefitInTat': '4 hours',
    //     'GoLiveDate': '2025-01-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Arjun Patel',
    //     'SpocManager': 'Suresh Nair',
    //     'UnitHead': 'Kavita Joshi',
    //     'Priority': 'High',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 2,
    //     'SourceList': '4,5,6',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Operations',
    //     'SourceListNames': 'Ops DB,Core DB,MIS DB',
    //   },
    //   {
    //     'TemplateId': 7,
    //     'TemplateName': 'Branch Performance',
    //     'Department': '2',
    //     'Frequency': 'Monthly',
    //     'NormalVolume': 300,
    //     'PeakVolume': 600,
    //     'SourceCount': 2,
    //     'BenefitType': 'Reporting',
    //     'BenefitAmount': 2500,
    //     'BenefitInTat': '2 days',
    //     'GoLiveDate': '2025-02-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Meena Iyer',
    //     'SpocManager': 'Suresh Nair',
    //     'UnitHead': 'Kavita Joshi',
    //     'Priority': 'Medium',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 1,
    //     'SourceList': '4,5',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Operations',
    //     'SourceListNames': 'Ops DB,Core DB',
    //   },
    //   {
    //     'TemplateId': 8,
    //     'TemplateName': 'Transaction Summary',
    //     'Department': '2',
    //     'Frequency': 'Daily',
    //     'NormalVolume': 5000,
    //     'PeakVolume': 8000,
    //     'SourceCount': 1,
    //     'BenefitType': 'Compliance',
    //     'BenefitAmount': 3500,
    //     'BenefitInTat': '1 hour',
    //     'GoLiveDate': '2025-01-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Arjun Patel',
    //     'SpocManager': 'Suresh Nair',
    //     'UnitHead': 'Kavita Joshi',
    //     'Priority': 'High',
    //     'TemplateType': '1 - Static',
    //     'NumberOfOutputs': null,
    //     'SourceList': '4',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'BCU Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Operations',
    //     'SourceListNames': 'Ops DB',
    //   },
    //   {
    //     'TemplateId': 9,
    //     'TemplateName': 'SLA Report',
    //     'Department': '2',
    //     'Frequency': 'Weekly',
    //     'NormalVolume': 200,
    //     'PeakVolume': 400,
    //     'SourceCount': 2,
    //     'BenefitType': 'Efficiency',
    //     'BenefitAmount': 2000,
    //     'BenefitInTat': '1 day',
    //     'GoLiveDate': '2025-03-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Meena Iyer',
    //     'SpocManager': 'Suresh Nair',
    //     'UnitHead': 'Kavita Joshi',
    //     'Priority': 'Medium',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 1,
    //     'SourceList': '4,6',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Operations',
    //     'SourceListNames': 'Ops DB,MIS DB',
    //   },
    // ],
    // 3: [
    //   // Marketing
    //   {
    //     'TemplateId': 10,
    //     'TemplateName': 'Campaign Report',
    //     'Department': '3',
    //     'Frequency': 'Weekly',
    //     'NormalVolume': 200,
    //     'PeakVolume': 400,
    //     'SourceCount': 2,
    //     'BenefitType': 'Revenue',
    //     'BenefitAmount': 8000,
    //     'BenefitInTat': '2 days',
    //     'GoLiveDate': '2025-01-15',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Ananya Roy',
    //     'SpocManager': 'Deepak Mishra',
    //     'UnitHead': 'Sunita Verma',
    //     'Priority': 'Medium',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 1,
    //     'SourceList': '7,8',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Marketing',
    //     'SourceListNames': 'CRM DB,Campaign DB',
    //   },
    //   {
    //     'TemplateId': 11,
    //     'TemplateName': 'Customer Segment',
    //     'Department': '3',
    //     'Frequency': 'Monthly',
    //     'NormalVolume': 500,
    //     'PeakVolume': 1000,
    //     'SourceCount': 3,
    //     'BenefitType': 'Revenue',
    //     'BenefitAmount': 12000,
    //     'BenefitInTat': '3 days',
    //     'GoLiveDate': '2025-02-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Ravi Shankar',
    //     'SpocManager': 'Deepak Mishra',
    //     'UnitHead': 'Sunita Verma',
    //     'Priority': 'High',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 2,
    //     'SourceList': '7,8,9',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'UAT Sign Off',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Marketing',
    //     'SourceListNames': 'CRM DB,Campaign DB,Analytics DB',
    //   },
    // ],
    // 4: [
    //   // IT
    //   {
    //     'TemplateId': 12,
    //     'TemplateName': 'System Health',
    //     'Department': '4',
    //     'Frequency': 'Daily',
    //     'NormalVolume': 500,
    //     'PeakVolume': 1000,
    //     'SourceCount': 2,
    //     'BenefitType': 'Efficiency',
    //     'BenefitAmount': 3000,
    //     'BenefitInTat': '1 hour',
    //     'GoLiveDate': '2025-01-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Kiran Desai',
    //     'SpocManager': 'Ashok Tiwari',
    //     'UnitHead': 'Ramesh Pillai',
    //     'Priority': 'High',
    //     'TemplateType': '1 - Static',
    //     'NumberOfOutputs': null,
    //     'SourceList': '10,11',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'IT',
    //     'SourceListNames': 'Server Logs,App Monitor',
    //   },
    //   {
    //     'TemplateId': 13,
    //     'TemplateName': 'API Metrics',
    //     'Department': '4',
    //     'Frequency': 'Daily',
    //     'NormalVolume': 2000,
    //     'PeakVolume': 5000,
    //     'SourceCount': 1,
    //     'BenefitType': 'Efficiency',
    //     'BenefitAmount': 2000,
    //     'BenefitInTat': '30 mins',
    //     'GoLiveDate': '2025-01-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Kiran Desai',
    //     'SpocManager': 'Ashok Tiwari',
    //     'UnitHead': 'Ramesh Pillai',
    //     'Priority': 'High',
    //     'TemplateType': '1 - Static',
    //     'NumberOfOutputs': null,
    //     'SourceList': '10',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'IT',
    //     'SourceListNames': 'Server Logs',
    //   },
    //   {
    //     'TemplateId': 14,
    //     'TemplateName': 'Uptime Report',
    //     'Department': '4',
    //     'Frequency': 'Weekly',
    //     'NormalVolume': 100,
    //     'PeakVolume': 200,
    //     'SourceCount': 1,
    //     'BenefitType': 'Compliance',
    //     'BenefitAmount': 1000,
    //     'BenefitInTat': '1 day',
    //     'GoLiveDate': '2025-01-15',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Nitin Kulkarni',
    //     'SpocManager': 'Ashok Tiwari',
    //     'UnitHead': 'Ramesh Pillai',
    //     'Priority': 'Low',
    //     'TemplateType': '1 - Static',
    //     'NumberOfOutputs': null,
    //     'SourceList': '11',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'IT',
    //     'SourceListNames': 'App Monitor',
    //   },
    // ],
    // 5: [
    //   // HR
    //   {
    //     'TemplateId': 15,
    //     'TemplateName': 'Headcount Report',
    //     'Department': '5',
    //     'Frequency': 'Monthly',
    //     'NormalVolume': 100,
    //     'PeakVolume': 200,
    //     'SourceCount': 2,
    //     'BenefitType': 'Efficiency',
    //     'BenefitAmount': 1500,
    //     'BenefitInTat': '2 days',
    //     'GoLiveDate': '2025-01-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Pooja Bhatt',
    //     'SpocManager': 'Girish Nanda',
    //     'UnitHead': 'Lakshmi Rao',
    //     'Priority': 'Medium',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 1,
    //     'SourceList': '12,13',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'HR',
    //     'SourceListNames': 'HRMS,Payroll DB',
    //   },
    //   {
    //     'TemplateId': 16,
    //     'TemplateName': 'Payroll Summary',
    //     'Department': '5',
    //     'Frequency': 'Monthly',
    //     'NormalVolume': 200,
    //     'PeakVolume': 400,
    //     'SourceCount': 2,
    //     'BenefitType': 'Compliance',
    //     'BenefitAmount': 2000,
    //     'BenefitInTat': '1 day',
    //     'GoLiveDate': '2025-02-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Pooja Bhatt',
    //     'SpocManager': 'Girish Nanda',
    //     'UnitHead': 'Lakshmi Rao',
    //     'Priority': 'High',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 2,
    //     'SourceList': '12,13',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'BCU Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'HR',
    //     'SourceListNames': 'HRMS,Payroll DB',
    //   },
    //   {
    //     'TemplateId': 17,
    //     'TemplateName': 'Attrition Report',
    //     'Department': '5',
    //     'Frequency': 'Quarterly',
    //     'NormalVolume': 50,
    //     'PeakVolume': 100,
    //     'SourceCount': 2,
    //     'BenefitType': 'Reporting',
    //     'BenefitAmount': 1000,
    //     'BenefitInTat': '3 days',
    //     'GoLiveDate': '2025-03-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Anjali Singh',
    //     'SpocManager': 'Girish Nanda',
    //     'UnitHead': 'Lakshmi Rao',
    //     'Priority': 'Medium',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 1,
    //     'SourceList': '12,13',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'HR',
    //     'SourceListNames': 'HRMS,Payroll DB',
    //   },
    // ],
    // 6: [
    //   // Risk
    //   {
    //     'TemplateId': 18,
    //     'TemplateName': 'NPA Report',
    //     'Department': '6',
    //     'Frequency': 'Monthly',
    //     'NormalVolume': 500,
    //     'PeakVolume': 1000,
    //     'SourceCount': 3,
    //     'BenefitType': 'Compliance',
    //     'BenefitAmount': 10000,
    //     'BenefitInTat': '2 days',
    //     'GoLiveDate': '2025-01-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Sameer Khan',
    //     'SpocManager': 'Rajesh Dubey',
    //     'UnitHead': 'Vandana Saxena',
    //     'Priority': 'High',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 2,
    //     'SourceList': '14,15,16',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'CCU Head Approval',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Risk',
    //     'SourceListNames': 'Loan DB,Risk DB,Collateral DB',
    //   },
    //   {
    //     'TemplateId': 19,
    //     'TemplateName': 'Exposure Report',
    //     'Department': '6',
    //     'Frequency': 'Weekly',
    //     'NormalVolume': 300,
    //     'PeakVolume': 600,
    //     'SourceCount': 2,
    //     'BenefitType': 'Compliance',
    //     'BenefitAmount': 7000,
    //     'BenefitInTat': '1 day',
    //     'GoLiveDate': '2025-02-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Sameer Khan',
    //     'SpocManager': 'Rajesh Dubey',
    //     'UnitHead': 'Vandana Saxena',
    //     'Priority': 'High',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 1,
    //     'SourceList': '14,15',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Risk',
    //     'SourceListNames': 'Loan DB,Risk DB',
    //   },
    // ],
    // 7: [
    //   // Compliance
    //   {
    //     'TemplateId': 20,
    //     'TemplateName': 'AML Report',
    //     'Department': '7',
    //     'Frequency': 'Daily',
    //     'NormalVolume': 1000,
    //     'PeakVolume': 2000,
    //     'SourceCount': 2,
    //     'BenefitType': 'Compliance',
    //     'BenefitAmount': 15000,
    //     'BenefitInTat': '2 hours',
    //     'GoLiveDate': '2025-01-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Farhaan Sheikh',
    //     'SpocManager': 'Nandini Kapoor',
    //     'UnitHead': 'Arun Menon',
    //     'Priority': 'High',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 1,
    //     'SourceList': '17,18',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Functional Head Approval',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Compliance',
    //     'SourceListNames': 'Transaction DB,AML Engine',
    //   },
    //   {
    //     'TemplateId': 21,
    //     'TemplateName': 'KYC Tracker',
    //     'Department': '7',
    //     'Frequency': 'Weekly',
    //     'NormalVolume': 500,
    //     'PeakVolume': 1000,
    //     'SourceCount': 2,
    //     'BenefitType': 'Compliance',
    //     'BenefitAmount': 8000,
    //     'BenefitInTat': '1 day',
    //     'GoLiveDate': '2025-01-15',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Farhaan Sheikh',
    //     'SpocManager': 'Nandini Kapoor',
    //     'UnitHead': 'Arun Menon',
    //     'Priority': 'High',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 1,
    //     'SourceList': '17,19',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'SMS Whitelisting',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Compliance',
    //     'SourceListNames': 'Transaction DB,KYC DB',
    //   },
    //   {
    //     'TemplateId': 22,
    //     'TemplateName': 'Audit Trail',
    //     'Department': '7',
    //     'Frequency': 'Daily',
    //     'NormalVolume': 2000,
    //     'PeakVolume': 4000,
    //     'SourceCount': 1,
    //     'BenefitType': 'Compliance',
    //     'BenefitAmount': 5000,
    //     'BenefitInTat': '1 hour',
    //     'GoLiveDate': '2025-01-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Preethi Nair',
    //     'SpocManager': 'Nandini Kapoor',
    //     'UnitHead': 'Arun Menon',
    //     'Priority': 'High',
    //     'TemplateType': '1 - Static',
    //     'NumberOfOutputs': null,
    //     'SourceList': '17',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Compliance',
    //     'SourceListNames': 'Transaction DB',
    //   },
    // ],
    // 8: [
    //   // Treasury
    //   {
    //     'TemplateId': 23,
    //     'TemplateName': 'Liquidity Report',
    //     'Department': '8',
    //     'Frequency': 'Daily',
    //     'NormalVolume': 300,
    //     'PeakVolume': 600,
    //     'SourceCount': 2,
    //     'BenefitType': 'Compliance',
    //     'BenefitAmount': 6000,
    //     'BenefitInTat': '2 hours',
    //     'GoLiveDate': '2025-01-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Vivek Oberoi',
    //     'SpocManager': 'Shilpa Doshi',
    //     'UnitHead': 'Manish Agarwal',
    //     'Priority': 'High',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 2,
    //     'SourceList': '20,21',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'CSV'},
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'BCU Head',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Treasury',
    //     'SourceListNames': 'Treasury DB,Liquidity Pool',
    //   },
    //   {
    //     'TemplateId': 24,
    //     'TemplateName': 'FX Exposure',
    //     'Department': '8',
    //     'Frequency': 'Weekly',
    //     'NormalVolume': 200,
    //     'PeakVolume': 400,
    //     'SourceCount': 3,
    //     'BenefitType': 'Revenue',
    //     'BenefitAmount': 9000,
    //     'BenefitInTat': '1 day',
    //     'GoLiveDate': '2025-02-01',
    //     'DeactivateDate': null,
    //     'SpocPerson': 'Vivek Oberoi',
    //     'SpocManager': 'Shilpa Doshi',
    //     'UnitHead': 'Manish Agarwal',
    //     'Priority': 'High',
    //     'TemplateType': '2 - Dynamic',
    //     'NumberOfOutputs': 1,
    //     'SourceList': '20,21,22',
    //     'OutputFormats': [
    //       {'TemplateTempId': null, 'FormatName': 'Excel'},
    //     ],
    //     'Approvals': [
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Unit Head',
    //         'ApprovalFile': ''
    //       },
    //       {
    //         'TemplateTempId': null,
    //         'Approval_Type': 'Functional Head Approval',
    //         'ApprovalFile': ''
    //       },
    //     ],
    //     'CreatedBy': 'admin',
    //     'jsonData': '',
    //     'DepartmentName': 'Treasury',
    //     'SourceListNames': 'Treasury DB,Liquidity Pool,FX DB',
    //   },
    // ],
    7: [
      {
        'templateType': '3',
        'templateId': 12,
        'templateName': '12 - tempa1',
        'department': null,
        'frequency': '1',
        'normalVolume': 0,
        'peakVolume': 0,
        'sourceCount': 2,
        'numberOfOutputs': 0,
        'benefitType': 0,
        'benefitAmount': 0,
        'benefitInTAT': null,
        'goLiveDate': null,
        'deactivateDate': null,
        'spocPerson': null,
        'spocManager': null,
        'unitHead': null,
        'priority': 0,
        'template': null,
        'outputFormats': [
          {'templateTempId': 12, 'formatName': 'Unimailing'},
        ],
        'approvals': null,
        'dynamicTemplate': [
          {
            'srno': 3,
            'id': 5,
            'sourceList': '1,2',
            'sourceCount': '2',
            'sourceListName': null,
            'templateId': 12,
            'sourceMasterList': [
              {
                'id': 1,
                'name': '1 - Manual',
                'sourceType': '1',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '7',
                'type': '3',
                'template_id': null,
                'typeId': '1',
              },
              {
                'id': 2,
                'name': '2 - IHA Application',
                'sourceType': '2',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '7',
                'type': '3',
                'template_id': null,
                'typeId': '2',
              },
            ],
            'sourceType': '3',
          },
          {
            'srno': 0,
            'id': 0,
            'sourceList': '1,2',
            'sourceCount': '2',
            'sourceListName': null,
            'templateId': 12,
            'sourceMasterList': [],
            'sourceType': '1',
          },
        ],
        'jsonData': null,
        'departmentName': null,
        'sourceListNames': null,
        'sourceList': '1,2',
      },
      {
        'templateType': '3',
        'templateId': 9,
        'templateName': '9 - template dynnic',
        'department': null,
        'frequency': '1',
        'normalVolume': 0,
        'peakVolume': 0,
        'sourceCount': 2,
        'numberOfOutputs': 0,
        'benefitType': 0,
        'benefitAmount': 0,
        'benefitInTAT': null,
        'goLiveDate': null,
        'deactivateDate': null,
        'spocPerson': null,
        'spocManager': null,
        'unitHead': null,
        'priority': 0,
        'template': null,
        'outputFormats': [
          {'templateTempId': 9, 'formatName': 'Unimailing'},
        ],
        'approvals': null,
        'dynamicTemplate': [
          {
            'srno': 1,
            'id': 3,
            'sourceList': '1',
            'sourceCount': '2',
            'sourceListName': null,
            'templateId': 9,
            'sourceMasterList': [
              {
                'id': 1,
                'name': '1 - Manual',
                'sourceType': '1',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '7',
                'type': '3',
                'template_id': null,
                'typeId': '1',
              },
              {
                'id': 1,
                'name': '1 - Manual',
                'sourceType': '1',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '7',
                'type': '3',
                'template_id': null,
                'typeId': '1',
              },
              {
                'id': 3,
                'name': '3 - Flexcube',
                'sourceType': '3',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '7',
                'type': '3',
                'template_id': null,
                'typeId': '3',
              },
            ],
            'sourceType': '3',
          },
          {
            'srno': 2,
            'id': 4,
            'sourceList': '1,3',
            'sourceCount': '2',
            'sourceListName': null,
            'templateId': 9,
            'sourceMasterList': [
              {
                'id': 1,
                'name': '1 - Manual',
                'sourceType': '1',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '7',
                'type': '3',
                'template_id': null,
                'typeId': '1',
              },
              {
                'id': 1,
                'name': '1 - Manual',
                'sourceType': '1',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '7',
                'type': '3',
                'template_id': null,
                'typeId': '1',
              },
              {
                'id': 3,
                'name': '3 - Flexcube',
                'sourceType': '3',
                'appName': null,
                'itgrc': 0,
                'dbVault': null,
                'createdBy': null,
                'createdOn': '0001-01-01T00:00:00',
                'svalues': null,
                'department_id': '7',
                'type': '3',
                'template_id': null,
                'typeId': '3',
              },
            ],
            'sourceType': '3',
          },
          {
            'srno': 0,
            'id': 0,
            'sourceList': '1',
            'sourceCount': '2',
            'sourceListName': null,
            'templateId': 9,
            'sourceMasterList': [],
            'sourceType': '1',
          },
        ],
        'jsonData': null,
        'departmentName': null,
        'sourceListNames': null,
        'sourceList': '1',
      },
      {
        'templateType': '2',
        'templateId': 3,
        'templateName': '3 - template 1 static',
        'department': null,
        'frequency': '1',
        'normalVolume': 0,
        'peakVolume': 0,
        'sourceCount': 2,
        'numberOfOutputs': 0,
        'benefitType': 0,
        'benefitAmount': 0,
        'benefitInTAT': null,
        'goLiveDate': null,
        'deactivateDate': null,
        'spocPerson': null,
        'spocManager': null,
        'unitHead': null,
        'priority': 0,
        'template': null,
        'outputFormats': [
          {'templateTempId': 3, 'formatName': 'Unimailing'},
        ],
        'approvals': null,
        'dynamicTemplate': [
          {
            'srno': 0,
            'id': 0,
            'sourceList': '1,2',
            'sourceCount': '2',
            'sourceListName': null,
            'templateId': 3,
            'sourceMasterList': [],
            'sourceType': '1',
          },
        ],
        'jsonData': null,
        'departmentName': null,
        'sourceListNames': null,
        'sourceList': '1,2',
      },
    ],
  };

  // ── Source Types ──
  final List<Map<String, dynamic>> sourceTypes = [
    {'id': 1, 'sourceName': '1 - Manual', 'sourceValue': 'manual'},
    {
      'id': 2,
      'sourceName': '2 - IHA Application',
      'sourceValue': 'iha application'
    },
    {'id': 3, 'sourceName': '3 - Flexcube', 'sourceValue': 'flexcube'},
    {'id': 4, 'sourceName': '4 - Finone', 'sourceValue': 'finone'},
  ];

  // ── Operations ──
  final List<Map<String, dynamic>> operations = [
    {
      "id": 2,
      "operationName": "2 - Matches only",
      "operationValue": "inner_join"
    },
    {"id": 4, "operationName": "4 - All", "operationValue": "union"},
    {"id": 5, "operationName": "5 - Exists in list", "operationValue": "in"}
  ];

  // ── Approval List ──
  final List<Map<String, dynamic>> approvalList = [
    {
      'id': 5,
      'approvalName': 'QUERY OPS SIGN OFF ',
      'createdBy': 'Admin',
      'createdOn': '0001-01-01T00:00:00',
    },
    {
      'id': 6,
      'approvalName': 'UH APPROVAL',
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
