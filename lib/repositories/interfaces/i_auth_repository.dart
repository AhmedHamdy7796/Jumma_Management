abstract interface class IAuthRepository {
  Future<bool> login(String username, String password);
  Future<bool> signup(String username, String password);
}
