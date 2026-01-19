import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../repositories/notification_repository.dart' as repo;

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsBloc(
        repository: repo.NotificationRepository(
          apiClient: RepositoryProvider.of<ApiClient>(context),
        ),
      )..add(const NotificationsLoadRequested()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    context.read<NotificationsBloc>().add(
                          NotificationsMarkAllAsReadRequested(),
                        );
                  },
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          switch (state.status) {
            case NotificationsStatus.initial:
            case NotificationsStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case NotificationsStatus.failure:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load notifications',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<NotificationsBloc>().add(
                              const NotificationsLoadRequested(refresh: true),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );

            case NotificationsStatus.success:
              if (state.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll be notified about important updates',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationsBloc>().add(
                        const NotificationsLoadRequested(refresh: true),
                      );
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.extentAfter < 100) {
                      context.read<NotificationsBloc>().add(
                            NotificationsLoadMoreRequested(),
                          );
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = state.notifications[index];
                      return _NotificationItem(
                        notification: notification,
                        onTap: () {
                          if (!notification.isRead) {
                            context.read<NotificationsBloc>().add(
                                  NotificationMarkAsReadRequested(
                                    notificationId: notification.id,
                                  ),
                                );
                          }
                          // Handle navigation based on notification type
                          _handleNotificationTap(context, notification);
                        },
                      );
                    },
                  ),
                ),
              );
          }
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, repo.Notification notification) {
    // Handle different notification types
    switch (notification.type) {
      case 'NEW_MESSAGE':
        // Navigate to chat
        break;
      case 'VERIFICATION_APPROVED':
      case 'VERIFICATION_REJECTED':
        // Navigate to verification screen
        break;
      default:
        // Show notification details
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title),
            content: Text(notification.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final repo.Notification notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? null : Colors.blue.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(notification.type),
                color: _getIconColor(notification.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight:
                                notification.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'NEW_MESSAGE':
        return Icons.message;
      case 'VERIFICATION_APPROVED':
        return Icons.verified;
      case 'VERIFICATION_REJECTED':
        return Icons.cancel;
      case 'PLANT_VIEWED':
        return Icons.visibility;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'NEW_MESSAGE':
        return Colors.blue;
      case 'VERIFICATION_APPROVED':
        return Colors.green;
      case 'VERIFICATION_REJECTED':
        return Colors.red;
      case 'PLANT_VIEWED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
