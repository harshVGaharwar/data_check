// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/index.dart' as index;
import '../routes/api/v1/templates/[id].dart' as api_v1_templates_$id;
import '../routes/api/v1/template/UploadManualDataChecker.dart' as api_v1_template_upload_manual_data_checker;
import '../routes/api/v1/template/UploadManualData.dart' as api_v1_template_upload_manual_data;
import '../routes/api/v1/template/GetTemplates.dart' as api_v1_template_get_templates;
import '../routes/api/v1/template/GetSourceType.dart' as api_v1_template_get_source_type;
import '../routes/api/v1/template/GetSourceMasterListFilterwise.dart' as api_v1_template_get_source_master_list_filterwise;
import '../routes/api/v1/template/GetSourceMasterList.dart' as api_v1_template_get_source_master_list;
import '../routes/api/v1/template/GetSourceList.dart' as api_v1_template_get_source_list;
import '../routes/api/v1/template/GetOperations.dart' as api_v1_template_get_operations;
import '../routes/api/v1/template/GetManualTemplateDetails.dart' as api_v1_template_get_manual_template_details;
import '../routes/api/v1/template/GetDepartment.dart' as api_v1_template_get_department;
import '../routes/api/v1/template/GetCheckerTayList.dart' as api_v1_template_get_checker_tay_list;
import '../routes/api/v1/template/GetApprovalList.dart' as api_v1_template_get_approval_list;
import '../routes/api/v1/template/DownloadFile.dart' as api_v1_template_download_file;
import '../routes/api/v1/template/AddTemplateConfig.dart' as api_v1_template_add_template_config;
import '../routes/api/v1/template/AddTemplate.dart' as api_v1_template_add_template;
import '../routes/api/v1/template/AddSourceMasterList.dart' as api_v1_template_add_source_master_list;
import '../routes/api/v1/pipeline/save-sources.dart' as api_v1_pipeline_save_sources;
import '../routes/api/v1/master/approval-list.dart' as api_v1_master_approval_list;
import '../routes/api/v1/auth/logout.dart' as api_v1_auth_logout;
import '../routes/api/v1/account/refresh.dart' as api_v1_account_refresh;
import '../routes/api/v1/account/login.dart' as api_v1_account_login;

import '../routes/_middleware.dart' as middleware;

void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/', (context) => buildHandler()(context))
    ..mount('/api/v1/templates', (context) => buildApiV1TemplatesHandler()(context))
    ..mount('/api/v1/template', (context) => buildApiV1TemplateHandler()(context))
    ..mount('/api/v1/pipeline', (context) => buildApiV1PipelineHandler()(context))
    ..mount('/api/v1/master', (context) => buildApiV1MasterHandler()(context))
    ..mount('/api/v1/auth', (context) => buildApiV1AuthHandler()(context))
    ..mount('/api/v1/account', (context) => buildApiV1AccountHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiV1TemplatesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => api_v1_templates_$id.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildApiV1TemplateHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/AddSourceMasterList', (context) => api_v1_template_add_source_master_list.onRequest(context,))..all('/AddTemplate', (context) => api_v1_template_add_template.onRequest(context,))..all('/AddTemplateConfig', (context) => api_v1_template_add_template_config.onRequest(context,))..all('/DownloadFile', (context) => api_v1_template_download_file.onRequest(context,))..all('/GetApprovalList', (context) => api_v1_template_get_approval_list.onRequest(context,))..all('/GetCheckerTayList', (context) => api_v1_template_get_checker_tay_list.onRequest(context,))..all('/GetDepartment', (context) => api_v1_template_get_department.onRequest(context,))..all('/GetManualTemplateDetails', (context) => api_v1_template_get_manual_template_details.onRequest(context,))..all('/GetOperations', (context) => api_v1_template_get_operations.onRequest(context,))..all('/GetSourceList', (context) => api_v1_template_get_source_list.onRequest(context,))..all('/GetSourceMasterList', (context) => api_v1_template_get_source_master_list.onRequest(context,))..all('/GetSourceMasterListFilterwise', (context) => api_v1_template_get_source_master_list_filterwise.onRequest(context,))..all('/GetSourceType', (context) => api_v1_template_get_source_type.onRequest(context,))..all('/GetTemplates', (context) => api_v1_template_get_templates.onRequest(context,))..all('/UploadManualData', (context) => api_v1_template_upload_manual_data.onRequest(context,))..all('/UploadManualDataChecker', (context) => api_v1_template_upload_manual_data_checker.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiV1PipelineHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/save-sources', (context) => api_v1_pipeline_save_sources.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiV1MasterHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/approval-list', (context) => api_v1_master_approval_list.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiV1AuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/logout', (context) => api_v1_auth_logout.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiV1AccountHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/login', (context) => api_v1_account_login.onRequest(context,))..all('/refresh', (context) => api_v1_account_refresh.onRequest(context,));
  return pipeline.addHandler(router);
}

