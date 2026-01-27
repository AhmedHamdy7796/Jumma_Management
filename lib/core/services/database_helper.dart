import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:gomaa_management/features/customer/data/models/customer.dart';
import 'package:gomaa_management/features/purchase/data/models/purchase.dart';
import 'package:gomaa_management/features/fix/data/models/fix.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gomaa_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE customers ADD COLUMN purchases TEXT NOT NULL DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE customers ADD COLUMN model TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE purchases ADD COLUMN model TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 4) {
      // Previous purchase migration
      try {
        await db.execute('ALTER TABLE purchases RENAME TO purchases_old');
        await db.execute('''
          CREATE TABLE purchases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            machineName TEXT NOT NULL,
            model TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            price REAL NOT NULL,
            totalAmount REAL NOT NULL,
            paidAmount REAL NOT NULL,
            remainingBalance REAL NOT NULL,
            date TEXT NOT NULL,
            notes TEXT NOT NULL
          )
        ''');
        await db.execute('''
          INSERT INTO purchases (id, machineName, model, quantity, price, totalAmount, paidAmount, remainingBalance, date, notes)
          SELECT id, productName, model, quantity, price, totalAmount, paidAmount, remainingBalance, date, notes FROM purchases_old
        ''');
        await db.execute('DROP TABLE purchases_old');
      } catch (e) {
        // Handle if table was already renamed or partially migrated
      }
    }
    if (oldVersion < 5) {
      // Migration to fix customers table (remove phone column)
      // Check if phone column exists before attempting migration
      var tableInfo = await db.rawQuery('PRAGMA table_info(customers)');
      bool hasPhone = tableInfo.any((column) => column['name'] == 'phone');

      if (hasPhone) {
        await db.execute('''
          CREATE TABLE customers_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            mobilePhone TEXT NOT NULL,
            transactionType TEXT NOT NULL,
            purchases TEXT NOT NULL,
            model TEXT NOT NULL,
            amount REAL NOT NULL,
            paidAmount REAL NOT NULL,
            remainingBalance REAL NOT NULL,
            date TEXT NOT NULL,
            notes TEXT NOT NULL
          )
        ''');

        await db.execute('''
          INSERT INTO customers_new (id, name, mobilePhone, transactionType, purchases, model, amount, paidAmount, remainingBalance, date, notes)
          SELECT id, name, mobilePhone, transactionType, purchases, model, amount, paidAmount, remainingBalance, date, notes FROM customers
        ''');

        await db.execute('DROP TABLE customers');
        await db.execute('ALTER TABLE customers_new RENAME TO customers');
      }
    }
    if (oldVersion < 6) {
      // Add imagePath column to purchases table
      await db.execute('ALTER TABLE purchases ADD COLUMN imagePath TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Create customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobilePhone TEXT NOT NULL,
        transactionType TEXT NOT NULL,
        purchases TEXT NOT NULL,
        model TEXT NOT NULL,
        amount REAL NOT NULL,
        paidAmount REAL NOT NULL,
        remainingBalance REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT NOT NULL
      )
    ''');

    // Create purchases table
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        machineName TEXT NOT NULL,
        model TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        totalAmount REAL NOT NULL,
        paidAmount REAL NOT NULL,
        remainingBalance REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT NOT NULL,
        imagePath TEXT
      )
    ''');

    // Create fixes table
    await db.execute('''
      CREATE TABLE fixes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        machineName TEXT NOT NULL,
        model TEXT NOT NULL,
        dryerType TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        issue TEXT NOT NULL,
        status TEXT NOT NULL,
        cost REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT NOT NULL
      )
    ''');
  }

  // Customer CRUD operations
  Future<int> createCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Purchase CRUD operations
  Future<int> createPurchase(Purchase purchase) async {
    final db = await database;
    return await db.insert('purchases', purchase.toMap());
  }

  Future<List<Purchase>> getAllPurchases() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchases',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Purchase.fromMap(maps[i]));
  }

  Future<Purchase?> getPurchase(int id) async {
    final db = await database;
    final maps = await db.query('purchases', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Purchase.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePurchase(Purchase purchase) async {
    final db = await database;
    return await db.update(
      'purchases',
      purchase.toMap(),
      where: 'id = ?',
      whereArgs: [purchase.id],
    );
  }

  Future<int> deletePurchase(int id) async {
    final db = await database;
    return await db.delete('purchases', where: 'id = ?', whereArgs: [id]);
  }

  // Fix CRUD operations
  Future<int> createFix(Fix fix) async {
    final db = await database;
    return await db.insert('fixes', fix.toMap());
  }

  Future<List<Fix>> getAllFixes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fixes',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Fix.fromMap(maps[i]));
  }

  Future<Fix?> getFix(int id) async {
    final db = await database;
    final maps = await db.query('fixes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Fix.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateFix(Fix fix) async {
    final db = await database;
    return await db.update(
      'fixes',
      fix.toMap(),
      where: 'id = ?',
      whereArgs: [fix.id],
    );
  }

  Future<int> deleteFix(int id) async {
    final db = await database;
    return await db.delete('fixes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
