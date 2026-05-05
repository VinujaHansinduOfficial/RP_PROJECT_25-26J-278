import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:health_research/pages/baseUi.dart';
import 'package:health_research/pages/dashboard.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:health_research/config/api_config.dart';

const String appId = "f84298e9180448cfb3d26e3ec61e49db";

/// Doctor Video Call Screen
/// This is used by the doctor/clinician on web/desktop
/// Ensures 2-way video communication with proper UID management
class DoctorVideoCall extends StatefulWidget {
  final String sessionId;
  final int doctorUid;

  const DoctorVideoCall({
    super.key,
    required this.sessionId,
    this.doctorUid = 1001, // Doctor UID (different from patient UID 1002)
  });

  @override
  State<DoctorVideoCall> createState() => _DoctorVideoCallState();
}

class _DoctorVideoCallState extends State<DoctorVideoCall> {
  int? _remoteUid; // Patient's UID
  bool _localUserJoined = false;
  late RtcEngine _engine;
  late String _channelId;

  bool micOn = true;
  bool cameraOn = true;

  @override
  void initState() {
    super.initState();
    _channelId = widget.sessionId;
    debugPrint(
        "🏥 Doctor Video Call Init - Session: $_channelId, Doctor UID: ${widget.doctorUid}");
    _initAgora();
  }

