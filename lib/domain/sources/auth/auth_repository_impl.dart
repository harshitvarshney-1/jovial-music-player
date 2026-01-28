import 'package:dartz/dartz.dart';
import '../../../data/models/auth/create_user_req.dart';
import '../../../data/models/auth/signin_user_req.dart';
import '../../repository/auth/auth.dart';
import '../../sources/auth/auth_firebase_service.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthFirebaseService _authFirebaseService;
  AuthRepositoryImpl(this._authFirebaseService);

  @override
  Future<Either<String, String>> signin(SigninUserReq signinUserReq) async {
    return await _authFirebaseService.signin(signinUserReq);
  }

  @override
  Future<Either<String, String>> signup(CreateUserReq createUserReq) async {
    return await _authFirebaseService.signup(createUserReq);
  }
}

