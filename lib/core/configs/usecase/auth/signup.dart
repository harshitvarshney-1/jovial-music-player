import 'package:mymusicplayer_new/core/configs/usecase/auth/usecase.dart';
import 'package:mymusicplayer_new/data/models/auth/create_user_req.dart';
import 'package:mymusicplayer_new/data/models/auth/signin_user_req.dart';
import 'package:dartz/dartz.dart';

import '../../../../domain/repository/auth/auth.dart';

class SignupUseCase implements UseCase<Either, CreateUserReq> {
  final AuthRepository _authRepository;
  SignupUseCase(this._authRepository);

  @override
  Future<Either> call({CreateUserReq? params}) async {
    return _authRepository.signup(params!);
  }
}
