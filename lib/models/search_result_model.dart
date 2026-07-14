import 'package:flutter/material.dart';

/// Represents a single result from the global search service.
///
/// Produced by [SearchRepository.globalSearch] and displayed in
/// [GlobalSearchScreen]. Tapping a result navigates to the
/// entity-specific screen.
class SearchResultModel {
  /// The type of entity found.
  ///
  /// One of: `'customer'`, `'purchase'`, `'fix'`, `'equipment'`.
  final String entityType;

  /// The primary key of the found record.
  final int entityId;

  /// The main display text (e.g. customer name, machine name).
  final String title;

  /// Secondary display text (e.g. phone, date, status).
  final String subtitle;

  /// Icon representing the entity type.
  final IconData icon;

  const SearchResultModel({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  String toString() =>
      'SearchResultModel(type: $entityType, id: $entityId, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResultModel &&
          runtimeType == other.runtimeType &&
          entityType == other.entityType &&
          entityId == other.entityId;

  @override
  int get hashCode => Object.hash(entityType, entityId);
}
