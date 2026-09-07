import 'package:flutter_test/flutter_test.dart';
import 'package:cie_connect/features/user/data/firebase_user_repository.dart';
import 'package:cie_connect/features/chat/data/chat_repository.dart';

void main() {
  test('connection code is deterministic for the same uid', () {
    final first =
        FirebaseUserRepository.generateConnectionCode('Manas V', 'uid-123');
    final second =
        FirebaseUserRepository.generateConnectionCode('Manas V', 'uid-123');
    expect(second, first);
    expect(first, matches(RegExp(r'^MANAS-[A-Z0-9]{6}$')));
  });

  test('connection code differs for different uids', () {
    expect(
      FirebaseUserRepository.generateConnectionCode('Student', 'uid-a'),
      isNot(FirebaseUserRepository.generateConnectionCode('Student', 'uid-b')),
    );
  });

  test('connection code handles empty non-alphanumeric input safely', () {
    final code = FirebaseUserRepository.generateConnectionCode('!!!', 'uid-1');
    expect(code, matches(RegExp(r'^STUDENT-[A-Z0-9]{6}$')));
  });

  test('connection code input is case and whitespace insensitive', () {
    expect(ChatRepository.normalizeConnectionCode('  manas - 7k4p2  '),
        'MANAS-7K4P2');
  });
}
