import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction.dart';

class SmsTransactionResult {
  final String? rawSms;
  final Transaction? transaction;
  final bool success;
  final String? error;

  SmsTransactionResult({
    this.rawSms,
    this.transaction,
    required this.success,
    this.error,
  });
}

class SmsService {
  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasSmsPermission() async {
    return await Permission.sms.isGranted;
  }

  SmsTransactionResult parseSms(String message, String userId) {
    message = message.toUpperCase();

    final creditPatterns = [
      RegExp(r'(?:CREDITED|CREDIT|DEPOSIT)\s*(?:RS|INR|₹)?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'(?:RS|INR|₹)\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s*(?:CREDITED|CREDIT|DEPOSIT)'),
      RegExp(r'CREDIT[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'(?:AC|ACCOUNT)\s*(?:CREDITED|CREDIT)[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'DEPOSIT[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'SALARY[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'REFUND[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
    ];

    final debitPatterns = [
      RegExp(r'(?:DEBITED|DEBIT|WITHDRAWAL|SPENT|PAID)\s*(?:RS|INR|₹)?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'(?:RS|INR|₹)\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s*(?:DEBITED|DEBIT|WITHDRAWAL)'),
      RegExp(r'DEBIT[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'(?:AC|ACCOUNT)\s*(?:DEBITED|DEBIT)[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'WITHDRAWAL[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'PAID[^0-9]*(?:RS|INR|₹)?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'PURCHASE[^0-9]*(?:RS|INR|₹)?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'TRANSFER[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
    ];

    final upiPatterns = [
      RegExp(r'UPI[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'PAYTM[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'GPay[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
      RegExp(r'PHONEPE[^0-9]*(\d+(?:,\d+)*(?:\.\d{1,2})?)'),
    ];

    String cleanAmount(String raw) {
      return raw.replaceAll(',', '');
    }

    TransactionCategory inferCategory(String message) {
      if (message.contains('FOOD') || message.contains('RESTAURANT') ||
          message.contains('SWIGGY') || message.contains('ZOMATO') ||
          message.contains('DINING') || message.contains('EAT') ||
          message.contains('GROCERY')) {
        return TransactionCategory.food;
      }
      if (message.contains('TRAVEL') || message.contains('FLIGHT') ||
          message.contains('HOTEL') || message.contains('OYO') ||
          message.contains('BUS') || message.contains('TRAIN') ||
          message.contains('CAB') || message.contains('UBER') ||
          message.contains('OLA') || message.contains('RAIL')) {
        return TransactionCategory.travel;
      }
      if (message.contains('SHOP') || message.contains('AMAZON') ||
          message.contains('FLIPKART') || message.contains('MYNTRA') ||
          message.contains('MALL') || message.contains('RETAIL') ||
          message.contains('CLOTH') || message.contains('ONLINE')) {
        return TransactionCategory.shopping;
      }
      if (message.contains('BILL') || message.contains('ELECTRICITY') ||
          message.contains('WATER') || message.contains('GAS') ||
          message.contains('PHONE') || message.contains('RECHARGE') ||
          message.contains('INTERNET') || message.contains('DTH') ||
          message.contains('RENT') || message.contains('TAX')) {
        return TransactionCategory.bills;
      }
      if (message.contains('MEDICAL') || message.contains('HOSPITAL') ||
          message.contains('DOCTOR') || message.contains('CLINIC') ||
          message.contains('PHARMA') || message.contains('MEDICINE') ||
          message.contains('HEALTH') || message.contains('INSURANCE')) {
        return TransactionCategory.medical;
      }
      return TransactionCategory.others;
    }

    String inferTitle(String message, TransactionType type, TransactionCategory category) {
      final merchantPatterns = [
        RegExp(r'(?:TO|AT|VIA|BY)\s+([A-Z\s]+?)(?:\s+(?:ON|REF|BAL|AVAIL|IS|RS|INR|₹|\d))'),
        RegExp(r'(?:AT|TO)\s+([A-Z][A-Z\s&]+?)(?:\s+(?:ON|AT))'),
      ];

      for (final pattern in merchantPatterns) {
        final match = pattern.firstMatch(message);
        if (match != null) {
          return match.group(1)!.trim();
        }
      }

      if (type == TransactionType.credit) {
        if (message.contains('SALARY')) return 'Salary';
        if (message.contains('REFUND')) return 'Refund';
        if (message.contains('CREDIT')) return 'Credit Received';
        return 'Income';
      } else {
        return '${category.label} Purchase';
      }
    }

    for (final pattern in creditPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final amountStr = cleanAmount(match.group(1)!);
        final amount = double.tryParse(amountStr);
        if (amount != null) {
          final category = inferCategory(message);
          return SmsTransactionResult(
            rawSms: message,
            transaction: Transaction(
              title: inferTitle(message, TransactionType.credit, category),
              amount: amount,
              type: TransactionType.credit,
              category: category,
              date: DateTime.now(),
              smsSource: message.substring(0, message.length > 100 ? 100 : message.length),
              userId: userId,
            ),
            success: true,
          );
        }
      }
    }

    for (final pattern in debitPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final amountStr = cleanAmount(match.group(1)!);
        final amount = double.tryParse(amountStr);
        if (amount != null) {
          final category = inferCategory(message);
          return SmsTransactionResult(
            rawSms: message,
            transaction: Transaction(
              title: inferTitle(message, TransactionType.debit, category),
              amount: amount,
              type: TransactionType.debit,
              category: category,
              date: DateTime.now(),
              smsSource: message.substring(0, message.length > 100 ? 100 : message.length),
              userId: userId,
            ),
            success: true,
          );
        }
      }
    }

    for (final pattern in upiPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final amountStr = cleanAmount(match.group(1)!);
        final amount = double.tryParse(amountStr);
        if (amount != null) {
          final isCredit = message.contains('CREDIT') || message.contains('RECEIVED') || message.contains('REFUND');
          final type = isCredit ? TransactionType.credit : TransactionType.debit;
          final category = inferCategory(message);
          return SmsTransactionResult(
            rawSms: message,
            transaction: Transaction(
              title: inferTitle(message, type, category),
              amount: amount,
              type: type,
              category: category,
              date: DateTime.now(),
              smsSource: message.substring(0, message.length > 100 ? 100 : message.length),
              userId: userId,
            ),
            success: true,
          );
        }
      }
    }

    return SmsTransactionResult(success: false, error: 'No transaction pattern found');
  }

  Future<List<SmsTransactionResult>> readRecentSms({
    required String userId,
    int maxMessages = 50,
  }) async {
    return [];
  }

  void startListening({
    required Function(SmsTransactionResult) onTransactionDetected,
    required String userId,
  }) {}

  void stopListening() {}

  bool get isListening => false;
}
