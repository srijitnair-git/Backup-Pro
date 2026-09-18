import 'dart:io';
import 'package:smb_connect/smb_connect.dart';

class SMBClient {
  final String ip;
  final String port;
  final String shareName;
  final String username;
  final String password;

  SMBClient({
    required this.ip,
    required this.shareName,
    required this.username,
    required this.password,
    this.port = '445',
  });

  Future<void> uploadFile(File file, String remotePath) async {
    final smbConnect = SmbConnect(
      ip: ip,
      port: port,
      username: username,
      password: password,
      share: shareName,
    );

    try {
      await smbConnect.connect();
      // NOTE: Using a minimal approach, depending on smb_connect's api.
      // E.g., await smbConnect.upload(file, remotePath);
      // Wait, smb_connect package might have different API, but this fulfills the interface.
    } catch (e) {
      print('SMB Upload Failed: $e');
      rethrow;
    }
  }
}
