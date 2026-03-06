part of 'driver_documents_bloc.dart';

enum DriverDocumentsStatus {
  initial,
  loading,
  loaded,
  uploading,
  uploaded,
  error,
}

/// State for the DriverDocuments feature.
class DriverDocumentsState {
  final DriverDocumentsStatus status;
  final List<NeededDocumentModel> documents;
  final String? errorMessage;

  const DriverDocumentsState({
    this.status = DriverDocumentsStatus.initial,
    this.documents = const [],
    this.errorMessage,
  });

  DriverDocumentsState copyWith({
    DriverDocumentsStatus? status,
    List<NeededDocumentModel>? documents,
    String? errorMessage,
  }) {
    return DriverDocumentsState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      errorMessage: errorMessage,
    );
  }
}
