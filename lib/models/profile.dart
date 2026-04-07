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

  String get displayBirthDate {
    if (birthDate == null) return '날짜 미입력';
    final parts = birthDate!.split('-');
    if (parts.length != 3) return birthDate!;
    return '${parts[0]}년 ${parts[1]}월 ${parts[2]}일';
  }

  String get displayGender {
    if (gender == null) return '';
    return gender == 'male' ? '남성' : '여성';
  }
}
