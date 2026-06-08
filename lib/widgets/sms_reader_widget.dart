import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../services/sms_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SmsReaderWidget extends StatefulWidget {
  const SmsReaderWidget({super.key});

  @override
  State<SmsReaderWidget> createState() => _SmsReaderWidgetState();
}

class _SmsReaderWidgetState extends State<SmsReaderWidget> {
  final SmsService _smsService = SmsService();
  bool _hasPermission = false;
  bool _isReading = false;
  List<SmsTransactionResult> _results = [];
  int _importedCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await _smsService.hasSmsPermission();
    setState(() => _hasPermission = granted);
  }

  Future<void> _requestPermission() async {
    final granted = await _smsService.requestSmsPermission();
    setState(() => _hasPermission = granted);
  }

  Future<void> _readSms() async {
    if (!_hasPermission) {
      await _requestPermission();
      if (!_hasPermission) return;
    }

    setState(() => _isReading = true);
    _results.clear();
    _importedCount = 0;

    final userId = context.read<AuthProvider>().userId;
    final results = await _smsService.readRecentSms(userId: userId);

    final provider = context.read<TransactionProvider>();
    for (final result in results) {
      if (result.transaction != null) {
        final success = await provider.addTransaction(result.transaction!);
        if (success) {
          _importedCount++;
        }
      }
    }

    setState(() {
      _results = results;
      _isReading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sms, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SMS Transaction Reader',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _hasPermission
                          ? 'Ready to read bank SMS'
                          : 'Permission required',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_hasPermission)
                TextButton(
                  onPressed: _requestPermission,
                  child: const Text('Allow'),
                ),
            ],
          ),
          if (_hasPermission) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isReading ? null : _readSms,
                icon: _isReading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                    _isReading ? 'Reading SMS...' : 'Import from SMS'),
              ),
            ),
            if (_importedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Imported $_importedCount transactions',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (_results.isNotEmpty && _importedCount == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: const Text(
                  'No bank transactions found in recent messages',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
