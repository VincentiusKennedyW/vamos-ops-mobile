import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/errors/api_exception.dart';
import 'package:vamos_ops_mobile/app/core/storage/session_store.dart';
import 'package:vamos_ops_mobile/app/modules/auth/controllers/auth_controller.dart';
import 'package:vamos_ops_mobile/app/modules/auth/data/auth_api_provider.dart';
import 'package:vamos_ops_mobile/app/modules/auth/data/auth_repository.dart';
import 'package:vamos_ops_mobile/app/modules/auth/models/auth_session.dart';
import 'package:vamos_ops_mobile/app/routes/app_routes.dart';
import 'package:vamos_ops_mobile/app/vamos_app.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('login and logout can repeat without leaving auth busy', (
    tester,
  ) async {
    final repository = _CycleAuthRepository();
    final controller = AuthController(repository);
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: BindingsBuilder(() {
          Get.put(controller, permanent: true);
        }),
        initialRoute: AppRoutes.login,
        getPages: [
          GetPage(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('LOGIN PAGE')),
          ),
          GetPage(
            name: AppRoutes.staff,
            page: () => const Scaffold(body: Text('STAFF PAGE')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    for (var cycle = 0; cycle < 2; cycle++) {
      controller.login('andi@vamos.local', 'VamosStaff#2026');
      await tester.pumpAndSettle();
      expect(find.text('STAFF PAGE'), findsOneWidget);
      expect(
        controller.isAuthenticating.value,
        isFalse,
        reason: 'route completion must not keep auth busy',
      );
      controller.logout();
      await tester.pumpAndSettle();
      expect(find.text('LOGIN PAGE'), findsOneWidget);
    }
    expect(repository.logoutCalls, 2);
  });

  test('login stores opaque token and resolves authenticated user', () async {
    final store = _MemorySessionStore();
    final repository = AuthRepository(_SuccessfulAuthProvider(), store);

    final session = await repository.login(
      'andi@vamos.local',
      'VamosStaff#2026',
    );

    expect(store.token, 'opaque-test-token');
    expect(session.user.fullName, 'Andi Saputra');
    expect(session.user.permissions, contains('tasks:update:own'));
  });

  test('expired stored session is removed locally', () async {
    final store = _MemorySessionStore()..currentToken = 'expired-token';
    final repository = AuthRepository(_ExpiredAuthProvider(), store);

    final session = await repository.restore();

    expect(session, isNull);
    expect(store.token, isNull);
  });

  testWidgets('login validates fields and shows server failure feedback', (
    tester,
  ) async {
    final fakeRepository = _FailingAuthRepository();
    await tester.pumpWidget(
      VamosApp(
        initialRoute: AppRoutes.login,
        initialBinding: BindingsBuilder(() {
          Get.put<AuthRepositoryContract>(fakeRepository);
          Get.put<AuthController>(AuthController(fakeRepository));
        }),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Email wajib diisi.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'andi@vamos.local',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'password-valid',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email atau kata sandi tidak sesuai.'), findsOneWidget);
    expect(fakeRepository.loginCalls, 1);
  });
}

class _CycleAuthRepository implements AuthRepositoryContract {
  int logoutCalls = 0;
  @override
  Future<AuthSession?> restore() async => null;
  @override
  Future<AuthSession> login(String email, String password) async => AuthSession(
    token: 'test',
    user: AuthUser.fromJson({
      'userId': 'staff-1',
      'fullName': 'Andi',
      'email': email,
      'permissions': [],
    }),
  );
  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

class _MemorySessionStore implements SessionStoreContract {
  String? currentToken;

  @override
  String? get token => currentToken;

  @override
  Future<void> clear() async => currentToken = null;

  @override
  Future<String?> load() async => currentToken;

  @override
  Future<void> save(String token) async => currentToken = token;
}

class _SuccessfulAuthProvider extends AuthApiProvider {
  @override
  Future<Response<dynamic>> login(String email, String password) async =>
      const Response<dynamic>(
        statusCode: 200,
        body: {'token': 'opaque-test-token'},
      );

  @override
  Future<Response<dynamic>> session(String token) async => Response<dynamic>(
    statusCode: 200,
    body: {
      'user': {
        'userId': 'staff-1',
        'fullName': 'Andi Saputra',
        'email': 'andi@vamos.local',
        'roleName': 'Crew Padel',
        'roleCode': 'CREW_PADEL',
        'venueName': 'Vamos Arena Fit Denpasar',
        'permissions': ['tasks:update:own'],
        'expiresAt': '2026-09-02T12:00:00.000Z',
      },
    },
  );
}

class _ExpiredAuthProvider extends AuthApiProvider {
  @override
  Future<Response<dynamic>> session(String token) async =>
      const Response<dynamic>(
        statusCode: 401,
        body: {'message': 'Sesi tidak valid atau sudah berakhir.'},
      );
}

class _FailingAuthRepository implements AuthRepositoryContract {
  int loginCalls = 0;

  @override
  Future<AuthSession> login(String email, String password) async {
    loginCalls += 1;
    throw const ApiException(
      'Email atau kata sandi tidak sesuai.',
      statusCode: 401,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restore() async => null;
}
