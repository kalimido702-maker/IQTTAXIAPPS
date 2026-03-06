import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/driver_documents_data_source.dart';
import '../../data/models/needed_document_model.dart';

part 'driver_documents_event.dart';
part 'driver_documents_state.dart';

/// BLoC for managing driver verification documents.
class DriverDocumentsBloc
    extends Bloc<DriverDocumentsEvent, DriverDocumentsState> {
  final DriverDocumentsDataSource dataSource;

  DriverDocumentsBloc({required this.dataSource})
      : super(const DriverDocumentsState()) {
    on<DriverDocumentsLoadRequested>(_onLoadRequested);
    on<DriverDocumentUploadRequested>(_onUploadRequested);
  }

  Future<void> _onLoadRequested(
    DriverDocumentsLoadRequested event,
    Emitter<DriverDocumentsState> emit,
  ) async {
    emit(state.copyWith(status: DriverDocumentsStatus.loading));

    final result = await dataSource.getNeededDocuments();

    result.fold(
      (failure) => emit(state.copyWith(
        status: DriverDocumentsStatus.error,
        errorMessage: failure.message,
      )),
      (documents) => emit(state.copyWith(
        status: DriverDocumentsStatus.loaded,
        documents: documents,
      )),
    );
  }

  Future<void> _onUploadRequested(
    DriverDocumentUploadRequested event,
    Emitter<DriverDocumentsState> emit,
  ) async {
    emit(state.copyWith(status: DriverDocumentsStatus.uploading));

    final result = await dataSource.uploadDocument(
      documentId: event.documentId,
      filePath: event.filePath,
      backFilePath: event.backFilePath,
      identifyNumber: event.identifyNumber,
      expiryDate: event.expiryDate,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: DriverDocumentsStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: DriverDocumentsStatus.uploaded));
        // Reload the documents list after upload.
        add(const DriverDocumentsLoadRequested());
      },
    );
  }
}
