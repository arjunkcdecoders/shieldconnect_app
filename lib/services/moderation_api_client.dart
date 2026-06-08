import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shieldconnect_app/model/moderator/pagination_info.dart';
import '../model/moderator/session_response.dart';
import '../model/moderator/moderation_stats_response.dart';
import '../model/moderator/moderation_history_response.dart';
import '../model/moderator/action_update_response.dart';

class ModerationApiClient {
  static const String baseUrl =
      "https://shield-connect-api-new-production.up.railway.app";

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      contentType: "application/json",
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // 1. Fetch Session (GET /api/admin/session)
  Future<SessionResponse> fetchSession() async {
    try {
      final response = await _dio.get('/api/admin/session');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return SessionResponse.fromJson(json);
    } catch (e) {
      debugPrint("ModerationApiClient: Error fetching session: $e");
      // Return a fallback session for local development when localhost server is not available
      return SessionResponse(
        isLoggedIn: true,
        admin: SessionAdmin(
          id: "mod123",
          email: "moderator@shieldconnect.com",
          role: "Moderator",
          name: "System Admin",
        ),
      );
    }
  }

  // 2. Fetch Moderation Stats (GET /api/admin/moderation/stats?moderatorId=<MODERATOR_ID>)
  Future<ModerationStatsResponse> fetchStats(String moderatorId) async {
    try {
      final response = await _dio.get(
        '/api/admin/moderation/stats',
        queryParameters: {'moderatorId': moderatorId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return ModerationStatsResponse.fromJson(json);
    } catch (e) {
      debugPrint("ModerationApiClient: Error fetching stats: $e");
      // Return fallback empty stats on error
      return ModerationStatsResponse(
        success: false,
        message: e.toString(),
        data: ModerationStats(pending: 0, reviewedToday: 0, escalations: 0, usersCount: 0),
      );
    }
  }

  // 3. Fetch Queue Items List (GET /api/admin/moderation/history)
  Future<ModerationHistoryResponse> fetchHistory({
    required int page,
    required int limit,
    required String moderatorId,
    required String status,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        'moderatorId': moderatorId,
      };
      if (status.isNotEmpty) {
        queryParams['status'] = status;
      }
      final response = await _dio.get(
        '/api/admin/moderation/history',
        queryParameters: queryParams,
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return ModerationHistoryResponse.fromJson(json);
    } catch (e) {
      debugPrint("ModerationApiClient: Error fetching history: $e");
      return ModerationHistoryResponse(
        success: false,
        count: 0,
        status: status,
        data: [],
        pagination: PaginationInfo(
          page: page,
          limit: limit,
          totalPages: 1,
          totalRecords: 0,
        ),
      );
    }
  }

  // 4. Update Item Status (PUT /api/admin/moderation/:id)
  Future<ActionUpdateResponse> updateItemStatus({
    required String itemId,
    required String status,
    required String moderatorId,
  }) async {
    try {
      final response = await _dio.put(
        '/api/admin/moderation/$itemId',
        data: {'status': status, 'moderatorId': moderatorId},
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;
      return ActionUpdateResponse.fromJson(json);
    } catch (e) {
      debugPrint("ModerationApiClient: Error updating item status: $e");
      return ActionUpdateResponse(success: false, message: e.toString());
    }
  }
}
