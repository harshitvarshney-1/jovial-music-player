import 'package:get_it/get_it.dart';

import '../core/configs/usecase/auth/signin.dart';
import '../core/configs/usecase/auth/signup.dart';
import '../domain/repository/auth/auth.dart';
import '../domain/sources/auth/auth_firebase_service.dart';
import '../domain/sources/auth/auth_repository_impl.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final sl = GetIt.instance;
  // Register Firebase Auth Service
  sl.registerSingleton<AuthFirebaseService>(
    AuthFirebaseServiceImpl(),
  );

  // Register Auth Repository
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(sl<AuthFirebaseService>()),
  );

  // Register Signup UseCase
  sl.registerSingleton<SignupUseCase>(
    SignupUseCase(sl<AuthRepository>()),
  );

  // Register Signin UseCase
  sl.registerSingleton<SigninUseCase>(
    SigninUseCase(sl<AuthRepository>()),
  );
}

