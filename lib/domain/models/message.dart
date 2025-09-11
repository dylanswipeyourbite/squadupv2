/// Message types matching database enum
enum MessageType { text, activityCheckin, image, voice, video, poll }

/// Domain model for a squad message
class Message {
  final String id;
  final String squadId;
  final String profileId;
  final MessageType type;
  final String? content;
  final Map<String, dynamic>? metadata;
  final String? replyToId;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;

  // Joined data
  final MessageAuthor? author;
  final Message? replyTo;
  final List<MessageReaction> reactions;
  final List<String> readByProfileIds;

  const Message({
    required this.id,
    required this.squadId,
    required this.profileId,
    required this.type,
    this.content,
    this.metadata,
    this.replyToId,
    this.editedAt,
    this.deletedAt,
    required this.createdAt,
    this.author,
    this.replyTo,
    this.reactions = const [],
    this.readByProfileIds = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      squadId: json['squad_id'] as String,
      profileId: json['profile_id'] as String,
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      replyToId: json['reply_to_id'] as String?,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['author'] != null
          ? MessageAuthor.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      replyTo: json['reply_to'] != null
          ? Message.fromJson(json['reply_to'] as Map<String, dynamic>)
          : null,
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      readByProfileIds:
          (json['read_by_profile_ids'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Author information for a message
class MessageAuthor {
  final String id;
  final String displayName;
  final String? avatarUrl;

  const MessageAuthor({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory MessageAuthor.fromJson(Map<String, dynamic> json) {
    return MessageAuthor(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// Reaction to a message
class MessageReaction {
  final String id;
  final String messageId;
  final String profileId;
  final String emoji;
  final DateTime createdAt;

  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.profileId,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      profileId: json['profile_id'] as String,
      emoji: json['emoji'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Metadata for activity check-in messages
class ActivityCheckInMetadata {
  final String activityType;
  final String? runType;
  final double distanceKm;
  final int durationSeconds;
  final double? paceMinPerKm;
  final int? averageHeartRate;
  final int? sufferScore;
  final double? elevationGainMeters;
  final String? activityId;

  const ActivityCheckInMetadata({
    required this.activityType,
    this.runType,
    required this.distanceKm,
    required this.durationSeconds,
    this.paceMinPerKm,
    this.averageHeartRate,
    this.sufferScore,
    this.elevationGainMeters,
    this.activityId,
  });

  factory ActivityCheckInMetadata.fromJson(Map<String, dynamic> json) {
    return ActivityCheckInMetadata(
      activityType: json['activity_type'] as String,
      runType: json['run_type'] as String?,
      distanceKm: (json['distance_km'] as num).toDouble(),
      durationSeconds: json['duration_seconds'] as int,
      paceMinPerKm: json['pace_min_per_km'] != null
          ? (json['pace_min_per_km'] as num).toDouble()
          : null,
      averageHeartRate: json['average_heart_rate'] as int?,
      sufferScore: json['suffer_score'] as int?,
      elevationGainMeters: json['elevation_gain_meters'] != null
          ? (json['elevation_gain_meters'] as num).toDouble()
          : null,
      activityId: json['activity_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_type': activityType,
      if (runType != null) 'run_type': runType,
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      if (paceMinPerKm != null) 'pace_min_per_km': paceMinPerKm,
      if (averageHeartRate != null) 'average_heart_rate': averageHeartRate,
      if (sufferScore != null) 'suffer_score': sufferScore,
      if (elevationGainMeters != null)
        'elevation_gain_meters': elevationGainMeters,
      if (activityId != null) 'activity_id': activityId,
    };
  }
}

/// Metadata for poll messages
class PollMetadata {
  final String question;
  final List<PollOption> options;
  final DateTime? deadline;
  final bool allowMultiple;
  final List<PollVote> votes;

  const PollMetadata({
    required this.question,
    required this.options,
    this.deadline,
    required this.allowMultiple,
    this.votes = const [],
  });

  factory PollMetadata.fromJson(Map<String, dynamic> json) {
    return PollMetadata(
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((o) => PollOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      allowMultiple: json['allow_multiple'] as bool,
      votes:
          (json['votes'] as List<dynamic>?)
              ?.map((v) => PollVote.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options.map((o) => o.toJson()).toList(),
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      'allow_multiple': allowMultiple,
      'votes': votes.map((v) => v.toJson()).toList(),
    };
  }
}

class PollOption {
  final String id;
  final String text;

  const PollOption({required this.id, required this.text});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(id: json['id'] as String, text: json['text'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text};
  }
}

class PollVote {
  final String profileId;
  final List<String> optionIds;
  final DateTime votedAt;

  const PollVote({
    required this.profileId,
    required this.optionIds,
    required this.votedAt,
  });

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      profileId: json['profile_id'] as String,
      optionIds: (json['option_ids'] as List<dynamic>).cast<String>(),
      votedAt: DateTime.parse(json['voted_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'option_ids': optionIds,
      'voted_at': votedAt.toIso8601String(),
    };
  }
}
