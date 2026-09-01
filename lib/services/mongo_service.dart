import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MongoService {
  static const String _uri = "mongodb+srv://smnafizulislam_db_user:Rao8j7DupRDxxLJi@cafetrack-cluster.06rhpd2.mongodb.net/cafetrackDB";
  static late Db _db;
  static Map<String, dynamic>? currentUser;

  static Future<void> connect() async {
    _db = await Db.create(_uri);
    await _db.open();
    await _loadSession();
  }

  static Db get db => _db;

  static DbCollection collection(String name) {
    return _db.collection(name);
  }

  static Future<void> saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert ObjectId to string so it can be JSON encoded
    final userToSave = Map<String, dynamic>.from(user);
    if (userToSave['_id'] != null) {
      userToSave['_id'] = userToSave['_id'].toString();
    }
    await prefs.setString('currentUser', jsonEncode(userToSave));
    currentUser = user;
  }

  static Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('currentUser');
    if (userStr != null) {
      currentUser = jsonDecode(userStr);
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
    currentUser = null;
  }

  static Future<String> getNextOrderNumber() async {
    final count = await _db.collection('orders').count();
    final nextId = count + 1;
    return 'CT-${nextId.toString().padLeft(5, '0')}';
  }

  static Future<int> getNextTokenNumber() async {
    final pipeline = [
      {'\$match': {'token_number': {'\$ne': null}}},
      {'\$group': {'_id': null, 'maxToken': {'\$max': '\$token_number'}}}
    ];
    final result = await _db.collection('orders').aggregateToStream(pipeline).toList();
    if (result.isNotEmpty && result.first['maxToken'] != null) {
      return (result.first['maxToken'] as num).toInt() + 1;
    }
    return 1;
  }

  static ObjectId parseObjectId(String id) {
    String hexId = id;
    if (id.startsWith('ObjectId("') && id.endsWith('")')) {
      hexId = id.substring(10, id.length - 2);
    }
    return ObjectId.parse(hexId);
  }
}
