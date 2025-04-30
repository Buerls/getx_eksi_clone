// lib/data/models/topic.dart
import 'package:json_annotation/json_annotation.dart';

part 'topic.g.dart';

@JsonSerializable()
class Topic {
  final int id;
  final String title;
  final int author;
  @JsonKey(name: 'author_username')
  final String authorUsername;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // YENİ ALAN EKLENDİ
  @JsonKey(name: 'first_entry_content_display', nullable: true) // JSON'dan null gelebilir
  final String? firstEntryContent; // Nullable String

  Topic({
    required this.id,
    required this.title,
    required this.author,
    required this.authorUsername,
    required this.createdAt,
    this.firstEntryContent, // Constructor'a eklendi (opsiyonel)
  });

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
  Map<String, dynamic> toJson() => _$TopicToJson(this);
}
