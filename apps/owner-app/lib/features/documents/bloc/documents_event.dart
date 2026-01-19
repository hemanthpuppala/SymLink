import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class DocumentsEvent extends Equatable {
  const DocumentsEvent();

  @override
  List<Object?> get props => [];
}

class DocumentsLoadRequested extends DocumentsEvent {}

class DocumentsRefreshRequested extends DocumentsEvent {}

class DocumentsSubmitRequested extends DocumentsEvent {
  final String plantId;
  final List<File> documents;
  final String? notes;

  const DocumentsSubmitRequested({
    required this.plantId,
    required this.documents,
    this.notes,
  });

  @override
  List<Object?> get props => [plantId, documents, notes];
}

class DocumentsAddFileRequested extends DocumentsEvent {
  final File file;

  const DocumentsAddFileRequested({required this.file});

  @override
  List<Object?> get props => [file];
}

class DocumentsRemoveFileRequested extends DocumentsEvent {
  final int index;

  const DocumentsRemoveFileRequested({required this.index});

  @override
  List<Object?> get props => [index];
}

class DocumentsClearFilesRequested extends DocumentsEvent {}
