import 'package:flutter/material.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/domain/models/squad.dart';
import 'package:squadupv2/domain/repositories/squad_repository.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';

/// ViewModel for managing the list of user's squads
class SquadListViewModel extends ChangeNotifier {
  final SquadRepository _squadRepository;
  final LoggerService _logger;

  List<Squad> _squads = [];
  List<Squad> get squads => _squads;

  String? _currentSquadId;
  String? get currentSquadId => _currentSquadId;

  Squad? get currentSquad {
    if (_currentSquadId == null || _squads.isEmpty) {
      return null;
    }
    try {
      return _squads.firstWhere((s) => s.id == _currentSquadId);
    } catch (_) {
      return _squads.first;
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SquadListViewModel({SquadRepository? squadRepository, LoggerService? logger})
    : _squadRepository = squadRepository ?? locator<SquadRepository>(),
      _logger = logger ?? locator<LoggerService>();

  Future<void> loadSquads() async {
    _isLoading = true;
    notifyListeners();

    try {
      _squads = await _squadRepository.getUserSquads();

      // Set current squad if not set
      if (_currentSquadId == null && _squads.isNotEmpty) {
        _currentSquadId = _squads.first.id;
      }

      _logger.info('Loaded ${_squads.length} squads');
    } catch (e) {
      _logger.error('Failed to load squads', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentSquad(String squadId) {
    if (_squads.any((s) => s.id == squadId)) {
      _currentSquadId = squadId;
      notifyListeners();
    }
  }

  Future<void> refreshSquads() async {
    await loadSquads();
  }
}
