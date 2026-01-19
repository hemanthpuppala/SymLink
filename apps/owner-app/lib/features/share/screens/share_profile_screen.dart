import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/api/api_client.dart';

class ShareInfo {
  final String plantId;
  final String plantName;
  final String shareUrl;
  final String qrData;
  final String deepLink;
  final String message;

  ShareInfo({
    required this.plantId,
    required this.plantName,
    required this.shareUrl,
    required this.qrData,
    required this.deepLink,
    required this.message,
  });

  factory ShareInfo.fromJson(Map<String, dynamic> json) {
    return ShareInfo(
      plantId: json['plantId'] as String,
      plantName: json['plantName'] as String,
      shareUrl: json['shareUrl'] as String,
      qrData: json['qrData'] as String,
      deepLink: json['deepLink'] as String,
      message: json['message'] as String,
    );
  }
}

class ShareProfileScreen extends StatefulWidget {
  final String plantId;

  const ShareProfileScreen({super.key, required this.plantId});

  @override
  State<ShareProfileScreen> createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends State<ShareProfileScreen> {
  ShareInfo? _shareInfo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShareInfo();
    });
  }

  Future<void> _loadShareInfo() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.get('/v1/owner/plant/${widget.plantId}/share');
      final data = response.data['data'] ?? response.data;

      if (mounted) {
        setState(() {
          _shareInfo = ShareInfo.fromJson(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _copyLink() async {
    if (_shareInfo == null) return;

    await Clipboard.setData(ClipboardData(text: _shareInfo!.shareUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  Future<void> _shareLink() async {
    if (_shareInfo == null) return;

    await Share.share(
      _shareInfo!.message,
      subject: 'Check out ${_shareInfo!.plantName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Profile'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadShareInfo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_shareInfo == null) {
      return const Center(child: Text('No share info available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            _shareInfo!.plantName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: _shareInfo!.qrData,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan this QR code to view your plant profile',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _shareInfo!.shareUrl,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyLink,
                  tooltip: 'Copy link',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.link),
                  label: const Text('Copy Link'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _shareLink,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share Options',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ShareOption(
                    icon: Icons.message,
                    title: 'WhatsApp',
                    onTap: () => _shareVia('whatsapp'),
                  ),
                  _ShareOption(
                    icon: Icons.telegram,
                    title: 'Telegram',
                    onTap: () => _shareVia('telegram'),
                  ),
                  _ShareOption(
                    icon: Icons.email,
                    title: 'Email',
                    onTap: () => _shareVia('email'),
                  ),
                  _ShareOption(
                    icon: Icons.more_horiz,
                    title: 'More Apps',
                    onTap: _shareLink,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareVia(String platform) {
    // For now, just use the general share functionality
    // In a real app, you could use platform-specific share intents
    _shareLink();
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
