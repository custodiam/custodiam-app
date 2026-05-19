import 'package:custodiam/infrastructure/auth/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('TokenStore', () {
    late _MockSecureStorage storage;
    late TokenStore store;

    setUp(() {
      storage = _MockSecureStorage();
      store = TokenStore(storage: storage);
    });

    test('save writes the JSON under the canonical key', () async {
      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await store.save('{"accessToken":"abc"}');

      verify(() => storage.write(
            key: 'custodiam_credentials',
            value: '{"accessToken":"abc"}',
          )).called(1);
    });

    test('read returns the value persisted under the canonical key',
        () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => '{"accessToken":"abc"}');

      final value = await store.read();

      expect(value, '{"accessToken":"abc"}');
      verify(() => storage.read(key: 'custodiam_credentials')).called(1);
    });

    test('read returns null when nothing is stored', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      expect(await store.read(), isNull);
    });

    test('clear deletes the canonical key', () async {
      when(() => storage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await store.clear();

      verify(() => storage.delete(key: 'custodiam_credentials')).called(1);
    });
  });
}
