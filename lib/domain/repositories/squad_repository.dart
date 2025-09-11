import 'package:squadupv2/domain/models/squad.dart';

/// Abstract repository interface for squad operations
abstract class SquadRepository {
  /// Create a new squad
  Future<Squad> createSquad({
    required String name,
    String? description,
    String? avatarUrl,
  });

  /// Join a squad using invite code
  Future<Squad> joinSquad(String inviteCode);

  /// Get squad by ID
  Future<Squad?> getSquad(String squadId);

  /// Get all squads for current user
  Future<List<Squad>> getUserSquads();

  /// Get squad members
  Future<List<SquadMember>> getSquadMembers(String squadId);

  /// Update squad (captain only)
  Future<Squad> updateSquad(
    String squadId, {
    String? name,
    String? description,
    String? avatarUrl,
    Map<String, String>? expertNames,
  });

  /// Delete squad (captain only)
  Future<void> deleteSquad(String squadId);

  /// Leave squad
  Future<void> leaveSquad(String squadId);

  /// Get squad invite code (captain only)
  Future<String> getInviteCode(String squadId);

  /// Check if user is captain
  Future<bool> isUserCaptain(String squadId);

  /// Get squad stats
  Future<Map<String, dynamic>> getSquadStats(String squadId);
}
