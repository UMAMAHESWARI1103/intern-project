// Place at: lib/models/temple_suggestion.dart

class TempleSuggestion {
  final bool canReach;
  final String crowdLevel;
  final int crowdPercent;
  final String bestTimeToVisit;
  final String estimatedDuration;
  final String distanceKm;
  final List<String> warnings;
  final String recommendation;
  final String goDecision;

  const TempleSuggestion({
    required this.canReach,
    required this.crowdLevel,
    required this.crowdPercent,
    required this.bestTimeToVisit,
    required this.estimatedDuration,
    required this.distanceKm,
    required this.warnings,
    required this.recommendation,
    required this.goDecision,
  });
}