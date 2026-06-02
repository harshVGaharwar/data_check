import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/io_client.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only GET allowed').toJson(),
    );
  }

  final params = context.request.uri.queryParameters;
  final deptId = params['DeptId'] ?? '';
  final flag = int.tryParse(params['flag'] ?? '') ?? 0;

  if (deptId.isEmpty || (flag != 4 && flag != 5)) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(
        message: 'DeptId and flag (4 or 5) are required',
      ).toJson(),
    );
  }

  if (kDevMode) {
    // All mock rows — filtered by deptId before returning.
    // flag=4 → Template Creation, flag=5 → Template Configuration
    final allRows = <Map<String, dynamic>>[
      // ── RETAIL ASSETS (deptId=7) ─────────────────────────────────────────
      if (flag == 4) ...[
        {
          'templateId': '108',
          'departmentId': '7',
          'templateName': 'test static',
          'departmentName': 'RETAIL ASSETS',
          'makerBy': 'J3216',
          'makerDate': '27/05/2026 2:40:39 PM',
          'jsonData': jsonEncode({
            'TemplateType': '1',
            'Template': [
              {
                'TemplateName': 'test static',
                'Department': '7',
                'Frequency': 'Daily',
                'NormalVolume': 100000,
                'PeakVolume': 100000000,
                'SourceCount': 2,
                'BenefitType': 'Cost Saving',
                'BenefitAmount': 1000000,
                'BenefitInTat': '1000000000',
                'GoLiveDate': '2026-05-27',
                'DeactivateDate': '2026-05-31',
                'SpocPerson': 'test',
                'SpocManager': 'test',
                'UnitHead': 'test',
                'Priority': 'Low',
                'NumberOfOutputs': null,
                'SourceList': '1',
              },
            ],
            'OutputFormats': [
              {'TemplateTempId': null, 'FormatName': 'User Defined'},
            ],
            'Approvals': [
              {
                'TemplateTempId': null,
                'Approval_Type': 'UAT test',
                'ApprovalFile': 'uatApproval.pdf',
              },
            ],
            'CreatedBy': 'J3216',
            'jsonData': '',
            'DepartmentName': 'RETAIL ASSETS',
            'SourceListNames': 'Manual',
            'DynamicTemplate': [],
          }),
        },
        {
          'templateId': '107',
          'departmentId': '7',
          'templateName': 'dynamci+uni',
          'departmentName': 'RETAIL ASSETS',
          'makerBy': 'J3216',
          'makerDate': '25/05/2026 6:36:56 PM',
          'jsonData': jsonEncode({
            'TemplateType': '3',
            'TemplateTypeName': '2-Dynamic',
            'Template': [
              {
                'TemplateName': 'dynamci+uni',
                'Department': '7',
                'Frequency': 'Monthly',
                'NormalVolume': 1,
                'PeakVolume': 1,
                'SourceCount': 3,
                'BenefitType': 'Revenue Generation',
                'BenefitAmount': 2,
                'BenefitInTat': '2',
                'GoLiveDate': '2026-05-25',
                'DeactivateDate': '2026-05-27',
                'SpocPerson': 'sdds',
                'SpocManager': 's',
                'UnitHead': 's',
                'Priority': 'Medium',
                'NumberOfOutputs': 2,
                'SourceList': '1',
              },
            ],
            'OutputFormats': [
              {'TemplateTempId': null, 'FormatName': 'Unimailing'},
            ],
            'Approvals': [
              {
                'TemplateTempId': null,
                'Approval_Type': 'UAT test',
                'ApprovalFile': 'image (4).png',
              },
            ],
            'CreatedBy': 'J3216',
            'jsonData': '',
            'DepartmentName': 'RETAIL ASSETS',
            'SourceListNames': 'Manual',
            'SourceCount': '3',
            'SourceType': '1',
            'DynamicTemplate': [
              {
                'SourceList': '1',
                'SourceListNames': 'Manual',
                'SourceCount': '2',
                'SourceType': '3',
              },
              {
                'SourceList': '1,2',
                'SourceListNames': 'Manual,QDRS',
                'SourceCount': '2',
                'SourceType': '3',
              },
              {
                'SourceList': '1,2',
                'SourceListNames': 'Manual,QDRS',
                'SourceCount': '2',
                'SourceType': '3',
              },
            ],
          }),
        },
      ],
      // ── flag=5: Template Configuration — jsonData is a List directly ───────
      if (flag == 5) ...[
        // RETAIL ASSETS (deptId=7)
        {
          'templateId': '105',
          'departmentId': '7',
          'templateName': 'Test Temp',
          'departmentName': 'RETAIL ASSETS',
          'makerBy': 'J3216',
          'makerDate': '01/06/2026 12:01:08 PM',
          'jsonData': [
            {
              'TemplateId': 105,
              'TemplateType': 3,
              'DymanicId': 0,
              'createdBy': 'J3216',
              'templateMode': 0,
              'Sources': [
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's1',
                  'SourceType': '1',
                  'Department': '7',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '1',
                  'uniqueField': ''
                },
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's3',
                  'SourceType': '1',
                  'Department': '7',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '2',
                  'uniqueField': ''
                },
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's3',
                  'SourceType': '1',
                  'Department': '7',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': 'valid_columns.csv',
                  'Columns':
                      'customer_id, first_name, last_name, email, phone, city, state, pincode',
                  'SelectedColumns': '',
                  'SourceSeqNo': '3',
                  'uniqueField': ''
                },
              ],
              'JoinMappings': [
                {
                  'Id': 0,
                  'TemplateId': 105,
                  'Department': '7',
                  'JoinNodeId': 'n4',
                  'LeftSourceId': 'n1',
                  'LeftSourceName': 's1',
                  'LeftColumn': 'orderName',
                  'JoinType': 'inner_join',
                  'RightSourceId': 'n2',
                  'RightSourceName': 's3',
                  'RightColumn': 'orderName',
                  'CreatedOn': '2026-06-01T00:00:00'
                },
              ],
              'Edges': [
                {
                  'template_id': 105,
                  'department': '7',
                  'From': 'n1',
                  'To': 'n4'
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'From': 'n2',
                  'To': 'n4'
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'From': 'n3',
                  'To': 'n4'
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'From': 'n4',
                  'To': 'n8'
                },
              ],
              'connectedSources': [
                {
                  'TemplateId': 105,
                  'Department': '7',
                  'JoinNodeId': 'n4',
                  'SourceId': 'n1'
                },
                {
                  'TemplateId': 105,
                  'Department': '7',
                  'JoinNodeId': 'n4',
                  'SourceId': 'n2'
                },
                {
                  'TemplateId': 105,
                  'Department': '7',
                  'JoinNodeId': 'n4',
                  'SourceId': 'n3'
                },
              ],
              'outputColumns': [
                {
                  'template_id': 105,
                  'department': '7',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Mail To',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Mail CC',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Mail BCC',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Subject',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Attachment',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'SMS To',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Barcode',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'sourceid': '1',
                  'sourceName': 's2',
                  'SourceColName': 'orderName',
                  'ColumnName': 'C1',
                  'Priority': 0
                },
              ],
              'Jsondata': null,
            },
            {
              'TemplateId': 105,
              'TemplateType': 3,
              'DymanicId': 6,
              'createdBy': 'J3216',
              'templateMode': 0,
              'Sources': [
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's2',
                  'SourceType': '1',
                  'Department': '7',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '1',
                  'uniqueField': ''
                },
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's2',
                  'SourceType': '1',
                  'Department': '7',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '2',
                  'uniqueField': ''
                },
              ],
              'JoinMappings': [
                {
                  'Id': 0,
                  'TemplateId': 105,
                  'Department': '7',
                  'JoinNodeId': 'n3',
                  'LeftSourceId': 'n1',
                  'LeftSourceName': 's2',
                  'LeftColumn': 'orderCity',
                  'JoinType': 'inner_join',
                  'RightSourceId': 'n2',
                  'RightSourceName': 's2',
                  'RightColumn': 'orderID',
                  'CreatedOn': '2026-06-01T00:00:00'
                },
              ],
              'Edges': [
                {
                  'template_id': 105,
                  'department': '7',
                  'From': 'n1',
                  'To': 'n3'
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'From': 'n2',
                  'To': 'n3'
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'From': 'n3',
                  'To': 'n6'
                },
              ],
              'connectedSources': [
                {
                  'TemplateId': 105,
                  'Department': '7',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n1'
                },
                {
                  'TemplateId': 105,
                  'Department': '7',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n2'
                },
              ],
              'outputColumns': [
                {
                  'template_id': 105,
                  'department': '7',
                  'sourceid': '1',
                  'sourceName': 's2',
                  'SourceColName': 'orderName',
                  'ColumnName': 'C1',
                  'Priority': 0
                },
              ],
              'Jsondata': null,
            },
            {
              'TemplateId': 105,
              'TemplateType': 3,
              'DymanicId': 7,
              'createdBy': 'J3216',
              'templateMode': 0,
              'Sources': [
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's2',
                  'SourceType': '1',
                  'Department': '7',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '1',
                  'uniqueField': ''
                },
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's3',
                  'SourceType': '1',
                  'Department': '7',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '2',
                  'uniqueField': ''
                },
              ],
              'JoinMappings': [
                {
                  'Id': 0,
                  'TemplateId': 105,
                  'Department': '7',
                  'JoinNodeId': 'n3',
                  'LeftSourceId': 'n1',
                  'LeftSourceName': 's2',
                  'LeftColumn': 'orderName',
                  'JoinType': 'inner_join',
                  'RightSourceId': 'n2',
                  'RightSourceName': 's3',
                  'RightColumn': 'orderName',
                  'CreatedOn': '2026-06-01T00:00:00'
                },
              ],
              'Edges': [
                {
                  'template_id': 105,
                  'department': '7',
                  'From': 'n1',
                  'To': 'n3'
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'From': 'n2',
                  'To': 'n3'
                },
                {
                  'template_id': 105,
                  'department': '7',
                  'From': 'n3',
                  'To': 'n6'
                },
              ],
              'connectedSources': [
                {
                  'TemplateId': 105,
                  'Department': '7',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n1'
                },
                {
                  'TemplateId': 105,
                  'Department': '7',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n2'
                },
              ],
              'outputColumns': [
                {
                  'template_id': 105,
                  'department': '7',
                  'sourceid': '1',
                  'sourceName': 's2',
                  'SourceColName': 'orderName',
                  'ColumnName': 'C1',
                  'Priority': 0
                },
              ],
              'Jsondata': null,
            },
          ],
        },
        {
          'templateId': '115',
          'departmentId': '7',
          'templateName': 'Static Uni',
          'departmentName': 'RETAIL ASSETS',
          'makerBy': 'J3216',
          'makerDate': '01/06/2026 1:09:27 PM',
          'jsonData': [
            {
              'TemplateId': 115,
              'TemplateType': 2,
              'DymanicId': 0,
              'createdBy': 'J3216',
              'templateMode': 0,
              'Sources': [
                {
                  'TemplateId': 115,
                  'SourceId': '1',
                  'SourceName': 'Customer',
                  'SourceType': '1',
                  'Department': '7',
                  'Template': '115 - Static Uni',
                  'Separator': ',',
                  'ColumnFile': 'customers_csv.csv',
                  'QueryFile': '',
                  'Columns': 'ID,NAME',
                  'SelectedColumns': 'ID',
                  'uniqueField': ''
                },
                {
                  'TemplateId': 115,
                  'SourceId': '1',
                  'SourceName': 'Products',
                  'SourceType': '1',
                  'Department': '7',
                  'Template': '115 - Static Uni',
                  'Separator': ',',
                  'ColumnFile': 'products_csv.csv',
                  'QueryFile': '',
                  'Columns': 'id,product_name,category,price',
                  'SelectedColumns': 'product_name',
                  'SourceSeqNo': '2'
                },
              ],
              'JoinMappings': [
                {
                  'Id': 0,
                  'TemplateId': 115,
                  'Department': '7',
                  'JoinNodeId': 'n3',
                  'LeftSourceId': 'n1',
                  'LeftSourceName': 'Customer',
                  'LeftColumn': 'ID',
                  'JoinType': 'inner_join',
                  'RightSourceId': 'n2',
                  'RightSourceName': 'Products',
                  'RightColumn': 'ID',
                  'CreatedOn': '2026-06-01T00:00:00'
                },
              ],
              'Edges': [
                {
                  'template_id': 115,
                  'department': '7',
                  'From': 'n1',
                  'To': 'n3'
                },
                {
                  'template_id': 115,
                  'department': '7',
                  'From': 'n3',
                  'To': 'n6'
                },
              ],
              'connectedSources': [
                {
                  'TemplateId': 115,
                  'Department': '7',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n1'
                },
                {
                  'TemplateId': 115,
                  'Department': '7',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n2'
                },
              ],
              'outputColumns': [
                {
                  'template_id': 115,
                  'department': '7',
                  'sourceId': '1',
                  'sourceName': 'Customer',
                  'SourceColName': 'ID',
                  'ColumnName': 'Mail To',
                  'Priority': 0
                },
                {
                  'template_id': 115,
                  'department': '7',
                  'sourceId': '1',
                  'sourceName': 'Products',
                  'SourceColName': 'product_name',
                  'ColumnName': 'Mail CC',
                  'Priority': 0
                },
                {
                  'template_id': 115,
                  'department': '7',
                  'sourceId': '1',
                  'sourceName': 'Customer',
                  'SourceColName': 'ID',
                  'ColumnName': 'Subject',
                  'Priority': 0
                },
                {
                  'template_id': 115,
                  'department': '7',
                  'sourceId': '1',
                  'sourceName': 'Customer',
                  'SourceColName': 'ID',
                  'ColumnName': 'Mail BCC',
                  'Priority': 0
                },
                {
                  'template_id': 115,
                  'department': '7',
                  'sourceId': '1',
                  'sourceName': 'Customer',
                  'SourceColName': 'ID',
                  'ColumnName': 'Attachment',
                  'Priority': 0
                },
                {
                  'template_id': 115,
                  'department': '7',
                  'sourceId': '1',
                  'sourceName': 'Customer',
                  'SourceColName': 'ID',
                  'ColumnName': 'SMS To',
                  'Priority': 0
                },
                {
                  'template_id': 115,
                  'department': '7',
                  'sourceId': '1',
                  'sourceName': 'Products',
                  'SourceColName': 'product_name',
                  'ColumnName': 'Barcode',
                  'Priority': 0
                },
              ],
              'Jsondata': null,
            },
          ],
        },
        // Finance (deptId=1) — full 3-entry structure matching exact API response
        {
          'templateId': '105',
          'departmentId': '1',
          'templateName': 'Test Temp',
          'departmentName': 'Finance',
          'makerBy': 'J3216',
          'makerDate': '01/06/2026 12:01:08 PM',
          'jsonData': [
            {
              'TemplateId': 105,
              'TemplateType': 3,
              'DymanicId': 0,
              'createdBy': 'J3216',
              'templateMode': 0,
              'Sources': [
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's1',
                  'SourceType': '1',
                  'Department': '1',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '1',
                  'uniqueField': ''
                },
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's3',
                  'SourceType': '1',
                  'Department': '1',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '2',
                  'uniqueField': ''
                },
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's3',
                  'SourceType': '1',
                  'Department': '1',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': 'valid_columns.csv',
                  'Columns':
                      'customer_id, first_name, last_name, email, phone, city, state, pincode',
                  'SelectedColumns': '',
                  'SourceSeqNo': '3',
                  'uniqueField': ''
                },
              ],
              'JoinMappings': [
                {
                  'Id': 0,
                  'TemplateId': 105,
                  'Department': '1',
                  'JoinNodeId': 'n4',
                  'LeftSourceId': 'n1',
                  'LeftSourceName': 's1',
                  'LeftColumn': 'orderName',
                  'JoinType': 'inner_join',
                  'RightSourceId': 'n2',
                  'RightSourceName': 's3',
                  'RightColumn': 'orderName',
                  'CreatedOn': '2026-06-01T00:00:00'
                },
              ],
              'Edges': [
                {
                  'template_id': 105,
                  'department': '1',
                  'From': 'n1',
                  'To': 'n4'
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'From': 'n2',
                  'To': 'n4'
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'From': 'n3',
                  'To': 'n4'
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'From': 'n4',
                  'To': 'n8'
                },
              ],
              'connectedSources': [
                {
                  'TemplateId': 105,
                  'Department': '1',
                  'JoinNodeId': 'n4',
                  'SourceId': 'n1'
                },
                {
                  'TemplateId': 105,
                  'Department': '1',
                  'JoinNodeId': 'n4',
                  'SourceId': 'n2'
                },
                {
                  'TemplateId': 105,
                  'Department': '1',
                  'JoinNodeId': 'n4',
                  'SourceId': 'n3'
                },
              ],
              'outputColumns': [
                {
                  'template_id': 105,
                  'department': '1',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Mail To',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Mail CC',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Mail BCC',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Subject',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Attachment',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'SMS To',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'sourceid': '1',
                  'sourceName': 's1',
                  'SourceColName': 'orderName',
                  'ColumnName': 'Barcode',
                  'Priority': 0
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'sourceid': '1',
                  'sourceName': 's2',
                  'SourceColName': 'orderName',
                  'ColumnName': 'C1',
                  'Priority': 0
                },
              ],
              'Jsondata': null,
            },
            {
              'TemplateId': 105,
              'TemplateType': 3,
              'DymanicId': 6,
              'createdBy': 'J3216',
              'templateMode': 0,
              'Sources': [
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's2',
                  'SourceType': '1',
                  'Department': '1',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '1',
                  'uniqueField': ''
                },
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's2',
                  'SourceType': '1',
                  'Department': '1',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '2',
                  'uniqueField': ''
                },
              ],
              'JoinMappings': [
                {
                  'Id': 0,
                  'TemplateId': 105,
                  'Department': '1',
                  'JoinNodeId': 'n3',
                  'LeftSourceId': 'n1',
                  'LeftSourceName': 's2',
                  'LeftColumn': 'orderCity',
                  'JoinType': 'inner_join',
                  'RightSourceId': 'n2',
                  'RightSourceName': 's2',
                  'RightColumn': 'orderID',
                  'CreatedOn': '2026-06-01T00:00:00'
                },
              ],
              'Edges': [
                {
                  'template_id': 105,
                  'department': '1',
                  'From': 'n1',
                  'To': 'n3'
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'From': 'n2',
                  'To': 'n3'
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'From': 'n3',
                  'To': 'n6'
                },
              ],
              'connectedSources': [
                {
                  'TemplateId': 105,
                  'Department': '1',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n1'
                },
                {
                  'TemplateId': 105,
                  'Department': '1',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n2'
                },
              ],
              'outputColumns': [
                {
                  'template_id': 105,
                  'department': '1',
                  'sourceid': '1',
                  'sourceName': 's2',
                  'SourceColName': 'orderName',
                  'ColumnName': 'C1',
                  'Priority': 0
                },
              ],
              'Jsondata': null,
            },
            {
              'TemplateId': 105,
              'TemplateType': 3,
              'DymanicId': 7,
              'createdBy': 'J3216',
              'templateMode': 0,
              'Sources': [
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's2',
                  'SourceType': '1',
                  'Department': '1',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '1',
                  'uniqueField': ''
                },
                {
                  'TemplateId': 105,
                  'SourceId': '1',
                  'SourceName': 's3',
                  'SourceType': '1',
                  'Department': '1',
                  'Template': '105 - Test Temp',
                  'Separator': '',
                  'ColumnFile': 'columnfile1.txt',
                  'QueryFile': '',
                  'Columns': 'orderID, orderName, orderCity',
                  'SelectedColumns': '',
                  'SourceSeqNo': '2',
                  'uniqueField': ''
                },
              ],
              'JoinMappings': [
                {
                  'Id': 0,
                  'TemplateId': 105,
                  'Department': '1',
                  'JoinNodeId': 'n3',
                  'LeftSourceId': 'n1',
                  'LeftSourceName': 's2',
                  'LeftColumn': 'orderName',
                  'JoinType': 'inner_join',
                  'RightSourceId': 'n2',
                  'RightSourceName': 's3',
                  'RightColumn': 'orderName',
                  'CreatedOn': '2026-06-01T00:00:00'
                },
              ],
              'Edges': [
                {
                  'template_id': 105,
                  'department': '1',
                  'From': 'n1',
                  'To': 'n3'
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'From': 'n2',
                  'To': 'n3'
                },
                {
                  'template_id': 105,
                  'department': '1',
                  'From': 'n3',
                  'To': 'n6'
                },
              ],
              'connectedSources': [
                {
                  'TemplateId': 105,
                  'Department': '1',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n1'
                },
                {
                  'TemplateId': 105,
                  'Department': '1',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n2'
                },
              ],
              'outputColumns': [
                {
                  'template_id': 105,
                  'department': '1',
                  'sourceid': '1',
                  'sourceName': 's2',
                  'SourceColName': 'orderName',
                  'ColumnName': 'C1',
                  'Priority': 0
                },
              ],
              'Jsondata': null,
            },
          ],
        },
        {
          'templateId': '115',
          'departmentId': '1',
          'templateName': 'Static Uni',
          'departmentName': 'Finance',
          'makerBy': 'J3216',
          'makerDate': '01/06/2026 1:09:27 PM',
          'jsonData': [
            {
              'TemplateId': 115,
              'TemplateType': 2,
              'DymanicId': 0,
              'createdBy': 'J3216',
              'templateMode': 0,
              'Sources': [
                {
                  'TemplateId': 115,
                  'SourceId': '1',
                  'SourceName': 'Customer',
                  'SourceType': '1',
                  'Department': '1',
                  'Template': '115 - Static Uni',
                  'Separator': ',',
                  'ColumnFile': 'customers_csv.csv',
                  'QueryFile': '',
                  'Columns': 'ID,NAME',
                  'SelectedColumns': 'ID',
                  'uniqueField': ''
                },
                {
                  'TemplateId': 115,
                  'SourceId': '1',
                  'SourceName': 'Products',
                  'SourceType': '1',
                  'Department': '1',
                  'Template': '115 - Static Uni',
                  'Separator': ',',
                  'ColumnFile': 'products_csv.csv',
                  'QueryFile': '',
                  'Columns': 'id,product_name,category,price',
                  'SelectedColumns': 'product_name',
                  'SourceSeqNo': '2'
                },
              ],
              'JoinMappings': [
                {
                  'Id': 0,
                  'TemplateId': 115,
                  'Department': '1',
                  'JoinNodeId': 'n3',
                  'LeftSourceId': 'n1',
                  'LeftSourceName': 'Customer',
                  'LeftColumn': 'ID',
                  'JoinType': 'inner_join',
                  'RightSourceId': 'n2',
                  'RightSourceName': 'Products',
                  'RightColumn': 'ID',
                  'CreatedOn': '2026-06-01T00:00:00'
                },
              ],
              'Edges': [
                {
                  'template_id': 115,
                  'department': '1',
                  'From': 'n1',
                  'To': 'n3'
                },
                {
                  'template_id': 115,
                  'department': '1',
                  'From': 'n3',
                  'To': 'n6'
                },
              ],
              'connectedSources': [
                {
                  'TemplateId': 115,
                  'Department': '1',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n1'
                },
                {
                  'TemplateId': 115,
                  'Department': '1',
                  'JoinNodeId': 'n3',
                  'SourceId': 'n2'
                },
              ],
              'outputColumns': [
                {
                  'template_id': 115,
                  'department': '1',
                  'sourceId': '1',
                  'sourceName': 'Customer',
                  'SourceColName': 'ID',
                  'ColumnName': 'Mail To',
                  'Priority': 0
                },
                {
                  'template_id': 115,
                  'department': '1',
                  'sourceId': '1',
                  'sourceName': 'Products',
                  'SourceColName': 'product_name',
                  'ColumnName': 'Mail CC',
                  'Priority': 0
                },
                {
                  'template_id': 115,
                  'department': '1',
                  'sourceId': '1',
                  'sourceName': 'Customer',
                  'SourceColName': 'ID',
                  'ColumnName': 'Subject',
                  'Priority': 0
                },
              ],
              'Jsondata': null,
            },
          ],
        },
      ],
    ];

    // Mock returns raw rows directly — jsonData is already a List, no processing needed.
    final filtered =
        allRows.where((r) => r['departmentId'].toString() == deptId).toList();
    return Response.json(body: filtered);
  }

  // Production: forward to external API
  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final externalResponse = await client.get(
      Uri.parse(
        '$kBaseUrl${ExternalApi.getTemplateCheckerTray}?DeptId=$deptId&flag=$flag',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authHeader.isNotEmpty) 'Authorization': authHeader,
      },
    ).timeout(const Duration(seconds: 30));

    print('[TEMPLATE CHECKER TRAY] External API status: '
        '${externalResponse.statusCode}');

    if (externalResponse.statusCode >= 200 &&
        externalResponse.statusCode < 300) {
      final decoded = jsonDecode(externalResponse.body);
      final data =
          (decoded is Map<String, dynamic> && decoded.containsKey('data'))
              ? decoded['data']
              : decoded;

      if (data is List) {
        final items = data
            .whereType<Map>()
            .map((item) => TemplateCheckerTrayItem.fromMap(
                  item.map((k, v) => MapEntry(k.toString(), v)),
                ).toJson())
            .toList(growable: false);
        return Response.json(body: items);
      }
      return Response.json(body: data);
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(
        message: 'Failed to fetch template checker tray',
      ).toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'Template checker tray service unavailable: $e',
      ).toJson(),
    );
  }
}
