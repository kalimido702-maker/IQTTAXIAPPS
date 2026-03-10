import 'dart:convert';

/// Represents a POS device transaction parsed from the QR code JSON.
///
/// Example QR JSON:
/// ```json
/// {
///   "RRN": "260108133451",
///   "TransactionName": "SALE",
///   "MerchantName": "UAT Othman",
///   "Date": "08/01/2026",
///   "Time": "01:34:51",
///   "ResponseMessage": "transaction successful",
///   "Amount": "10,500 IQD",
///   "PAN": "522249******7127",
///   "CardType": "CLSS",
///   "SystemTraceAuditNumber": 12,
///   "ResponseCode": "00",
///   "TerminalId": "00400676",
///   "MerchantId": "36858818",
///   "Version": "1.07.224_20251230"
/// }
/// ```
class PosTransactionModel {
  const PosTransactionModel({
    required this.rrn,
    required this.transactionName,
    required this.merchantName,
    required this.date,
    required this.time,
    required this.responseMessage,
    required this.amount,
    required this.pan,
    required this.cardType,
    required this.systemTraceAuditNumber,
    required this.responseCode,
    required this.terminalId,
    required this.merchantId,
    required this.version,
  });

  final String rrn;
  final String transactionName;
  final String merchantName;
  final String date;
  final String time;
  final String responseMessage;
  final String amount;
  final String pan;
  final String cardType;
  final int systemTraceAuditNumber;
  final String responseCode;
  final String terminalId;
  final String merchantId;
  final String version;

  /// Whether the transaction was successful (ResponseCode == "00").
  bool get isSuccessful => responseCode == '00';

  /// Try to parse a raw QR string → [PosTransactionModel].
  /// Returns `null` if the string is not valid POS JSON.
  static PosTransactionModel? tryParse(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PosTransactionModel(
        rrn: json['RRN']?.toString() ?? '',
        transactionName: json['TransactionName']?.toString() ?? '',
        merchantName: json['MerchantName']?.toString() ?? '',
        date: json['Date']?.toString() ?? '',
        time: json['Time']?.toString() ?? '',
        responseMessage: json['ResponseMessage']?.toString() ?? '',
        amount: json['Amount']?.toString() ?? '',
        pan: json['PAN']?.toString() ?? '',
        cardType: json['CardType']?.toString() ?? '',
        systemTraceAuditNumber:
            int.tryParse(json['SystemTraceAuditNumber']?.toString() ?? '') ?? 0,
        responseCode: json['ResponseCode']?.toString() ?? '',
        terminalId: json['TerminalId']?.toString() ?? '',
        merchantId: json['MerchantId']?.toString() ?? '',
        version: json['Version']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
