import '../../domain/models/app_user.dart';

abstract class AuthRepository {
  AppUser? currentUser();
}
