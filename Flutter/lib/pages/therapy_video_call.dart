import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:health_research/pages/dashboard.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

const String appId = "f84298e9180448cfb3d26e3ec61e49db";

class MainScreen extends StatefulWidget {
  final String sessionId;
  final String token;
  final int uid;

  const MainScreen({
    super.key,
    required this.sessionId,
    required this.token,
    required this.uid,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  late String _channelId;

  bool micOn = true;
  bool cameraOn = true;

  @override
  void initState() {
    super.initState();
    _channelId = widget.sessionId;
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Request camera and microphone permissions
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted) {
      debugPrint("❌ Camera permission denied: $cameraStatus");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permission required")),
        );
      }
      return;
    }
    if (!micStatus.isGranted) {
      debugPrint("⚠️ Microphone permission denied: $micStatus");
    }

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection conn, int elapsed) {
          debugPrint(
              "✅ [PATIENT] Joined channel - Local UID: ${conn.localUid}");
          debugPrint("   Channel ID: ${conn.channelId}");
          debugPrint("   Elapsed: ${elapsed}ms");
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection conn, int remoteUid, int elapsed) {
          debugPrint("🔔 [PATIENT] DOCTOR JOINED");
          debugPrint("   Remote UID: $remoteUid");
          debugPrint("   Elapsed: ${elapsed}ms");
          debugPrint("   Configuring subscriptions...");

          // Explicitly enable subscription to remote user's video and audio
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
              "❌ [PATIENT] DOCTOR OFFLINE - UID: $remoteUid, Reason: $reason");
          setState(() => _remoteUid = null);
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("❌ [PATIENT] ERROR: $err - $msg");
        },
        onRemoteVideoStateChanged: (RtcConnection connection,
            int remoteUid,
            RemoteVideoState state,
            RemoteVideoStateReason reason,
            int elapsed) {
          debugPrint("🎬 [PATIENT] REMOTE VIDEO STATE CHANGE");
          debugPrint("   UID: $remoteUid");
          debugPrint("   State: $state (${state.index})");
          debugPrint("   Reason: $reason");
          debugPrint("   Elapsed: ${elapsed}ms");
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
          debugPrint("🔊 [PATIENT] REMOTE AUDIO STATE CHANGE");
          debugPrint("   UID: $remoteUid");
          debugPrint("   State: $state (${state.index})");
          debugPrint("   Reason: $reason");
          debugPrint("   Elapsed: ${elapsed}ms");
          String stateStr = {
                0: 'MUTED',
                1: 'RUNNING',
                2: 'FAILED',
                3: 'FROZEN'
              }[state.index] ??
              'UNKNOWN';
          debugPrint("   Readable State: $stateStr");
        },
        onVideoDeviceStateChanged: (String deviceId, MediaDeviceType deviceType,
            MediaDeviceStateType deviceState) {
          debugPrint(
              "🎥 [PATIENT] VIDEO DEVICE CHANGE - Device: $deviceId, Type: $deviceType, State: $deviceState");
        },
      ),
    );
    debugPrint("✅ [PATIENT] Event handlers registered successfully");

    try {
      // Enable video and audio BEFORE starting preview
      await _engine.enableVideo();
      debugPrint("✅ Video enabled");

      await _engine.enableAudio();
      debugPrint("✅ Audio enabled");

      // Start local preview
      await _engine.startPreview();
      debugPrint("✅ Local preview started - camera should be visible now");

      setState(() => _localUserJoined = true);
    } catch (e) {
      debugPrint("❌ Failed to enable video/audio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to start camera: $e")),
        );
      }
      return;
    }

    try {
      debugPrint("📡 Using token from session request");
      debugPrint("✅ Token received: ${widget.token.substring(0, 30)}...");

      debugPrint("🔗 Joining channel: $_channelId with UID: ${widget.uid}");
      await _engine.joinChannel(
        token: widget.token,
        channelId: _channelId,
        uid: widget.uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          // Force subscription to remote streams
          enableAudioRecordingOrPlayout: true,
        ),
      );
      debugPrint("✅ Join request sent to Agora");

      // Explicitly subscribe to remote audio and video
      debugPrint("🔄 Configuring remote stream subscriptions...");
    } catch (e) {
      debugPrint("❌ Error joining channel: $e");
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
  }

  void _toggleCamera() async {
    cameraOn = !cameraOn;
    await _engine.muteLocalVideoStream(!cameraOn);
    setState(() {});
  }

  void _switchCamera() {
    _engine.switchCamera();
  }

  Future<void> _leaveMeeting() async {
    await _engine.leaveChannel();
    await _engine.release();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Video Call'),
        actions: [
          IconButton(
              icon: const Icon(Icons.exit_to_app), onPressed: _leaveMeeting),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Remote video (doctor) – full screen
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
                        "⏳ Waiting for doctor to join...",
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                    ),
                  ),

                // Local preview (top left)
                Align(
                  alignment: Alignment.topLeft,
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
                  icon: Icon(micOn ? Icons.mic : Icons.mic_off),
                  onPressed: _toggleMic,
                  tooltip: micOn ? 'Mute' : 'Unmute',
                ),
                IconButton(
                  icon: Icon(cameraOn ? Icons.videocam : Icons.videocam_off),
                  onPressed: _toggleCamera,
                  tooltip: cameraOn ? 'Turn off camera' : 'Turn on camera',
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch),
                  onPressed: _switchCamera,
                  tooltip: 'Switch camera',
                ),
                IconButton(
                  icon: const Icon(Icons.call_end),
                  color: Colors.red,
                  onPressed: _leaveMeeting,
                  tooltip: 'End call',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
