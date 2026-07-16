import 'package:flutter/material.dart';
import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/search_result_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_search_repository.dart';

class SearchRepository implements ISearchRepository {
  final DatabaseService _dbService;
  static const _tag = 'SearchRepository';

  SearchRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  @override
  Future<List<SearchResultModel>> globalSearch(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final db = await _dbService.database;
      final wildCardQuery = '%$query%';

      // We query name/mobile from customers, machineName/model from purchases, 
      // machineName/issue from fixes, name/model from inventory.
      // We use SQL UNION to combine them, utilizing indexes on those fields.
      final sql = '''
        SELECT '${AuditEntityType.customer}' AS type, ${CustomerColumns.id} AS id, ${CustomerColumns.name} AS title, ${CustomerColumns.mobilePhone} AS subtitle
          FROM ${TableNames.customers} 
          WHERE ${CustomerColumns.name} LIKE ? OR ${CustomerColumns.mobilePhone} LIKE ?
        UNION ALL
        SELECT '${AuditEntityType.purchase}' AS type, ${PurchaseColumns.id} AS id, ${PurchaseColumns.machineName} AS title, ${PurchaseColumns.model} AS subtitle
          FROM ${TableNames.purchases} 
          WHERE ${PurchaseColumns.machineName} LIKE ? OR ${PurchaseColumns.model} LIKE ?
        UNION ALL
        SELECT '${AuditEntityType.fix}' AS type, ${FixColumns.id} AS id, ${FixColumns.machineName} AS title, ${FixColumns.issue} AS subtitle
          FROM ${TableNames.fixes} 
          WHERE ${FixColumns.machineName} LIKE ? OR ${FixColumns.issue} LIKE ?
        UNION ALL
        SELECT '${AuditEntityType.inventory}' AS type, ${InventoryColumns.id} AS id, ${InventoryColumns.name} AS title, ${InventoryColumns.model} AS subtitle
          FROM ${TableNames.inventory} 
          WHERE ${InventoryColumns.name} LIKE ? OR ${InventoryColumns.model} LIKE ?
        LIMIT 50
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        sql,
        [
          wildCardQuery, wildCardQuery, // customer
          wildCardQuery, wildCardQuery, // purchase
          wildCardQuery, wildCardQuery, // fix
          wildCardQuery, wildCardQuery, // inventory
        ],
      );

      return List.generate(maps.length, (i) {
        final type = maps[i]['type'] as String;
        final id = maps[i]['id'] as int;
        final title = maps[i]['title'] as String;
        final subtitle = maps[i]['subtitle'] as String;

        IconData icon;
        switch (type) {
          case AuditEntityType.customer:
            icon = Icons.person;
            break;
          case AuditEntityType.purchase:
            icon = Icons.shopping_bag;
            break;
          case AuditEntityType.fix:
            icon = Icons.build;
            break;
          case AuditEntityType.inventory:
            icon = Icons.inventory_2;
            break;
          default:
            icon = Icons.search;
        }

        return SearchResultModel(
          entityType: type,
          entityId: id,
          title: title,
          subtitle: subtitle,
          icon: icon,
        );
      });
    } catch (e) {
      AppLogger.instance.error('Global search query failed', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
