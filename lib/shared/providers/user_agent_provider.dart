import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_agent_provider.g.dart';

@riverpod
Future<String> userAgent(ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  final platform = kIsWeb ? 'Web' : Platform.operatingSystem;

  return '${packageInfo.appName}/${packageInfo.version} ($platform)';
}
