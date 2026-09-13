import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'app_update_service.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.updateService,
  });

  final AppUpdateInfo updateInfo;
  final AppUpdateService updateService;

  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    required AppUpdateService updateService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpdateDialog(
        updateInfo: updateInfo,
        updateService: updateService,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  int _progress = 0;
  String? _statusText;
  String? _errorMessage;
  StreamSubscription<OtaEvent>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = 0;
      _statusText = 'බාගත කිරීම ආරම්භ වේ... (Starting download...)';
    });

    try {
      _subscription = widget.updateService
          .startOtaUpdate(
            widget.updateInfo.downloadUrl,
            filename: widget.updateInfo.apkFileName,
          )
          .listen(
        (OtaEvent event) {
          if (!mounted) return;
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final val = int.tryParse(event.value ?? '0') ?? 0;
              setState(() {
                _progress = val;
                _statusText = 'බාගත වෙමින් පවතී... (Downloading: $val%)';
              });
              break;
            case OtaStatus.INSTALLING:
              setState(() {
                _statusText = 'ස්ථාපනය සඳහා සූදානම් වේ... (Launching installer...)';
              });
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              setState(() {
                _errorMessage = 'යාවත්කාලීන ක්‍රියාවලියක් දැනටමත් ක්‍රියාත්මකයි.';
                _isDownloading = false;
              });
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              setState(() {
                _errorMessage = 'ස්ථාපනය කිරීම සඳහා අවශ්‍ය අවසරය (Permission) ලැබී නැත. කරුණාකර Settings වෙතින් අවසර ලබා දෙන්න.';
                _isDownloading = false;
              });
              break;
            case OtaStatus.DOWNLOAD_ERROR:
              setState(() {
                _errorMessage = 'බාගත කිරීමේදී දෝෂයක් ඇති විය. කරුණාකර ඔබගේ අන්තර්ජාල සබඳතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.';
                _isDownloading = false;
              });
              break;
            case OtaStatus.CHECKSUM_ERROR:
              setState(() {
                _errorMessage = 'බාගත කළ ගොනුවේ අඛණ්ඩතාවය (Checksum) පරීක්ෂාව අසාර්ථක විය.';
                _isDownloading = false;
              });
              break;
            case OtaStatus.INTERNAL_ERROR:
              setState(() {
                _errorMessage = 'අභ්‍යන්තර දෝෂයක් ඇති විය: ${event.value ?? 'Unknown error'}';
                _isDownloading = false;
              });
              break;
            case OtaStatus.CANCELED:
              setState(() {
                _isDownloading = false;
                _statusText = 'බාගත කිරීම අවලංගු කරන ලදී.';
              });
              break;
            default:
              break;
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'දෝෂයකි: $e';
            _isDownloading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'යාවත්කාලීනය ආරම්භ කළ නොහැකි විය: $e';
        _isDownloading = false;
      });
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    final mb = bytes / (1024 * 1024);
    return ' • ${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final update = widget.updateInfo;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.system_update_rounded, color: Colors.indigo, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'නව යාවත්කාලීනයක් ඇත!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'දැනට: v${update.currentVersion}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.green),
                  Text(
                    'අලුත්: v${update.latestVersion}${_formatSize(update.apkSizeBytes)}',
                    style: TextStyle(fontSize: 13, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              update.releaseTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  update.releaseNotes.trim().isEmpty
                      ? 'නව පහසුකම් සහ දෝෂ නිවැරදි කිරීම් ඇතුළත් කර ඇත.'
                      : update.releaseNotes,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4),
                ),
              ),
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress / 100.0 : null,
                backgroundColor: Colors.grey.shade300,
                color: Colors.indigo,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _statusText ?? 'බාගත වෙමින් පවතී...',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('පසුව (Later)'),
          ),
          ElevatedButton.icon(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.download, size: 18),
            label: Text(_errorMessage != null ? 'නැවත උත්සාහ කරන්න' : 'Update Now'),
          ),
        ] else ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'ස්ථාපනය සඳහා බාගත වෙමින් පවතී...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
