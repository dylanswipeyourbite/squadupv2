import 'package:squadupv2/domain/models/squad.dart';
import 'package:squadupv2/domain/repositories/squad_repository.dart';
import 'package:squadupv2/infrastructure/helpers/edge_function_helper.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';

/// Implementation of SquadRepository using Edge Functions
class SquadRepositoryImpl implements SquadRepository {
  final _logger = locator<LoggerService>();

  @override
  Future<Squad> createSquad({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    _logger.debug('Creating squad: $name');

    return invokeEdgeFunction(
      functionName: 'squad-create',
      body: {'name': name, 'description': description, 'avatarUrl': avatarUrl},
      parser: (data) => Squad.fromJson(data['squad']),
    );
  }

  @override
  Future<Squad> joinSquad(String inviteCode) async {
    _logger.debug('Joining squad with invite code');

    return invokeEdgeFunction(
      functionName: 'squad-join',
      body: {'inviteCode': inviteCode},
      parser: (data) => Squad.fromJson(data['squad']),
    );
  }

  @override
  Future<Squad?> getSquad(String squadId) async {
    _logger.debug('Getting squad: $squadId');

    try {
      return invokeEdgeFunction(
        functionName: 'squad-get',
        body: {'squadId': squadId},
        parser: (data) => Squad.fromJson(data['squad']),
      );
    } catch (e) {
      _logger.error('Failed to get squad', e);
      return null;
    }
  }

  @override
  Future<List<Squad>> getUserSquads() async {
    _logger.debug('Getting user squads');

    return invokeEdgeFunctionList(
      functionName: 'squad-list',
      body: {},
      itemParser: (data) => Squad.fromJson(data),
    );
  }

  @override
  Future<List<SquadMember>> getSquadMembers(String squadId) async {
    _logger.debug('Getting squad members: $squadId');

    return invokeEdgeFunctionList(
      functionName: 'squad-members',
      body: {'squadId': squadId},
      itemParser: (data) => SquadMember.fromJson(data),
    );
  }

  @override
  Future<Squad> updateSquad(
    String squadId, {
    String? name,
    String? description,
    String? avatarUrl,
    Map<String, String>? expertNames,
  }) async {
    _logger.debug('Updating squad: $squadId');

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (expertNames != null) updates['expertNames'] = expertNames;

    return invokeEdgeFunction(
      functionName: 'squad-update',
      body: {'squadId': squadId, 'updates': updates},
      parser: (data) => Squad.fromJson(data['squad']),
    );
  }

  @override
  Future<void> deleteSquad(String squadId) async {
    _logger.debug('Deleting squad: $squadId');

    await invokeEdgeFunction(
      functionName: 'squad-delete',
      body: {'squadId': squadId},
      parser: (_) => null,
    );
  }

  @override
  Future<void> leaveSquad(String squadId) async {
    _logger.debug('Leaving squad: $squadId');

    await invokeEdgeFunction(
      functionName: 'squad-leave',
      body: {'squadId': squadId},
      parser: (_) => null,
    );
  }

  @override
  Future<String> getInviteCode(String squadId) async {
    _logger.debug('Getting invite code for squad: $squadId');

    return invokeEdgeFunction(
      functionName: 'squad-invite-code',
      body: {'squadId': squadId},
      parser: (data) => data['inviteCode'] as String,
    );
  }

  @override
  Future<bool> isUserCaptain(String squadId) async {
    _logger.debug('Checking if user is captain: $squadId');

    return invokeEdgeFunction(
      functionName: 'squad-check-captain',
      body: {'squadId': squadId},
      parser: (data) => data['isCaptain'] as bool,
    );
  }

  @override
  Future<Map<String, dynamic>> getSquadStats(String squadId) async {
    _logger.debug('Getting squad stats: $squadId');

    return invokeEdgeFunction(
      functionName: 'squad-stats',
      body: {'squadId': squadId},
      parser: (data) => data['stats'] as Map<String, dynamic>,
    );
  }
}
