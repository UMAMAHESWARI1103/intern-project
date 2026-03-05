// Place at: lib/services/crowd_service.dart

class CrowdService {
  /// Predict crowd level for a given temple at given time.
  /// Returns: { 'level': String, 'percent': int, 'is_festival': bool }
  Future<Map<String, dynamic>> predictCrowd(
      String templeId, DateTime now) async {
    // Small delay to simulate a real call
    await Future.delayed(const Duration(milliseconds: 300));

    final hour    = now.hour;
    final weekday = now.weekday; // 1=Mon … 7=Sun

    // Festival days (simplified — extend with real DB lookup)
    final isFestival = _isFestivalDay(now);

    String level;

    if (isFestival) {
      level = 'very_high';
    } else if (weekday == 6 || weekday == 7) {
      // Weekend
      if (hour >= 6 && hour < 9) {
        level = 'medium';
      } else if (hour >= 9 && hour < 18)  level = 'very_high';
      else if (hour >= 18 && hour < 21) level = 'high';
      else                               level = 'low';
    } else {
      // Weekday
      if (hour >= 5 && hour < 8) {
        level = 'low';
      } else if (hour >= 8 && hour < 11)  level = 'medium';
      else if (hour >= 11 && hour < 14) level = 'high';
      else if (hour >= 14 && hour < 17) level = 'medium';
      else if (hour >= 17 && hour < 21) level = 'high';
      else                               level = 'low';
    }

    return {
      'level':      level,
      'percent':    _toPercent(level),
      'is_festival': isFestival,
    };
  }

  bool _isFestivalDay(DateTime now) {
    // Simple check: Fridays close to Pournami (full moon ~15th) are festival-ish
    // Replace with real MongoDB festival lookup for production
    if (now.weekday == 5 && now.day >= 13 && now.day <= 16) return true;
    // Major Tamil festival months: January (Pongal), March (Panguni)
    if (now.month == 1 && now.day >= 14 && now.day <= 17) return true;
    return false;
  }

  int _toPercent(String level) {
    switch (level) {
      case 'low':       return 15;
      case 'medium':    return 50;
      case 'high':      return 78;
      case 'very_high': return 95;
      default:          return 50;
    }
  }

  /// Returns "go" | "wait" | "avoid"
  String getGoDecision(String crowdLevel, bool canReach) {
    if (!canReach) return 'avoid';
    switch (crowdLevel) {
      case 'low':       return 'go';
      case 'medium':    return 'go';
      case 'high':      return 'wait';
      case 'very_high': return 'avoid';
      default:          return 'go';
    }
  }

  String getBestTime(String crowdLevel, DateTime now) {
    if (crowdLevel == 'low') return 'Right now is a great time! Peaceful darshan expected.';
    final isWeekend = now.weekday == 6 || now.weekday == 7;
    if (isWeekend) {
      return 'Weekends are crowded. Best: Weekday mornings 6–8 AM or evenings 7–8 PM.';
    }
    if (now.hour >= 11 && now.hour < 17) {
      return 'Afternoon is busy. Visit before 9 AM or after 7 PM for shorter queues.';
    }
    return 'Best times: Early morning 6–8 AM or post-sunset 7–8 PM on weekdays.';
  }
}