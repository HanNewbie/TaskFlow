import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource authDataSource;

  AuthRepositoryImpl({required this.authDataSource});

  @override
  Future<UserEntity> signIn(String email, String password) async {
    return await authDataSource.signIn(email, password);
  }

  @override
  Future<UserEntity> signUp(String email, String password, String displayName) async {
    return await authDataSource.signUp(email, password, displayName);
  }

  @override
  Future<void> signOut() async {
    return await authDataSource.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await authDataSource.getCurrentUser();
  }

  @override
  Stream<UserEntity?> get authStateChanges => authDataSource.authStateChanges;
}
