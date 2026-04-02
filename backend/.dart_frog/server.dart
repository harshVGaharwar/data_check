// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/index.dart' as index;
import '../routes/api/v1/templates/index.dart' as api_v1_templates_index;
import '../routes/api/v1/templates/[id].dart' as api_v1_templates_$id;
import '../routes/api/v1/pipeline/submit-mapping.dart' as api_v1_pipeline_submit_mapping;
import '../routes/api/v1/pipeline/save-sources.dart' as api_v1_pipeline_save_sources;
import '../routes/api/v1/master/departments.dart' as api_v1_master_departments;
import '../routes/api/v1/master/approval-list.dart' as api_v1_master_approval_list;
import '../routes/api/v1/auth/logout.dart' as api_v1_auth_logout;
import '../routes/api/v1/auth/login.dart' as api_v1_auth_login;

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
    ..mount('/api/v1/pipeline', (context) => buildApiV1PipelineHandler()(context))
    ..mount('/api/v1/master', (context) => buildApiV1MasterHandler()(context))
    ..mount('/api/v1/auth', (context) => buildApiV1AuthHandler()(context));
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
    ..all('/<id>', (context,id,) => api_v1_templates_$id.onRequest(context,id,))..all('/', (context) => api_v1_templates_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiV1PipelineHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/save-sources', (context) => api_v1_pipeline_save_sources.onRequest(context,))..all('/submit-mapping', (context) => api_v1_pipeline_submit_mapping.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiV1MasterHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/approval-list', (context) => api_v1_master_approval_list.onRequest(context,))..all('/departments', (context) => api_v1_master_departments.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiV1AuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/login', (context) => api_v1_auth_login.onRequest(context,))..all('/logout', (context) => api_v1_auth_logout.onRequest(context,));
  return pipeline.addHandler(router);
}

