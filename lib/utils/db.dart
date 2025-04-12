

import 'package:flutter/services.dart';
import 'package:flutterondeor/alias.dart';
import 'package:sqflite/sqflite.dart';


abstract class DBConnection{
  final String _dbFileName;
  late final Database _database;
  late final String _dbPath;

  DBConnection({required String dbFileName}) : _dbFileName = dbFileName;

  /// This should be the first method to call
  void openDB() async{
    _dbPath=await getDBPath(this);
    _database = await openDatabase(_dbPath, version: 1,onCreate: onCreateDBConnection);
  }

  static Future<String> loadSqlAsset(String filePath)=> rootBundle.loadString('assets/sql/$filePath');

  static Future<String> getDBPath(DBConnection q)async=>'${await getDatabasesPath()}/${q._dbFileName}';

  /// Run some initialization of tables for example.
  /// ```sql
  /// await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
  /// ```
  Future<void> onCreateDBConnection(Database db, int version);


  Future<int> runInsertDBQuery(String query, {List<dynamic>? args})async{
    return _database.transaction((txn) async {
      return  txn.rawInsert(query,args);
    });
  }
  Future<int> runInsertDBQueryFromMap({required String tableName,required JsonMap map,StrList excludeFields=const[],StrList extraFields=const[],StrList extraValues=const []})async{
    final mp= {...map}..removeWhere((k,v)=>excludeFields.contains(k))..removeWhere((k,v)=>extraFields.contains(k));
    final keys=[...mp.keys,...extraFields];
    final values=[...mp.values,...extraValues];
    final columns=keys.join(',');
    final qs=keys.map((_)=>'?').join(',');
    return runInsertDBQuery('insert into $tableName ($columns) values ($qs)',args:values);
  }

  /// ```sql
  /// SELECT COUNT(*) FROM Test
  /// ```
  Future<int?> runCountDBQuery(String query)async =>Sqflite.firstIntValue(await _database.rawQuery(query));

  Future<int> runUpdateDBQuery(String query, {List<dynamic>? args})async{
    return _database.transaction((txn) async {
      return  txn.rawUpdate(query,args);
    });
  }

  Future<int> deleteDBRecord(String query,[List<dynamic>? args])async=> await _database.rawDelete(query, args);

  Future<List<JsonMap>> runRawSelectDBQuery(String query)async=> _database.rawQuery(query);

  Future<List<JsonMap>> runSelectDBQuery({required String tableName})async=> runRawSelectDBQuery('select * from $tableName');


  Future<void> deleteDB()async=>    await deleteDatabase(_dbPath);


  Future<void> closeDB()async=>await _database.close();


}