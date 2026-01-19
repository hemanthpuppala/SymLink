import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/verification_repository.dart';
import 'documents_event.dart';
import 'documents_state.dart';

class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  final VerificationRepository _verificationRepository;

  DocumentsBloc({required VerificationRepository verificationRepository})
      : _verificationRepository = verificationRepository,
        super(const DocumentsState()) {
    on<DocumentsLoadRequested>(_onLoadRequested);
    on<DocumentsRefreshRequested>(_onRefreshRequested);
    on<DocumentsSubmitRequested>(_onSubmitRequested);
    on<DocumentsAddFileRequested>(_onAddFileRequested);
    on<DocumentsRemoveFileRequested>(_onRemoveFileRequested);
    on<DocumentsClearFilesRequested>(_onClearFilesRequested);
  }

  Future<void> _onLoadRequested(
    DocumentsLoadRequested event,
    Emitter<DocumentsState> emit,
  ) async {
    emit(state.copyWith(status: DocumentsStatus.loading));
    await _loadVerificationRequests(emit);
  }

  Future<void> _onRefreshRequested(
    DocumentsRefreshRequested event,
    Emitter<DocumentsState> emit,
  ) async {
    await _loadVerificationRequests(emit);
  }

  Future<void> _loadVerificationRequests(Emitter<DocumentsState> emit) async {
    try {
      final requests = await _verificationRepository.getVerificationRequests();

      // Sort by created date, most recent first
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(state.copyWith(
        status: DocumentsStatus.loaded,
        verificationRequests: requests,
        latestRequest: requests.isNotEmpty ? requests.first : null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentsStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitRequested(
    DocumentsSubmitRequested event,
    Emitter<DocumentsState> emit,
  ) async {
    emit(state.copyWith(status: DocumentsStatus.submitting));
    try {
      final request = await _verificationRepository.submitVerification(
        plantId: event.plantId,
        documents: event.documents,
        notes: event.notes,
      );

      emit(state.copyWith(
        status: DocumentsStatus.submitted,
        latestRequest: request,
        verificationRequests: [request, ...state.verificationRequests],
        pendingFiles: [],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentsStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onAddFileRequested(
    DocumentsAddFileRequested event,
    Emitter<DocumentsState> emit,
  ) {
    final updatedFiles = [...state.pendingFiles, event.file];
    emit(state.copyWith(pendingFiles: updatedFiles));
  }

  void _onRemoveFileRequested(
    DocumentsRemoveFileRequested event,
    Emitter<DocumentsState> emit,
  ) {
    final updatedFiles = List.of(state.pendingFiles)..removeAt(event.index);
    emit(state.copyWith(pendingFiles: updatedFiles));
  }

  void _onClearFilesRequested(
    DocumentsClearFilesRequested event,
    Emitter<DocumentsState> emit,
  ) {
    emit(state.copyWith(pendingFiles: []));
  }
}
