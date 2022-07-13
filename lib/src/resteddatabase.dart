library rested.database;

import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'dart:io';

DatabaseManager rdb = DatabaseManager();

class DatabaseManager {

    RestedDatabaseConnection con = RestedDatabaseConnection();
    DatabaseManager();

    Map<String, RestedTable> tables = {};

    void addTable(String name, RestedTable schema) {
        tables[name] = schema;
    }

    void loadTable() {

    }

    Future<List<List<dynamic>>> query(String querystring) async {
        return await con.query(querystring);
    }


    Future<List<Map<String, dynamic>>> getRow(String table, String where) async {
        if(tables.containsKey(table) == false) {
            print("Error, tried to access table '" + table + "' which isn't loaded.");
            return [{}];
        }

        List<List<dynamic>> db_response = await con.query('SELECT * FROM ' + table + " WHERE " + where);
        return tables[table].getArray(db_response);
    }
}

Map<String, String> envVars = Platform.environment;

class RestedDatabaseConnection {
    String _integration;
    String _hostname;
    int _port;
    String _database;
    String _username;
    String _password;
    Function _query;
    Function _exists;
    Function _describe;
    
    RestedDatabaseConnection() {
        _integration = envVars['db_integration'];
        _hostname = envVars['db_hostname'];
        _port = int.parse(envVars['db_port']);
        _database = envVars['db_database'];
        _username = envVars['db_username'];
        _password = envVars['db_password'];

        if(_integration.toLowerCase() == 'postgres') {
            _query = postgres_query;
            _exists = postgres_exists;
            _describe = postgres_describe;
        }
    }

    Future<List<List<dynamic>>> postgres_query(String querystring) async {
        var connection = PostgreSQLConnection(_hostname, _port, _database, username: _username, password: _password);
        await connection.open();
        List<List<dynamic>> result = await connection.query(querystring);
        connection.close();
        return result;
    }

    Future<bool> postgres_exists(String querystring) async {
        var connection = PostgreSQLConnection(_hostname, _port, _database, username: _username, password: _password);
        await connection.open();
        List<List<dynamic>> result = await connection.query("SELECT COUNT(*) FROM " + querystring);
        connection.close();
        if(result[0][0] == 0) {
            return false;
        } else {
            return true;
        }

    }

    Future<List<List<dynamic>>> postgres_describe(String querystring) async {
        var connection = PostgreSQLConnection(_hostname, _port, _database, username: _username, password: _password);
        await connection.open();
        return await connection.query(querystring);
    }

    Future<List<List<dynamic>>> query(String querystring) async {
        return await _query(querystring);
    }

    Future<bool> exists(String querystring) async {
        return await _exists(querystring);
    }

    Future<Map<String, dynamic>> describe(String table) async {
        return await _describe(table);
    }
}

class RestedTable {
    List<String> columnNames = [];

    RestedTable(this.columnNames);

    Map<String, dynamic> columnToMap(List<dynamic> resultColumn, {List<String> returning, List<String> excluding}) {
        Map<String, dynamic> result = {};

        // checking if null on both optional parameters - unelegant but effective
        if(returning == null) {
            for(String key in columnNames) {
                if(excluding != null) {
                    if(excluding.contains(key) == false) {
                        result[key] = resultColumn[columnNames.indexOf(key)];
                    }
                } else {
                    result[key] = resultColumn[columnNames.indexOf(key)];
                }
            }
        } else {
            for(String key in columnNames) {
                if(returning.contains(key)) {
                    if(excluding != null) {
                        if(excluding.contains(key) == false) {
                            result[key] = resultColumn[columnNames.indexOf(key)];
                        }
                    } else {
                        result[key] = resultColumn[columnNames.indexOf(key)];
                    }
                }
            }
        }
        return result;
    }

    Map<String, dynamic> getSingleObject(List<List<dynamic>> query_result, {List<String> returning, List<String> excluding}) {
        return columnToMap(query_result[0], returning: returning, excluding: excluding);
    }

    List<Map<String, dynamic>> getArray(List<List<dynamic>> query_result, {List<String> returning, List<String> excluding}) {
        List<Map<String, dynamic>> result = [];
        for(List<dynamic> element in query_result) {
            result.add(columnToMap(element, returning: returning, excluding: excluding));
        }
        return result;
    }
}
