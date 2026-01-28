import 'package:mymusicplayer_new/core/configs/usecase/auth/usecase.dart';
import 'package:mymusicplayer_new/data/models/auth/signin_user_req.dart';
import 'package:dartz/dartz.dart';

import '../../../../domain/repository/auth/auth.dart';

class SigninUseCase implements UseCase<Either, SigninUserReq> {
  final AuthRepository _authRepository;
  SigninUseCase(this._authRepository);

  @override
  Future<Either> call({SigninUserReq? params}) async {
    return _authRepository.signin(params!);
  }
}