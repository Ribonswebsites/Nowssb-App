// What one account opened must not show for the next account on the phone.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/word_private.dart';

Word _paidWord() => const Word(
      key: 'om',
      word: 'Om',
      deva: '',
      translit: '',
      phonetic: '',
      parts: [],
      audioMale: '',
      audioFemale: '',
      organ: '',
      origin: 'Sanskrit',
      benefit: '',
      meaning: '',
      mouthPos: '',
      resonance: '',
      mistake: '',
      tip: '',
      categories: [],
      gender: 'both',
      time: 'any',
      price: 99,
      img: '',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  tearDown(() {
    WordPrivateStore.instance.debugClear();
    Entitlements.instance.debugSet();
  });

  test('cached paid word fields only apply while the account may open the word', () {
    final store = WordPrivateStore.instance;
    store.debugPut('om', {'meaning': 'The first sound', 'audioMale': 'https://media.example/om.mp3'});

    Entitlements.instance.debugSet(uid: 'subscriber', tier: 'resonance');
    expect(store.apply(_paidWord()).meaning, 'The first sound');

    // The subscriber signs out; a free account / guest opens the player.
    Entitlements.instance.debugSet(uid: 'free-account');
    final w = store.apply(_paidWord());
    expect(w.meaning, isEmpty);
    expect(w.audioMale, isEmpty);
  });
}
