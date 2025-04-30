// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Entry _$EntryFromJson(Map<String, dynamic> json) => Entry(
  id: (json['id'] as num).toInt(),
  topic: (json['topic'] as num).toInt(),
  topicTitle: json['topic_title'] as String?,
  author: (json['author'] as num).toInt(),
  authorUsername: json['author_username'] as String,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  upvotesCount: (json['upvotes_count'] as num?)?.toInt() ?? 0,
  downvotesCount: (json['downvotes_count'] as num?)?.toInt() ?? 0,
  currentUserVote: (json['current_user_vote'] as num?)?.toInt(),
);

Map<String, dynamic> _$EntryToJson(Entry instance) => <String, dynamic>{
  'id': instance.id,
  'topic': instance.topic,
  'topic_title': instance.topicTitle,
  'author': instance.author,
  'author_username': instance.authorUsername,
  'content': instance.content,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'upvotes_count': instance.upvotesCount,
  'downvotes_count': instance.downvotesCount,
  'current_user_vote': instance.currentUserVote,
};
