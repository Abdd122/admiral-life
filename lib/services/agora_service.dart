
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

// --- AGORA CONFIGURATION ---
const String _appId = "49b0b00483ea4bd98e4e889bb8f67452";
const String _tempToken = "007eJxTYPgmddhzVVvJeT4Ft11z1EqfesyZvuT/VKNJ3VOt7IP/aisoMJhYJhkkGRiYWBinJpokpVhapJqkWlhYJiVZpJmZm5gamcS8yWwIZGS4o2bGysjAysDIwMQA4jMwAACJfR02"; 
// --- END AGORA CONFIGURATION ---

class AgoraService with ChangeNotifier {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  List<int> _remoteUids = []; 
  int? _activeSpeakerUid; // To store the UID of the active speaker

  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  List<int> get remoteUids => _remoteUids;
  int? get activeSpeakerUid => _activeSpeakerUid;

  Future<void> initialize() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: _appId));

    _addAgoraEventHandlers();

    await _engine!.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();

    // Enable audio volume indication
    // Reports the user who is speaking loudest every 250ms
    await _engine!.enableAudioVolumeIndication(250, 3, true);
  }

  void _addAgoraEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _isJoined = true;
          notifyListeners();
          debugPrint("Successfully joined channel: ${connection.channelId}");
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _isJoined = false;
          _remoteUids.clear();
          _activeSpeakerUid = null; // Clear active speaker on leave
          notifyListeners();
          debugPrint("Left channel");
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _remoteUids.add(remoteUid);
          notifyListeners();
          debugPrint("User joined: $remoteUid");
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _remoteUids.remove(remoteUid);
          if (_activeSpeakerUid == remoteUid) {
             _activeSpeakerUid = null;
          }
          notifyListeners();
          debugPrint("User offline: $remoteUid");
        },
        // Event to detect active speakers
        onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume) {
            int? newActiveSpeakerUid;
            if (speakers.isNotEmpty) {
                // Find the speaker with the highest volume
                speakers.sort((a, b) => b.volume.compareTo(a.volume));
                // Use the speaker if their volume is above a threshold (e.g., 5)
                if (speakers[0].volume > 5) {
                    // UID 0 represents the local user
                    newActiveSpeakerUid = speakers[0].uid == 0 ? null : speakers[0].uid; // We handle local user differently if needed
                }
            }
            
            if (_activeSpeakerUid != newActiveSpeakerUid) {
                _activeSpeakerUid = newActiveSpeakerUid;
                notifyListeners();
            }
        },
        onError: (ErrorCodeType err, String msg) {
            debugPrint('[Agora Error] err: $err, msg: $msg');
        },
      ),
    );
  }

  Future<void> joinChannel(String channelName) async {
    if (_engine == null) await initialize();
    
    await _engine!.joinChannel(
      token: _tempToken,
      channelId: channelName, 
      uid: 0, // Let Agora assign a UID for the local user
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }

  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
    _activeSpeakerUid = null;
  }

  Future<void> toggleMute() async {
    if (_engine == null) return;
    _isMuted = !_isMuted;
    await _engine!.muteLocalAudioStream(_isMuted);
    notifyListeners();
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }
}
