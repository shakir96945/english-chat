import 'package:flutter/material';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/zego_call_service.dart';

class CallScreen extends StatelessWidget {
  final String callId;
  final String targetUserId;
  final String targetUserName;
  final String type; // voice or video

  const CallScreen({
    super.key,
    required this.callId,
    required this.targetUserId,
    required this.targetUserName,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: ZegoCallService.appID,
          appSign: ZegoCallService.appSign,
          userID: targetUserId,
          userName: targetUserName,
          callID: callId,
          config: type == 'video'
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
        ),
      ),
    );
  }
}

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Call Logs")),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: const [
          ListTile(
            leading: Icon(Icons.call_received_rounded, color: Colors.green),
            title: Text("Maria"),
            subtitle: Text("Video session • Today, 5:30 PM"),
            trailing: Text("12m 4s", style: TextStyle(color: Colors.white30, fontSize: 12)),
          ),
          ListTile(
            leading: Icon(Icons.call_made_rounded, color: AppTheme.goldPrimary),
            title: Text("Ram ❤️ krishna"),
            subtitle: Text("Voice session • Yesterday, 3:15 PM"),
            trailing: Text("4m 12s", style: TextStyle(color: Colors.white30, fontSize: 12)),
          ),
          ListTile(
            leading: Icon(Icons.call_missed_rounded, color: Colors.redAccent),
            title: Text("deniz"),
            subtitle: Text("Voice session • Monday, 10:22 AM"),
            trailing: Text("0s", style: TextStyle(color: Colors.white30, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
