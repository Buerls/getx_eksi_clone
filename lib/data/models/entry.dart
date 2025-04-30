// lib/data/models/entry.dart
import 'package:json_annotation/json_annotation.dart';

part 'entry.g.dart'; // Kod üretimi için

@JsonSerializable()
class Entry {
  final int id;
  final int topic; // İlişkili topic ID'si
  @JsonKey(name: 'topic_title', nullable: true) // API'den geliyorsa (serializer'a eklemiştik)
  final String? topicTitle;
  final int author; // Yazar ID'si
  @JsonKey(name: 'author_username')
  final String authorUsername;
  final String content;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  // Oylama sayıları (eğer API'den geliyorsa eklenebilir)
  // final int upvotesCount;
  // final int downvotesCount;

  @JsonKey(name: 'upvotes_count', defaultValue: 0)
  final int upvotesCount;
  @JsonKey(name: 'downvotes_count', defaultValue: 0)
  final int downvotesCount;
  @JsonKey(name: 'current_user_vote', nullable: true)
  final int? currentUserVote; // +1, -1 veya null

  Entry({
    required this.id,
    required this.topic,
    this.topicTitle,
    required this.author,
    required this.authorUsername,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    // required this.upvotesCount,
    // required this.downvotesCount,
    required this.upvotesCount,
    required this.downvotesCount,
    this.currentUserVote,

  });

  bool get isUpvoted => currentUserVote == 1;
  bool get isDownvoted => currentUserVote == -1;

  factory Entry.fromJson(Map<String, dynamic> json) => _$EntryFromJson(json);
  Map<String, dynamic> toJson() => _$EntryToJson(this);

  //copyWith metodu (Optimistic Update için kullanışlı olabilir)
  Entry copyWith({
    int? id, int? topic, String? topicTitle, int? author, String? authorUsername,
    String? content, DateTime? createdAt, DateTime? updatedAt,
    int? upvotesCount, int? downvotesCount, int? currentUserVote, // Nullable int?
  }) {
    return Entry(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      topicTitle: topicTitle ?? this.topicTitle,
      author: author ?? this.author,
      authorUsername: authorUsername ?? this.authorUsername,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      downvotesCount: downvotesCount ?? this.downvotesCount,
      // currentUserVote null olabileceği için farklı ele almak gerekebilir
      // Ama copyWith genelde non-null alanlar içindir veya Optional kullanır.
      // Şimdilik direkt atama yapalım, null ise null olur.
      currentUserVote: currentUserVote ?? this.currentUserVote,
      // Eğer yeni değer null ise eskiyi korumak için `?? this.currentUserVote` EKLENMELİ Mİ?
      // Hayır, copyWith'te parametre verilmezse eski değer kullanılır. Eğer null geçmek istenirse explicit yapılır. Bu haliyle OK.
      // DÜZELTME: copyWith'te bir alanı null yapmak için null göndermek gerekir.
      // Mevcut değeri korumak için parametreyi göndermemek yeterli.
      // Ancak currentUserVote'u null yapmak için bu yapı çalışmaz.
      // Bu yüzden optimistic update'te doğrudan yeni Entry oluşturmak daha iyi.
      // Bu copyWith metodunu optimistic update için KULLANMAYACAĞIZ.
    );
  }

}