import 'package:equatable/equatable.dart';

/// A single document entry from the `api/v1/driver/documents/needed` API.
class NeededDocumentModel extends Equatable {
  const NeededDocumentModel({
    required this.id,
    required this.name,
    this.docType,
    this.hasIdNumber = false,
    this.hasExpiryDate = false,
    this.isUploaded = false,
    this.isEditable = false,
    this.isRequired = true,
    this.isFrontAndBack = false,
    this.documentStatus,
    this.statusString,
    this.documentImageUrl,
    this.backDocumentImageUrl,
  });

  final String id;
  final String name;
  final String? docType;
  final bool hasIdNumber;
  final bool hasExpiryDate;
  final bool isUploaded;
  final bool isEditable;
  final bool isRequired;
  final bool isFrontAndBack;
  final String? documentStatus;
  final String? statusString;
  final String? documentImageUrl;
  final String? backDocumentImageUrl;

  factory NeededDocumentModel.fromJson(Map<String, dynamic> json) {
    // document_status & document_status_string are TOP-LEVEL fields.
    // The uploaded document images live inside json['driver_document']['data'].
    final driverDoc = json['driver_document'] as Map<String, dynamic>?;
    final driverDocData = driverDoc?['data'] as Map<String, dynamic>?;

    return NeededDocumentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      docType: json['doc_type']?.toString(),
      hasIdNumber: json['has_identify_number'] == true ||
          json['has_identify_number'] == 1,
      hasExpiryDate: json['has_expiry_date'] == true ||
          json['has_expiry_date'] == 1,
      isUploaded: json['is_uploaded'] == true || json['is_uploaded'] == 1,
      isEditable: json['is_editable'] == true || json['is_editable'] == 1,
      isRequired: json['is_required'] == true ||
          json['is_required'] == 1 ||
          json['is_required'] == null,
      isFrontAndBack: json['is_front_and_back'] == true ||
          json['is_front_and_back'] == 1,
      documentStatus: json['document_status']?.toString(),
      statusString: json['document_status_string']?.toString(),
      documentImageUrl: driverDocData?['document']?.toString(),
      backDocumentImageUrl: driverDocData?['back_document']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, isUploaded, statusString];
}
