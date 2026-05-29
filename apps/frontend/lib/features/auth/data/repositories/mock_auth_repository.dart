import '../../domain/models/app_user.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  AppUser? currentUser() {
    return const AppUser(id: 'demo-user-1', displayName: '나');
  }
}
