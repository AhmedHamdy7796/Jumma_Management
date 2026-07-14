import 'package:gomaa_management/database/database_constants.dart';

/// Represents a freeform note, optionally attached to another entity.
///
/// When [entityType] and [entityId] are null, the note is standalone.
/// When set, the note is linked to a customer, purchase, fix, or equipment.
class NoteModel {
  final int? id;
  final String title;
  final String content;

  /// Optional: `'customer'`, `'purchase'`, `'fix'`, `'equipment'`, or null.
  final String? entityType;

  /// Optional: the ID of the linked entity.
  final int? entityId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.entityType,
    this.entityId,
  });

  bool get isStandalone => entityType == null;

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      NoteColumns.id: id,
      NoteColumns.title: title,
      NoteColumns.content: content,
      NoteColumns.entityType: entityType,
      NoteColumns.entityId: entityId,
      NoteColumns.createdAt: createdAt.toIso8601String(),
      NoteColumns.updatedAt: updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map[NoteColumns.id] as int?,
      title: map[NoteColumns.title] as String,
      content: map[NoteColumns.content] as String? ?? '',
      entityType: map[NoteColumns.entityType] as String?,
      entityId: map[NoteColumns.entityId] as int?,
      createdAt: DateTime.parse(map[NoteColumns.createdAt] as String),
      updatedAt: DateTime.parse(map[NoteColumns.updatedAt] as String),
    );
  }

  // ── Immutable copy ────────────────────────────────────────────────────────

  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? entityType,
    int? entityId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'NoteModel(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