  Future<String> _fetchToken(String channel) async {
    try {
      // Doctor on Flutter uses UID 1001 for consistency with web (1000)
      final url = Uri.parse(
          "${ApiConfig.agoraTokenServerUrl}/token?channel=$channel&uid=${widget.doctorUid}");
      debugPrint("📡 [DOCTOR] Requesting token from: $url");

      final res = await http.get(url).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception("Token request timed out"),
          );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["token"] == null) {
          throw Exception("Token field missing in response");
        }
        debugPrint(
            "✅ [DOCTOR] Token fetched (length: ${data['token'].toString().length})");
        debugPrint("✅ [DOCTOR] Assigned UID: ${data['uid']}");
        return data["token"];
      } else {
        throw Exception("Token request failed: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ [DOCTOR] Token fetch error: $e");
      rethrow;
    }
  }

  Future<void> _initAgora() async {
    debugPrint("🔧 [DOCTOR] Initializing Agora...");

    // Request permissions
    final cameraStatus = await Permission.camera.request();
    await Permission.microphone.request();

    if (!cameraStatus.isGranted) {
      debugPrint("❌ [DOCTOR] Camera permission denied");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permission required")),
        );
      }
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    debugPrint("✅ [DOCTOR] Engine created");

    // Register event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection conn, int elapsed) {
          debugPrint("✅ [DOCTOR] Joined channel - Local UID: ${conn.localUid}");
          debugPrint("   Channel ID: ${conn.channelId}");
          debugPrint("   Elapsed: ${elapsed}ms");
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection conn, int remoteUid, int elapsed) {
          debugPrint("🔔 [DOCTOR] PATIENT JOINED");
          debugPrint("   Remote UID: $remoteUid");
          debugPrint("   Elapsed: ${elapsed}ms");

          // Explicitly enable subscription to remote streams
          debugPrint("   📡 Enabling remote video stream (uid: $remoteUid)...");
          _engine.muteRemoteVideoStream(uid: remoteUid, mute: false);
          debugPrint("   ✅ Remote video stream enabled");

          debugPrint("   📡 Enabling remote audio stream (uid: $remoteUid)...");
          _engine.muteRemoteAudioStream(uid: remoteUid, mute: false);
          debugPrint("   ✅ Remote audio stream enabled");

          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline:
            (RtcConnection conn, int remoteUid, UserOfflineReasonType reason) {
          debugPrint(
              "❌ [DOCTOR] PATIENT OFFLINE - UID: $remoteUid, Reason: $reason");
          setState(() => _remoteUid = null);
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("❌ [DOCTOR] ERROR: $err - $msg");
        },
        onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid,
            RemoteVideoState state, reason, int elapsed) {
          debugPrint("🎬 [DOCTOR] REMOTE VIDEO STATE CHANGE");
          debugPrint("   UID: $remoteUid");
          debugPrint("   State: $state (${state.index})");
          debugPrint("   Reason: $reason");
          debugPrint("   Elapsed: ${elapsed}ms");
          // MUTED = 0, RUNNING = 1, FAILED = 2, FROZEN = 3
          String stateStr = {
                0: 'MUTED',
                1: 'RUNNING',
                2: 'FAILED',
                3: 'FROZEN'
              }[state.index] ??
              'UNKNOWN';
          debugPrint("   Readable State: $stateStr");
        },
        onRemoteAudioStateChanged: (RtcConnection connection,
            int remoteUid,
            RemoteAudioState state,
            RemoteAudioStateReason reason,
            int elapsed) {
          debugPrint("🔊 [DOCTOR] REMOTE AUDIO STATE CHANGE");
          debugPrint("   UID: $remoteUid");
          debugPrint("   State: $state (${state.index})");
          debugPrint("   Reason: $reason");
          debugPrint("   Elapsed: ${elapsed}ms");
          // MUTED = 0, RUNNING = 1, FAILED = 2, FROZEN = 3
          String stateStr = {
                0: 'MUTED',
                1: 'RUNNING',
                2: 'FAILED',
                3: 'FROZEN'
              }[state.index] ??
              'UNKNOWN';
          debugPrint("   Readable State: $stateStr");
        },
      ),
    );
    debugPrint("✅ [DOCTOR] Event handlers registered successfully");

    try {
      // Enable video and audio
      await _engine.enableVideo();
      await _engine.enableAudio();
      debugPrint("✅ [DOCTOR] Video and audio enabled");

      // Start preview
      await _engine.startPreview();
      debugPrint("✅ [DOCTOR] Preview started");

      setState(() => _localUserJoined = true);
    } catch (e) {
      debugPrint("❌ [DOCTOR] Failed to enable video/audio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to start camera: $e")),
        );
      }
      return;
    }

    try {
      String token = await _fetchToken(_channelId);

      debugPrint(
          "🔗 [DOCTOR] Joining channel - ID: $_channelId, UID: ${widget.doctorUid}");
      await _engine.joinChannel(
        token: token,
        channelId: _channelId,
        uid: widget.doctorUid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          enableAudioRecordingOrPlayout: true,
        ),
      );
      debugPrint("✅ [DOCTOR] Join request sent");
    } catch (e) {
      debugPrint("❌ [DOCTOR] Error joining channel: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _toggleMic() async {
    micOn = !micOn;
    await _engine.muteLocalAudioStream(!micOn);
    setState(() {});
    debugPrint("🔊 [DOCTOR] Microphone: ${micOn ? 'ON' : 'OFF'}");
  }

  void _toggleCamera() async {
    cameraOn = !cameraOn;
    await _engine.muteLocalVideoStream(!cameraOn);
    setState(() {});
    debugPrint("🎥 [DOCTOR] Camera: ${cameraOn ? 'ON' : 'OFF'}");
  }

  void _switchCamera() {
    _engine.switchCamera();
    debugPrint("🔄 [DOCTOR] Camera switched");
  }

  Future<void> _leaveMeeting() async {
    debugPrint("📞 [DOCTOR] Leaving meeting...");
    await _engine.leaveChannel();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BaseUi()),
      );
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    debugPrint("🛑 [DOCTOR] Engine released");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏥 Doctor Video Call'),
            Text('Session: $_channelId | UID: ${widget.doctorUid}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _leaveMeeting,
            tooltip: 'End call',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Remote video (patient) – full screen
                if (_remoteUid != null)
                  Stack(
                    children: [
                      AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: _engine,
                          canvas: VideoCanvas(
                            uid: _remoteUid!,
                            renderMode: RenderModeType.renderModeHidden,
                          ),
                          connection: RtcConnection(channelId: _channelId),
                        ),
                      ),
                      // Add black background container if no video
                      Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  )
                else
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        "🕐 Waiting for Doctor to join...",
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                    ),
                  ),

                // Local preview (top left - doctor's own video)
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyan, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SizedBox(
                      width: 120,
                      height: 160,
                      child: _localUserJoined
                          ? AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: _engine,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            )
                          : const CircularProgressIndicator(),
                    ),
                  ),
                ),

                // Status indicator
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _remoteUid != null ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _remoteUid != null ? "🟢 Connected" : "🟡 Waiting",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(micOn ? Icons.mic : Icons.mic_off,
                      color: Colors.blue),
                  onPressed: _toggleMic,
                  tooltip: micOn ? 'Mute' : 'Unmute',
                  iconSize: 32,
                ),
                IconButton(
                  icon: Icon(cameraOn ? Icons.videocam : Icons.videocam_off,
                      color: Colors.blue),
                  onPressed: _toggleCamera,
                  tooltip: cameraOn ? 'Turn off camera' : 'Turn on camera',
                  iconSize: 32,
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.blue),
                  onPressed: _switchCamera,
                  tooltip: 'Switch camera',
                  iconSize: 32,
                ),
                IconButton(
                  icon: const Icon(Icons.call_end, color: Colors.red),
                  onPressed: _leaveMeeting,
                  tooltip: 'End call',
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
