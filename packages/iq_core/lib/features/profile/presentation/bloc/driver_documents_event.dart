part of 'driver_documents_bloc.dart';

/// Events for the DriverDocuments feature.
sealed class DriverDocumentsEvent {
  const DriverDocumentsEvent();
}

/// Load the list of needed / uploaded documents.
class DriverDocumentsLoadRequested extends DriverDocumentsEvent {
  const DriverDocumentsLoadRequested();
}

/// Upload a document file.
class DriverDocumentUploadRequested extends DriverDocumentsEvent {
  final String documentId;
  final String filePath;
  final String? backFilePath;
  final String? identifyNumber;
  final String? expiryDate;

  const DriverDocumentUploadRequested({
    required this.documentId,
    required this.filePath,
    this.backFilePath,
    this.identifyNumber,
    this.expiryDate,
  });
}
