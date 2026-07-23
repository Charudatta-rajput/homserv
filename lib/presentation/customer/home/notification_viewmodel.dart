import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/notification.dart';

enum NotificationStateStatus { initial, loading, loaded, error }

class NotificationViewModel extends ChangeNotifier {
  NotificationStateStatus _status = NotificationStateStatus.initial;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  String? _errorMessage;

  NotificationStateStatus get status => _status;
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;

  final SupabaseClient _supabase = Supabase.instance.client;
  String? _userId;

  void setUserId(String userId) {
    _userId = userId;
  }

  Future<void> loadNotifications() async {
    final userId = _userId;
    if (userId == null) return;
    _status = NotificationStateStatus.loading;
    notifyListeners();

    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)  // ✅ userId is non-nullable String
          .order('created_at', ascending: false)
          .limit(20);

      _notifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
      _updateUnreadCount();
      _status = NotificationStateStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = NotificationStateStatus.error;
      _errorMessage = 'Failed to load notifications.';
      debugPrint('Notification load error: $e');
    }
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          bookingId: _notifications[index].bookingId,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          actionData: _notifications[index].actionData,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      _notifications = _notifications.map((n) {
        return AppNotification(
          id: n.id,
          userId: n.userId,
          bookingId: n.bookingId,
          type: n.type,
          title: n.title,
          message: n.message,
          actionData: n.actionData,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Mark all as read error: $e');
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  void resetError() {
    if (_status == NotificationStateStatus.error) {
      _status = NotificationStateStatus.loaded;
      notifyListeners();
    }
  }
}