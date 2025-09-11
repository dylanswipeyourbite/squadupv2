import 'package:freezed_annotation/freezed_annotation.dart';

part 'squad.freezed.dart';
part 'squad.g.dart';

/// Squad model representing a training group
@freezed
class Squad with _$Squad {
  const factory Squad({
    required String id,
    required String name,
    String? description,
    required String inviteCode,
    required String visibility, // 'private' or 'public'
    int? maxMembers,
    required int memberCount,
    String? avatarUrl,
    String? themeColor,
    required Map<String, String> expertNames,
    required double totalDistanceKm,
    required int totalActivities,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Squad;

  factory Squad.fromJson(Map<String, dynamic> json) => _$SquadFromJson(json);
}

/// Squad member role enum
enum SquadRole {
  captain('captain'),
  member('member');

  final String value;
  const SquadRole(this.value);

  static SquadRole fromString(String value) {
    return SquadRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => SquadRole.member,
    );
  }
}

/// Squad member model
@freezed
class SquadMember with _$SquadMember {
  const factory SquadMember({
    required String id,
    required String squadId,
    required String profileId,
    required String displayName,
    String? avatarUrl,
    required SquadRole role,
    required DateTime joinedAt,
    required int totalActivities,
    required double totalDistanceKm,
    DateTime? lastActivityAt,
    required bool notificationsEnabled,
  }) = _SquadMember;

  factory SquadMember.fromJson(Map<String, dynamic> json) =>
      _$SquadMemberFromJson(json);
}
