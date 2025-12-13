import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

void main() async {
  print('🔍 Testing WebSocket Format (3-byte header)');
  
  final email = 'lephuoccan@gmail.com';
  final password = '111111';
  
  // Hash password
  final emailLower = email.toLowerCase();
  final emailHash = sha256.convert(utf8.encode(emailLower)).bytes;
  final passWithEmailHash = utf8.encode(password) + emailHash;
  final passHash = base64.encode(sha256.convert(passWithEmailHash).bytes);
  
  print('📧 Email: $email');
  print('🔐 Password Hash: $passHash');
  
  // Connect WebSocket
  final ws = await WebSocket.connect(
    'wss://192.168.1.9:9443/dashws',
    customClient: HttpClient()..badCertificateCallback = (cert, host, port) => true,
  );
  print('✅ Connected to /dashws!');
  
  // Prepare LOGIN message body (5 parts như test code)
  final parts = [
    email,
    passHash,
    'web',
    '1.0.0',
    'Blynk'
  ];
  final bodyString = parts.join('\u0000'); // null separator
  final bodyBytes = utf8.encode(bodyString);
  
  // WebSocket format: ONLY 3 bytes header!
  final command = 2; // LOGIN
  final messageId = 1;
  
  final message = ByteData(3 + bodyBytes.length);
  message.setUint8(0, command);
  message.setUint16(1, messageId, Endian.big);
  // NO length field! Body follows directly
  for (var i = 0; i < bodyBytes.length; i++) {
    message.setUint8(3 + i, bodyBytes[i]);
  }
  
  print('');
  print('📤 Sending LOGIN to /dashws:');
  print('   Format: command(1) | messageId(2) | body (NO length field!)');
  print('   Command: $command (LOGIN)');
  print('   Message ID: $messageId');
  print('   Body: ${parts.join(" + ")} (${bodyBytes.length} bytes)');
  print('   Total: ${message.lengthInBytes} bytes');
  
  // Send
  ws.add(message.buffer.asUint8List());
  
  // Wait for response
  await for (final data in ws) {
    if (data is List<int>) {
      final bytes = Uint8List.fromList(data);
      print('');
      print('📥 Received ${bytes.length} bytes');
      print('   Raw: ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      
      if (bytes.length >= 3) {
        final respCommand = bytes[0];
        final respMsgId = (bytes[1] << 8) | bytes[2];
        
        if (respCommand == 0 && bytes.length >= 7) {
          // RESPONSE format: command(1) | msgId(2) | code(4)
          final code = (bytes[3] << 24) | (bytes[4] << 16) | (bytes[5] << 8) | bytes[6];
          
          String status;
          switch (code) {
            case 200: status = 'OK'; break;
            case 2: status = 'ILLEGAL_COMMAND'; break;
            case 8: status = 'NO_ACTIVE_DASHBOARD'; break;
            case 9: status = 'INVALID_TOKEN'; break;
            case 11: status = 'ILLEGAL_COMMAND_BODY'; break;
            default: status = 'Unknown($code)';
          }
          
          print('   Response code: $code');
          print('   Status: $status');
          
          if (code == 200) {
            print('\n🎉 SUCCESS! Logged in to /dashws!');
          } else {
            print('\n❌ Login failed: $status');
          }
        } else {
          print('   Unknown response format');
        }
      }
      break;
    }
  }
  
  await ws.close();
}
