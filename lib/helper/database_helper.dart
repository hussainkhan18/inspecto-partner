import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'cart_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE cart_items (id INTEGER PRIMARY KEY AUTOINCREMENT, productId INTEGER, name TEXT, itemImg TEXT, salePrice TEXT, quantity INTEGER, userId INTEGER)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('ALTER TABLE cart_items ADD COLUMN productId INTEGER');
        }
      },
    );
  }

  Future<void> insertCartItem(DatabaseItem item, int quantity, int userId) async {
    final db = await database;
    final cartItem = {
      'productId': item.id,
      'name': item.name,
      'itemImg': item.itemImg,
      'salePrice': item.salePrice,
      'quantity': quantity,
      'userId': userId,
    };
    print('Inserting item into cart: $cartItem'); // Debug statement
    await db.insert(
      'cart_items',
      cartItem,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCartItems(int userId) async {
    final db = await database;
    final cartItems = await db.query(
      'cart_items',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print('Fetched cart items from database: $cartItems'); // Debug statement
    return cartItems;
  }

  Future<void> clearCart(int userId) async {
    final db = await database;
    await db.delete(
      'cart_items',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> removeCartItem(String itemName, int userId) async {
    final db = await database;
    await db.delete(
      'cart_items',
      where: 'name = ? AND userId = ?',
      whereArgs: [itemName, userId],
    );
  }
}

class DatabaseItem {
  final int? id;
  final String name;
  final String itemImg;
  final String salePrice;

  DatabaseItem({
    this.id,
    required this.name,
    required this.itemImg,
    required this.salePrice,
  });
}
