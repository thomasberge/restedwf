import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'dart:io';

/*
Future<QueryResults> qr_query(String querystring) async {
    await connection.open();
    List<Map<String, Map<String, dynamic>>> result = await connection.mappedResultsQuery(querystring);
    return QueryResults(result);
}
*/

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
        }
    }

    Future<List<List<dynamic>>> postgres_query(String querystring) async {
        var connection = PostgreSQLConnection(_hostname, _port, _database, username: _username, password: _password);
        await connection.open();
        return await connection.query(querystring);
    }

    Future<bool> postgres_exists(String querystring) async {
        var connection = PostgreSQLConnection(_hostname, _port, _database, username: _username, password: _password);
        await connection.open();
        List<List<dynamic>> result = await connection.query("SELECT COUNT(*) FROM " + querystring);
        if(result[0][0] == 0) {
            return false;
        } else {
            return true;
        }

    }    

    Future<List<List<dynamic>>> query(String querystring) async {
        return await _query(querystring);
    }

    Future<bool> exists(String querystring) async {
        return await _exists(querystring);
    }    
}

class RestedTableSchema {
    List<String> columnNames = [];

    RestedTableSchema(this.columnNames);

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
/*
class QueryResults {
    List<Map<String, Map<String, dynamic>>> result = [];

    QueryResults(this.result);

    String toString() {
        return result.toString();
    }

    dynamic toJson() {
        //return 
    }
}
*/