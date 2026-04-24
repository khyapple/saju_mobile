import '../l10n/app_localizations.dart';

class Profile {
  final String id;
  final String name;
  final String? birthDate;
  final String? birthHour;
  final String? birthHourPrecision; // exact | rough | unknown
  final String? gender;
  final String? calendarType; // solar | lunar
  final Map<String, dynamic>? chartData;
  final Map<String, dynamic>? interpretation;
  final bool isOwner;
  final DateTime createdAt;
  final String? relationship;

  Profile({
    required this.id,
    required this.name,
    this.birthDate,
    this.birthHour,
    this.birthHourPrecision,
    this.gender,
    this.calendarType,
    this.chartData,
    this.interpretation,
    this.isOwner = false,
    required this.createdAt,
    this.relationship,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    // Build birth_date from camelCase fields (API) or fall back to snake_case (legacy)
    final birthYear = json['birthYear'] as int?;
    final birthMonth = json['birthMonth'] as int?;
    final birthDay = json['birthDay'] as int?;
    String? birthDate;
    if (birthYear != null && birthMonth != null && birthDay != null) {
      birthDate = '$birthYear-${birthMonth.toString().padLeft(2, '0')}-${birthDay.toString().padLeft(2, '0')}';
    } else {
      birthDate = json['birth_date'] as String?;
    }

    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      birthDate: birthDate,
      birthHour: (json['birthHour'] ?? json['birth_hour'])?.toString(),
      birthHourPrecision: (json['birthTimeType'] ?? json['birth_time_type'] ?? json['birth_hour_precision']) as String?,
      gender: json['gender'] as String?,
      calendarType: (json['calendarType'] ?? json['calendar_type']) as String?,
      chartData: (json['chartData'] ?? json['chart_data']) as Map<String, dynamic>?,
      interpretation: json['interpretation'] as Map<String, dynamic>?,
      isOwner: (json['isOwner'] ?? json['is_owner']) as bool? ?? false,
      createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
      relationship: (json['relationship'])?.toString(),
    );
  }

  /// Locale-aware birth date display, e.g. "1990년 5월 12일" / "May 12, 1990".
  String formattedBirthDate(AppLocalizations l10n) {
    if (birthDate == null) return l10n.noBirthDate;
    return l10n.formatBirthDateIso(birthDate!);
  }

  /// Locale-aware gender display.
  String formattedGender(AppLocalizations l10n) {
    if (gender == null) return '';
    return gender == 'male' ? l10n.male : l10n.female;
  }

  Profile copyWith({Map<String, dynamic>? chartData}) {
    return Profile(
      id: id,
      name: name,
      birthDate: birthDate,
      birthHour: birthHour,
      birthHourPrecision: birthHourPrecision,
      gender: gender,
      calendarType: calendarType,
      chartData: chartData ?? this.chartData,
      interpretation: interpretation,
      isOwner: isOwner,
      createdAt: createdAt,
      relationship: relationship,
    );
  }
}
