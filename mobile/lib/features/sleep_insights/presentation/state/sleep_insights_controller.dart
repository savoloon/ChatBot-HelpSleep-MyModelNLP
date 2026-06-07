import 'package:flutter/foundation.dart';
import 'package:mobile/features/auth/presentation/state/auth_controller.dart';
import 'package:mobile/features/sleep_insights/data/repositories/remote_sleep_insights_repository.dart';
import 'package:mobile/features/sleep_insights/domain/entities/sleep_insight.dart';

enum SleepInsightsPeriod { week, month, halfYear, year }

class SleepInsightsController extends ChangeNotifier {
  SleepInsightsController({required AuthController authController})
      : _repository =
            RemoteSleepInsightsRepository(authController: authController);

  final RemoteSleepInsightsRepository _repository;

  bool _isLoading = false;
  String? _error;
  SleepInsightsPeriod _period = SleepInsightsPeriod.week;
  List<SleepInsight> _items = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  SleepInsightsPeriod get period => _period;
  List<SleepInsight> get items => List.unmodifiable(_items);

  Future<void> initialize() async {
    await load();
  }

  Future<void> refresh() => load();

  Future<void> changePeriod(SleepInsightsPeriod value) async {
    if (_period == value) return;
    _period = value;
    notifyListeners();
    await load();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repository.loadInsights(period: _periodToApi(_period));
    } catch (err) {
      _error = err.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _periodToApi(SleepInsightsPeriod period) {
    switch (period) {
      case SleepInsightsPeriod.week:
        return 'week';
      case SleepInsightsPeriod.month:
        return 'month';
      case SleepInsightsPeriod.halfYear:
        return 'half_year';
      case SleepInsightsPeriod.year:
        return 'year';
    }
  }
}
