import 'package:dart_frog/dart_frog.dart';
import '../lib/middleware/middleware.dart';

Handler middleware(Handler handler) {
  return handler.use(corsMiddleware()).use(authMiddleware());
}
