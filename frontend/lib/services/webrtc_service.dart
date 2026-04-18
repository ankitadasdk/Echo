import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  WebSocketChannel? _signalingChannel;
  final String serverUrl;
  final String roomId;
  
  Function(Map<String, dynamic> payload)? onMessageReceived;
  Function(bool isConnected)? onConnectionStateChange;

  WebRTCService({required this.serverUrl, required this.roomId});

  Future<void> connect() async {
    try {
      _signalingChannel = WebSocketChannel.connect(Uri.parse('$serverUrl/ws/$roomId'));
      _signalingChannel!.stream.listen((message) {
        _handleSignalingMessage(message);
      }, onDone: () {
        debugPrint('Signaling disconnected');
      });

      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };
      
      _peerConnection = await createPeerConnection(configuration);

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        _signalingChannel!.sink.add(jsonEncode({
          'type': 'candidate',
          'candidate': candidate.toMap(),
        }));
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('Peer connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          onConnectionStateChange?.call(true);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                   state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          onConnectionStateChange?.call(false);
        }
      };

      // Receives DataChannel from peer
      _peerConnection!.onDataChannel = (RTCDataChannel channel) {
        _dataChannel = channel;
        _dataChannel!.onMessage = (RTCDataChannelMessage message) {
          if (onMessageReceived != null) {
            onMessageReceived!(jsonDecode(message.text));
          }
        };
      };

      // Create local DataChannel
      RTCDataChannelInit dataChannelDict = RTCDataChannelInit()..ordered = true;
      _dataChannel = await _peerConnection!.createDataChannel('echo_sync_data', dataChannelDict);
      _dataChannel!.onMessage = (RTCDataChannelMessage message) {
        if (onMessageReceived != null) {
          onMessageReceived!(jsonDecode(message.text));
        }
      };
      
      // Assume "initiator" role and send offer
      await _makeOffer();
      
    } catch (e) {
      debugPrint('Error starting WebRTC: $e');
    }
  }

  Future<void> _makeOffer() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _signalingChannel!.sink.add(jsonEncode({
      'type': 'offer',
      'sdp': offer.sdp,
    }));
  }

  void _handleSignalingMessage(String message) async {
    final Map<String, dynamic> data = jsonDecode(message);
    
    switch (data['type']) {
      case 'offer':
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type'])
        );
        RTCSessionDescription answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _signalingChannel!.sink.add(jsonEncode({
          'type': 'answer',
          'sdp': answer.sdp,
        }));
        break;
      case 'answer':
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type'])
        );
        break;
      case 'candidate':
        await _peerConnection!.addCandidate(
          RTCIceCandidate(
            data['candidate']['candidate'],
            data['candidate']['sdpMid'],
            data['candidate']['sdpMLineIndex']
          )
        );
        break;
    }
  }

  void sendMessage(Map<String, dynamic> data) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel!.send(RTCDataChannelMessage(jsonEncode(data)));
    } else {
      debugPrint('DataChannel not open');
    }
  }

  void dispose() {
    _dataChannel?.close();
    _peerConnection?.close();
    _signalingChannel?.sink.close();
  }
}
