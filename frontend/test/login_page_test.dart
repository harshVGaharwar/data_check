import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/pages/login_page.dart';
import 'package:vizualizer/providers/auth_provider.dart';
import 'package:vizualizer/models/login_response.dart';

// ── Manual mock for AuthProvider ──────────────────────────────────────────────

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  final bool _loginResult;
  final String? _fixedError; // error returned by login(); null means provider.error stays null
  String? _error;
  bool _loading = false;
  LoginResponse? _user;
  bool _initialized = true;

  MockAuthProvider({bool loginResult = true, String? error})
      : _loginResult = loginResult,
        _fixedError = error,
        _error = null;

  @override
  bool get initialized => _initialized;
  @override
  bool get loading => _loading;
  @override
  String? get error => _error;
  @override
  LoginResponse? get user => _user;
  @override
  bool get isLoggedIn => _user != null;

  @override
  Future<bool> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(Duration.zero); // yield to allow UI update
    _loading = false;
    if (_loginResult) {
      _user = LoginResponse(
        token: 'test-token',
        refreshToken: 'test-refresh',
        user: LoginUser(name: username, role: '1'),
      );
    } else {
      _error = _fixedError; // null means LoginPage falls back to 'Login failed'
    }
    notifyListeners();
    return _loginResult;
  }

  @override
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }

  // Private methods — not part of public interface, no-op here
  // ignore: unused_element
  Future<void> _tryAutoLogin() async {}
}

// ── Test helpers ──────────────────────────────────────────────────────────────

Widget buildLoginPage(AuthProvider authProvider) {
  return MaterialApp(
    routes: {
      '/dashboard': (_) => const Scaffold(body: Text('Dashboard')),
    },
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const LoginPage(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('LoginPage — UI rendering', () {
    testWidgets('renders Sign In title', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('renders username and password text fields', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Enter username'), findsOneWidget);
      expect(find.text('Enter password'), findsOneWidget);
    });

    testWidgets('renders HDFC Pipeline Builder heading', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      expect(find.text('HDFC Pipeline Builder'), findsOneWidget);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      expect(find.text('Enter your credentials to continue'), findsOneWidget);
    });

    testWidgets('password field is obscured by default', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      final passwordField = tester.widget<TextField>(find.byType(TextField).last);
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('password visibility toggle shows/hides password', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      // Password obscured by default
      TextField passwordField =
          tester.widget<TextField>(find.byType(TextField).last);
      expect(passwordField.obscureText, isTrue);

      // Tap the visibility toggle icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      passwordField = tester.widget<TextField>(find.byType(TextField).last);
      expect(passwordField.obscureText, isFalse);

      // Tap again to re-obscure
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      passwordField = tester.widget<TextField>(find.byType(TextField).last);
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('shows logo with letter H', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      expect(find.text('H'), findsOneWidget);
    });

    testWidgets('shows version footer text', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      expect(find.textContaining('v1.0'), findsOneWidget);
    });
  });

  group('LoginPage — validation', () {
    testWidgets('shows error SnackBar when both fields are empty', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      await tester.tap(find.text('Sign In').last);
      await tester.pump();

      expect(
        find.text('Please enter username and password'),
        findsOneWidget,
      );
    });

    testWidgets('shows error SnackBar when username is empty', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Sign In').last);
      await tester.pump();

      expect(
        find.text('Please enter username and password'),
        findsOneWidget,
      );
    });

    testWidgets('shows error SnackBar when password is empty', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.tap(find.text('Sign In').last);
      await tester.pump();

      expect(
        find.text('Please enter username and password'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for whitespace-only username', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Sign In').last);
      await tester.pump();

      expect(
        find.text('Please enter username and password'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for whitespace-only password', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.tap(find.text('Sign In').last);
      await tester.pump();

      expect(
        find.text('Please enter username and password'),
        findsOneWidget,
      );
    });
  });

  group('LoginPage — successful login', () {
    testWidgets('navigates to /dashboard on successful login', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider(loginResult: true)));

      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'admin123');
      await tester.tap(find.text('Sign In').last);

      // Let the async login complete
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('shows loading indicator while login is in progress', (tester) async {
      // Use a delayed mock to capture the loading state
      final provider = _DelayedAuthProvider();
      await tester.pumpWidget(buildLoginPage(provider));

      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'admin123');
      await tester.tap(find.text('Sign In').last);

      // Pump one frame — login is still in progress
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the login
      await tester.pumpAndSettle();
    });

    testWidgets('Sign In button is disabled while loading', (tester) async {
      final provider = _DelayedAuthProvider();
      await tester.pumpWidget(buildLoginPage(provider));

      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'admin123');
      await tester.tap(find.text('Sign In').last);
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      await tester.pumpAndSettle();
    });
  });

  group('LoginPage — failed login', () {
    testWidgets('shows error SnackBar on failed login', (tester) async {
      final provider = MockAuthProvider(
        loginResult: false,
        error: 'Invalid credentials',
      );
      await tester.pumpWidget(buildLoginPage(provider));

      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'wrongpass');
      await tester.tap(find.text('Sign In').last);

      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('shows fallback "Login failed" if error is null', (tester) async {
      final provider = MockAuthProvider(loginResult: false, error: null);
      await tester.pumpWidget(buildLoginPage(provider));

      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'wrongpass');
      await tester.tap(find.text('Sign In').last);

      await tester.pumpAndSettle();

      expect(find.text('Login failed'), findsOneWidget);
    });

    testWidgets('does not navigate to dashboard on failed login', (tester) async {
      final provider = MockAuthProvider(loginResult: false, error: 'Invalid credentials');
      await tester.pumpWidget(buildLoginPage(provider));

      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'wrongpass');
      await tester.tap(find.text('Sign In').last);

      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Sign In'), findsWidgets); // Still on login page
    });

    testWidgets('can retry login after failure', (tester) async {
      final provider = MockAuthProvider(loginResult: false, error: 'Invalid credentials');
      await tester.pumpWidget(buildLoginPage(provider));

      // First attempt — fails
      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.tap(find.text('Sign In').last);
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);

      // Second attempt — should still be able to tap
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });

  group('LoginPage — keyboard submission', () {
    testWidgets('pressing enter in password field submits the form', (tester) async {
      await tester.pumpWidget(buildLoginPage(MockAuthProvider()));

      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'admin123');

      // Simulate pressing done/enter on the password field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}

// ── Helper: delayed mock so we can observe loading state ─────────────────────

class _DelayedAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _loading = false;
  LoginResponse? _user;

  @override
  bool get initialized => true;
  @override
  bool get loading => _loading;
  @override
  String? get error => null;
  @override
  LoginResponse? get user => _user;
  @override
  bool get isLoggedIn => _user != null;

  @override
  Future<bool> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    _loading = false;
    _user = LoginResponse(
      token: 'test-token',
      refreshToken: 'test-refresh',
      user: LoginUser(name: username),
    );
    notifyListeners();
    return true;
  }

  @override
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }
}
