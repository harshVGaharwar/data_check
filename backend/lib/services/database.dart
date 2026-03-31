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
  final Map<String, String> tokens = {}; // token → userId

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
