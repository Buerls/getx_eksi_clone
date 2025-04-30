// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Topic _$TopicFromJson(Map<String, dynamic> json) => Topic(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  author: (json['author'] as num).toInt(),
  authorUsername: json['author_username'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  firstEntryContent: json['first_entry_content_display'] as String?,
);

Map<String, dynamic> _$TopicToJson(Topic instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'author': instance.author,
  'author_username': instance.authorUsername,
  'created_at': instance.createdAt.toIso8601String(),
  'first_entry_content_display': instance.firstEntryContent,
};
