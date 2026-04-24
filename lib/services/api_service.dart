import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/config.dart';
import '../models/profile.dart';
import '../models/chat_message.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get _base => AppConfig.apiBaseUrl;

  /// App locale ("ko" or "en"). Kept in sync by [LocaleProvider].
  /// Sent to the backend via `Accept-Language` so generated AI content
  /// (interpretation sections, chat replies) can match the user's language.
  static String currentLocale = 'ko';

  Future<Map<String, String>> _authHeaders() async {
    final session = Supabase.instance.client.auth.currentSession;
    final base = <String, String>{
      'Content-Type': 'application/json',
      'Accept-Language': currentLocale,
    };
    if (session == null) {
      debugPrint('=== AUTH: session is NULL - no token sent');
      return base;
    }
    debugPrint('=== AUTH: token present, expires at ${session.expiresAt}');
    return {
      ...base,
      'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  static const _timeout = Duration(seconds: 15);

  // ─── 프로필 목록 ───────────────────────────────────────────
  Future<List<Profile>> getProfiles() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_base/api/profiles'),
      headers: headers,
    ).timeout(_timeout, onTimeout: () => throw Exception('서버 연결 시간이 초과됐습니다. 백엔드 서버가 실행 중인지 확인해주세요.'));
    debugPrint('=== GET /api/profiles status: ${res.statusCode}');
    debugPrint('=== body: ${res.body}');
    if (res.statusCode != 200) throw Exception('프로필 로드 실패');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final List<dynamic> data = body['profiles'] as List<dynamic>? ?? [];
    return data
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── 프로필 상세 ───────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile(String profileId) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_base/api/profiles/$profileId'),
      headers: headers,
    ).timeout(_timeout, onTimeout: () => throw Exception('서버 연결 시간이 초과됐습니다.'));
    debugPrint('=== GET /api/profiles/${profileId} status: ${res.statusCode}');
    if (res.statusCode != 200) throw Exception('프로필 로드 실패');
    final outer = jsonDecode(res.body) as Map<String, dynamic>;
    final profile = outer['profile'] as Map<String, dynamic>;
    debugPrint('=== chartData present: ${profile['chartData'] != null}, keys: ${profile.keys.toList()}');

    // Construct birth_date from camelCase year/month/day for screen compatibility
    final birthYear = (profile['birthYear'] as num?)?.toInt();
    final birthMonth = (profile['birthMonth'] as num?)?.toInt();
    final birthDay = (profile['birthDay'] as num?)?.toInt();
    final birthDate = (birthYear != null && birthMonth != null && birthDay != null)
        ? '$birthYear-${birthMonth.toString().padLeft(2, '0')}-${birthDay.toString().padLeft(2, '0')}'
        : null;

    debugPrint('=== profile fields: birthYear=$birthYear, gender=${profile['gender']}, calendarType=${profile['calendarType']}');

    return {
      ...profile,
      // 정규화된 int 값으로 덮어쓰기 (혹시 모를 num/double 캐스트 실패 방지)
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      if (birthDay != null) 'birthDay': birthDay,
      'birth_date': birthDate,
      'chart_data': profile['chartData'],
      'calendar_type': profile['calendarType'],
      'is_owner': profile['isOwner'],
      'created_at': profile['createdAt'],
      'birth_time_type': profile['birthTimeType'],
    };
  }

  // ─── 프로필 생성 ───────────────────────────────────────────
  Future<Map<String, dynamic>> createProfile({
    required String name,
    required String birthDate,
    required String? birthHour,
    required String birthHourPrecision,
    required String gender,
    required String calendarType,
    String? relationship,
  }) async {
    final headers = await _authHeaders();

    // Parse birthDate (YYYY-MM-DD)
    final parts = birthDate.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final hour = birthHour != null ? int.tryParse(birthHour) : null;

    // Step 1: Calculate saju chart
    final calcRes = await http.post(
      Uri.parse('$_base/api/calculate'),
      headers: headers,
      body: jsonEncode({
        'year': year,
        'month': month,
        'day': day,
        if (hour != null) 'hour': hour,
        'gender': gender,
        'calendarType': calendarType,
      }),
    ).timeout(_timeout, onTimeout: () => throw Exception('서버 연결 시간이 초과됐습니다.'));
    if (calcRes.statusCode != 200) throw Exception('사주 계산 실패');
    final chartData = jsonDecode(calcRes.body) as Map<String, dynamic>;

    // Step 2: Save profile
    final res = await http.post(
      Uri.parse('$_base/api/profiles'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'chartData': chartData,
        'isOwner': false,
        'birthTimeType': birthHourPrecision,
        if (relationship != null) 'relationship': relationship,
      }),
    ).timeout(_timeout, onTimeout: () => throw Exception('서버 연결 시간이 초과됐습니다.'));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('프로필 생성 실패');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── 프로필 삭제 ───────────────────────────────────────────
  Future<void> deleteProfile(String profileId) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$_base/api/profiles/$profileId'),
      headers: headers,
    );
    if (res.statusCode != 200) throw Exception('프로필 삭제 실패');
  }

  // ─── 해석 생성 ─────────────────────────────────────────────
  Future<String> interpretProfile(String profileId) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/api/profiles/$profileId/interpret'),
      headers: headers,
    );
    if (res.statusCode != 200) throw Exception('해석 생성 실패');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['interpretation'] as String? ?? '';
  }

  // ─── 해석 생성 (SSE 스트림 완료까지 대기, 완료 시 DB에 저장됨) ────────────────────
  Future<void> triggerInterpretation(String profileId) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/api/profiles/$profileId/interpret'),
      headers: headers,
    ).timeout(const Duration(seconds: 180));
    if (res.statusCode != 200) {
      throw Exception('해석 생성 실패 (${res.statusCode})');
    }
    // SSE 스트림 종료 = 해석이 DB에 저장 완료됨. 호출 측에서 프로필 재조회 필요.
  }

  // ─── 채팅 세션 목록 조회 ────────────────────────────────────
  Future<List<Map<String, dynamic>>> getChatSessions(String profileId) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_base/api/profiles/$profileId/chat'),
      headers: headers,
    ).timeout(_timeout, onTimeout: () => throw Exception('서버 연결 시간이 초과됐습니다.'));
    if (res.statusCode != 200) throw Exception('채팅 세션 목록 로드 실패');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['sessions'] as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ─── 채팅 세션 생성 ────────────────────────────────────────
  Future<Map<String, dynamic>> createChatSession(
    String profileId, {
    String? compatibilityProfileId,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (compatibilityProfileId != null) {
      body['compatibilityProfileId'] = compatibilityProfileId;
    }
    final res = await http.post(
      Uri.parse('$_base/api/profiles/$profileId/chat'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('채팅 세션 생성 실패');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── 채팅 세션 업데이트 (제목/고정) ────────────────────────
  Future<void> updateChatSession(
    String profileId,
    String sessionId, {
    String? title,
    bool? pinned,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (pinned != null) body['pinned'] = pinned;
    final url = '$_base/api/profiles/$profileId/chat?sessionId=$sessionId';
    final payload = jsonEncode(body);
    final res = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: payload,
    );
    if (res.statusCode != 200) {
      // Short, actionable error text first so the floating toast is readable.
      final snippet = res.body.length > 180 ? '${res.body.substring(0, 180)}…' : res.body;
      throw Exception('[${res.statusCode}] $snippet');
    }
  }

  // ─── 채팅 세션 삭제 ────────────────────────────────────────
  Future<void> deleteChatSession(String profileId, String sessionId) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$_base/api/profiles/$profileId/chat?sessionId=$sessionId'),
      headers: headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('채팅 세션 삭제 실패 (${res.statusCode}): ${res.body}');
    }
  }

  // ─── 채팅 메시지 전송 (SSE 스트리밍 응답을 누적해서 반환) ──────
  Future<String> sendMessage(
    String sessionId,
    String message, {
    required String chartContext,
    required String interpretation,
    required List<Map<String, String>> history,
  }) async {
    final headers = await _authHeaders();
    final request = http.Request('POST', Uri.parse('$_base/api/chat'));
    request.headers.addAll(headers);
    request.body = jsonEncode({
      'sessionId': sessionId,
      'message': message,
      'history': history,
      'chartContext': chartContext,
      'interpretation': interpretation,
    });

    final client = http.Client();
    try {
      debugPrint('=== api.sendMessage: client.send starting, body bytes=${request.body.length}');
      final streamed = await client.send(request).timeout(const Duration(seconds: 120));
      debugPrint('=== api.sendMessage: response status=${streamed.statusCode}');
      if (streamed.statusCode != 200) {
        final body = await streamed.stream.bytesToString();
        debugPrint('=== chat error ${streamed.statusCode}: $body');
        throw Exception('메시지 전송 실패 (${streamed.statusCode}): $body');
      }
      // SSE/text-stream 청크를 누적
      final buffer = StringBuffer();
      int chunkCount = 0;
      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        chunkCount++;
        buffer.write(chunk);
      }
      debugPrint('=== api.sendMessage: stream complete, chunks=$chunkCount, total=${buffer.length}');
      return buffer.toString();
    } catch (e) {
      debugPrint('=== api.sendMessage exception: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // ─── 채팅 히스토리 ─────────────────────────────────────────
  Future<List<ChatMessage>> getChatHistory(String sessionId) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_base/api/chat/session?id=$sessionId'),
      headers: headers,
    );
    if (res.statusCode != 200) throw Exception('채팅 히스토리 로드 실패');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final messages = data['messages'] as List<dynamic>? ?? [];
    return messages
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── 온보딩 단계 업데이트 ──────────────────────────────────
  Future<void> updateOnboardingStep(String step) async {
    final headers = await _authHeaders();
    await http.patch(
      Uri.parse('$_base/api/onboarding/step'),
      headers: headers,
      body: jsonEncode({'step': step}),
    );
  }

  // ─── 구독 정보 ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getSubscription() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_base/api/subscription'),
      headers: headers,
    );
    if (res.statusCode != 200) throw Exception('구독 정보 로드 실패');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── 생활 이벤트 목록 ──────────────────────────────────────
  Future<List<Map<String, dynamic>>> getEvents(String profileId) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_base/api/profiles/$profileId/events'),
      headers: headers,
    ).timeout(_timeout, onTimeout: () => throw Exception('서버 연결 시간이 초과됐습니다.'));
    if (res.statusCode != 200) throw Exception('이벤트 로드 실패');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['events'] as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ─── 생활 이벤트 추가 ──────────────────────────────────────
  Future<void> addEvent(
    String profileId, {
    required int eventYear,
    required String description,
    required String impact,
    int? eventMonth,
    String? category,
    String? title,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/api/profiles/$profileId/events'),
      headers: headers,
      body: jsonEncode({
        'eventYear': eventYear,
        'description': description,
        'impact': impact,
        if (eventMonth != null) 'eventMonth': eventMonth,
        if (category != null) 'category': category,
        if (title != null && title.isNotEmpty) 'title': title,
      }),
    ).timeout(_timeout, onTimeout: () => throw Exception('서버 연결 시간이 초과됐습니다.'));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('이벤트 추가 실패');
    }
  }

  // ─── 생활 이벤트 수정 ──────────────────────────────────────
  Future<void> updateEvent(
    String profileId, {
    required String eventId,
    int? eventYear,
    int? eventMonth,
    String? description,
    String? impact,
    String? category,
    String? title,
  }) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$_base/api/profiles/$profileId/events'),
      headers: headers,
      body: jsonEncode({
        'eventId': eventId,
        if (eventYear != null) 'eventYear': eventYear,
        if (eventMonth != null) 'eventMonth': eventMonth,
        if (description != null) 'description': description,
        if (impact != null) 'impact': impact,
        if (category != null) 'category': category,
        if (title != null) 'title': title,
      }),
    ).timeout(_timeout, onTimeout: () => throw Exception('서버 연결 시간이 초과됐습니다.'));
    if (res.statusCode != 200) {
      throw Exception('이벤트 수정 실패');
    }
  }

  // ─── 생활 이벤트 삭제 ──────────────────────────────────────
  Future<void> deleteEvent(String profileId, String eventId) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$_base/api/profiles/$profileId/events?eventId=$eventId'),
      headers: headers,
    ).timeout(_timeout, onTimeout: () => throw Exception('서버 연결 시간이 초과됐습니다.'));
    if (res.statusCode != 200) throw Exception('이벤트 삭제 실패');
  }

  // ─── 프로필 수정 ───────────────────────────────────────────
  Future<Map<String, dynamic>> updateProfile(
    String profileId,
    Map<String, dynamic> updates,
  ) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$_base/api/profiles/$profileId'),
      headers: headers,
      body: jsonEncode(updates),
    ).timeout(_timeout, onTimeout: () => throw Exception('서버 연결 시간이 초과됐습니다.'));
    if (res.statusCode != 200) throw Exception('프로필 수정 실패');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
