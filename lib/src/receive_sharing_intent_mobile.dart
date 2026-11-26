import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../receive_sharing_intent.dart';

class ReceiveSharingIntentMobile extends ReceiveSharingIntent {
  @visibleForTesting
  final mChannel = const MethodChannel('receive_sharing_intent/messages');

  @visibleForTesting
  final eChannelMedia =
      const EventChannel("receive_sharing_intent/events-media");

  static Stream<List<SharedMediaFile>>? _streamMedia;

  @override
  Future<List<SharedMediaFile>> getInitialMedia() async {
    final payload = await mChannel.invokeMethod<String>('getInitialMedia');
    return _decodeSharedMedia(payload);
  }

  @override
  Stream<List<SharedMediaFile>> getMediaStream() {
    return _streamMedia ??= eChannelMedia
        .receiveBroadcastStream()
        .cast<String?>()
        .map(_decodeSharedMedia);
  }

  static List<SharedMediaFile> _decodeSharedMedia(String? payload) {
    if (payload == null) return [];
    final Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      throw const FormatException('Invalid shared media response');
    }
    if (decoded is! List<Object?>) {
      throw const FormatException('Invalid shared media response');
    }

    final files = <SharedMediaFile>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final path = item['path'];
      if (path is! String || path.isEmpty) continue;
      files.add(SharedMediaFile.fromMap(item));
    }
    if (decoded.isNotEmpty && files.isEmpty) {
      throw const UnreadableSharedMediaException();
    }
    return files;
  }

  @override
  Future<dynamic> reset() {
    return mChannel.invokeMethod('reset');
  }
}
