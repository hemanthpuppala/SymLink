import 'dart:io';
import 'package:equatable/equatable.dart';
import '../repositories/verification_repository.dart';

enum DocumentsStatus {
  initial,
  loading,
  loaded,
  submitting,
  submitted,
  error,
}

class DocumentsState extends Equatable {
  final DocumentsStatus status;
  final List<VerificationRequest> verificationRequests;
  final VerificationRequest? latestRequest;
  final List<File> pendingFiles;
  final String? error;

  const DocumentsState({
    this.status = DocumentsStatus.initial,
    this.verificationRequests = const [],
    this.latestRequest,
    this.pendingFiles = const [],
    this.error,
  });

  bool get hasActiveRequest {
    return latestRequest?.status == 'pending' ||
        latestRequest?.status == 'under_review';
  }

  bool get isVerified {
    return latestRequest?.status == 'approved' ||
        latestRequest?.status == 'verified';
  }

  bool get isRejected {
    return latestRequest?.status == 'rejected';
  }

  String get verificationStatusText {
    if (latestRequest == null) return 'Not Submitted';
    switch (latestRequest!.status) {
      case 'pending':
        return 'Pending Review';
      case 'under_review':
        return 'Under Review';
      case 'approved':
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return latestRequest!.status;
    }
  }

  DocumentsState copyWith({
    DocumentsStatus? status,
    List<VerificationRequest>? verificationRequests,
    VerificationRequest? latestRequest,
    List<File>? pendingFiles,
    String? error,
  }) {
    return DocumentsState(
      status: status ?? this.status,
      verificationRequests: verificationRequests ?? this.verificationRequests,
      latestRequest: latestRequest ?? this.latestRequest,
      pendingFiles: pendingFiles ?? this.pendingFiles,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        verificationRequests,
        latestRequest,
        pendingFiles,
        error,
      ];
}
