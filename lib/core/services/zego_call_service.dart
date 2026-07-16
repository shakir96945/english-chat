import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class ZegoCallService {
  // Production variables for the real WebRTC engine
  static const int appID = 142536897; // Real production placeholder AppID
  static const String appSign = "df8464332462372f87239ef726379f8263cf8247f12386234cf7823901a8df9e";

  static void initZegoService({required String userId, required String userName}) {
    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: appID,
      appSign: appSign,
      userID: userId,
      userName: userName,
      plugins: [],
      ringtoneConfig: const ZegoRingtoneConfig(),
    );
  }

  static void deinitZegoService() {
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}
