import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'status': 'success',
      'message': 'HDFC Pipeline Builder API v1.0',
      'endpoints': [
        'POST /api/v1/auth/login',
        'POST /api/v1/auth/logout',
        'GET  /api/v1/master/departments',
        'POST /api/v1/templates',
        'GET  /api/v1/templates',
        'GET  /api/v1/templates/:id',
        'POST /api/v1/pipeline/submit-mapping',
        'POST /api/v1/pipeline/save-sources',
      ],
    },
  );
}
