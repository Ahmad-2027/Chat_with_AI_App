import 'dart:io';

import 'package:chat_app_ai/features/auth/services/hive_user_profile_repository.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('aura_profile_test_');
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('stores and loads names separately for each account', () async {
    final repository = HiveUserProfileRepository();
    await repository.saveName('account-one', '  Ahmad  ');

    expect(await repository.loadName('account-one'), 'Ahmad');
    expect(await repository.loadName('account-two'), isNull);

    await Hive.close();
    Hive.init(hiveDirectory.path);
    expect(await HiveUserProfileRepository().loadName('account-one'), 'Ahmad');
  });

  test('rejects empty names', () async {
    final repository = HiveUserProfileRepository();
    await expectLater(
      repository.saveName('account-one', '   '),
      throwsArgumentError,
    );
  });
}
