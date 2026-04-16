import 'package:web/web.dart' as web;

/// Web implementation — reads navigator.onLine directly.
Future<bool> checkOnlineStatus() async => web.window.navigator.onLine;
