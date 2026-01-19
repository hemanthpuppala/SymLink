import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';

enum VerificationStatus {
  notSubmitted,
  pending,
  approved,
  rejected,
}

class VerificationStatusData {
  final VerificationStatus status;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  VerificationStatusData({
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });

  factory VerificationStatusData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return VerificationStatusData(status: VerificationStatus.notSubmitted);
    }

    final statusStr = json['status'] as String? ?? 'not_submitted';
    VerificationStatus status;

    switch (statusStr.toLowerCase()) {
      case 'pending':
        status = VerificationStatus.pending;
        break;
      case 'approved':
        status = VerificationStatus.approved;
        break;
      case 'rejected':
        status = VerificationStatus.rejected;
        break;
      default:
        status = VerificationStatus.notSubmitted;
    }

    return VerificationStatusData(
      status: status,
      rejectionReason: json['rejectionReason'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
    );
  }
}

class VerificationStatusWidget extends StatefulWidget {
  final bool showCompact;
  final VoidCallback? onTap;

  const VerificationStatusWidget({
    super.key,
    this.showCompact = false,
    this.onTap,
  });

  @override
  State<VerificationStatusWidget> createState() => _VerificationStatusWidgetState();
}

class _VerificationStatusWidgetState extends State<VerificationStatusWidget> {
  VerificationStatusData? _statusData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/owner/verification');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        setState(() {
          _statusData = VerificationStatusData.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _statusData = VerificationStatusData(status: VerificationStatus.notSubmitted);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusData = VerificationStatusData(status: VerificationStatus.notSubmitted);
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.showCompact
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
    }

    final status = _statusData?.status ?? VerificationStatus.notSubmitted;

    if (widget.showCompact) {
      return _buildCompactStatus(status);
    }

    return _buildFullStatus(status);
  }

  Widget _buildCompactStatus(VerificationStatus status) {
    final config = _getStatusConfig(status);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 16, color: config.color),
            const SizedBox(width: 4),
            Text(
              config.shortLabel,
              style: TextStyle(
                color: config.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullStatus(VerificationStatus status) {
    final config = _getStatusConfig(status);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              config.icon,
              color: config.color,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: config.color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.subtitle,
                    style: TextStyle(
                      color: config.color,
                      fontSize: 12,
                    ),
                  ),
                  if (status == VerificationStatus.rejected &&
                      _statusData?.rejectionReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${_statusData!.rejectionReason}',
                      style: TextStyle(
                        color: config.color,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.onTap != null)
              Icon(
                Icons.chevron_right,
                color: config.color,
              ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.notSubmitted:
        return _StatusConfig(
          icon: Icons.pending_outlined,
          color: Colors.orange[700]!,
          backgroundColor: Colors.orange[50]!,
          borderColor: Colors.orange[200]!,
          title: 'Not Verified',
          shortLabel: 'Unverified',
          subtitle: 'Submit your documents to get verified',
        );
      case VerificationStatus.pending:
        return _StatusConfig(
          icon: Icons.hourglass_empty,
          color: Colors.blue[700]!,
          backgroundColor: Colors.blue[50]!,
          borderColor: Colors.blue[200]!,
          title: 'Verification Pending',
          shortLabel: 'Pending',
          subtitle: 'Your documents are being reviewed',
        );
      case VerificationStatus.approved:
        return _StatusConfig(
          icon: Icons.verified,
          color: Colors.green[700]!,
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[200]!,
          title: 'Verified',
          shortLabel: 'Verified',
          subtitle: 'Your plant is verified and trusted',
        );
      case VerificationStatus.rejected:
        return _StatusConfig(
          icon: Icons.cancel_outlined,
          color: Colors.red[700]!,
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[200]!,
          title: 'Verification Rejected',
          shortLabel: 'Rejected',
          subtitle: 'Please resubmit with correct documents',
        );
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String shortLabel;
  final String subtitle;

  _StatusConfig({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.shortLabel,
    required this.subtitle,
  });
}
