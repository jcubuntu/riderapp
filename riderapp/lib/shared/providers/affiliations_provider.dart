import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/affiliation_model.dart';
import '../repositories/affiliations_repository.dart';

/// Affiliations repository provider
final affiliationsRepositoryProvider = Provider<AffiliationsRepository>((ref) {
  return AffiliationsRepository();
});

/// Affiliations state
sealed class AffiliationsState {
  const AffiliationsState();
}

class AffiliationsInitial extends AffiliationsState {
  const AffiliationsInitial();
}

class AffiliationsLoading extends AffiliationsState {
  const AffiliationsLoading();
}

class AffiliationsLoaded extends AffiliationsState {
  final List<AffiliationModel> affiliations;

  const AffiliationsLoaded(this.affiliations);
}

class AffiliationsError extends AffiliationsState {
  final String message;

  const AffiliationsError(this.message);
}

/// Affiliations state notifier
class AffiliationsNotifier extends StateNotifier<AffiliationsState> {
  final AffiliationsRepository _repository;

  AffiliationsNotifier(this._repository) : super(const AffiliationsInitial());

  /// Load affiliations from API
  Future<void> loadAffiliations() async {
    state = const AffiliationsLoading();

    try {
      final affiliations = await _repository.getAffiliations();
      state = AffiliationsLoaded(affiliations);
    } on AffiliationsException catch (e) {
      state = AffiliationsError(e.message);
    } catch (e) {
      state = AffiliationsError(e.toString());
    }
  }

  /// Retry loading affiliations
  Future<void> retry() => loadAffiliations();
}

/// Affiliations state notifier provider
final affiliationsProvider =
    StateNotifierProvider<AffiliationsNotifier, AffiliationsState>((ref) {
  final repository = ref.watch(affiliationsRepositoryProvider);
  return AffiliationsNotifier(repository);
});

/// Affiliations list provider (convenience provider)
final affiliationsListProvider = Provider<List<AffiliationModel>>((ref) {
  final state = ref.watch(affiliationsProvider);
  if (state is AffiliationsLoaded) {
    return state.affiliations;
  }
  return [];
});

/// Affiliation names provider (for dropdown)
final affiliationNamesProvider = Provider<List<String>>((ref) {
  final affiliations = ref.watch(affiliationsListProvider);
  return affiliations.map((a) => a.name).toList();
});

/// Is affiliations loading provider
final isAffiliationsLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(affiliationsProvider);
  return state is AffiliationsLoading;
});

/// Affiliations error provider
final affiliationsErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(affiliationsProvider);
  if (state is AffiliationsError) {
    return state.message;
  }
  return null;
});
