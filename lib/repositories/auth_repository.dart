import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'interfaces/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final DatabaseService _dbService;
  static const _tag = 'AuthRepository';

  AuthRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  @override
  Future<bool> login(String username, String password) async {
    try {
      final db = await _dbService.database;
      final results = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username.trim(), password.trim()],
      );
      
      if (results.isNotEmpty) {
        AppLogger.instance.info('User successfully authenticated: $username', tag: _tag);
        return true;
      }
      
      AppLogger.instance.warning('Authentication failed for user: $username', tag: _tag);
      return false;
    } catch (e) {
      AppLogger.instance.error('Error during database user authentication check', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<bool> signup(String username, String password) async {
    try {
      final db = await _dbService.database;
      
      // Check if username already exists
      final existing = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username.trim()],
      );
      
      if (existing.isNotEmpty) {
        AppLogger.instance.warning('Signup failed: username $username already exists', tag: _tag);
        return false;
      }
      
      final id = await db.insert('users', {
        'username': username.trim(),
        'password': password.trim(),
      });
      
      if (id > 0) {
        AppLogger.instance.info('New user registered successfully: $username', tag: _tag);
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.instance.error('Error during database signup', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<String>> getAllUsers() async {
    try {
      final db = await _dbService.database;
      final results = await db.query('users', columns: ['username']);
      return results.map((row) => row['username'] as String).toList();
    } catch (e) {
      AppLogger.instance.error('Error fetching all users', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<bool> deleteUser(String username) async {
    if (username.trim().toLowerCase() == 'admin') {
      AppLogger.instance.warning('Cannot delete admin user', tag: _tag);
      return false;
    }
    try {
      final db = await _dbService.database;
      final count = await db.delete(
        'users',
        where: 'username = ?',
        whereArgs: [username.trim()],
      );
      if (count > 0) {
        AppLogger.instance.info('User deleted successfully: $username', tag: _tag);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.instance.error('Error deleting user: $username', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<bool> updatePassword(String username, String newPassword) async {
    try {
      final db = await _dbService.database;
      final count = await db.update(
        'users',
        {'password': newPassword.trim()},
        where: 'username = ?',
        whereArgs: [username.trim()],
      );
      if (count > 0) {
        AppLogger.instance.info('Password updated successfully for: $username', tag: _tag);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.instance.error('Error updating password for: $username', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
