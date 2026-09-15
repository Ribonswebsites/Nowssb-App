/// Shared store-to-store navigation for the glass store picker sheet.
library;

import 'package:flutter/material.dart';

import 'ebooks_store.dart';
import 'meaning_store.dart';
import 'signature_store.dart';
import 'word_atelier.dart';

void openStoreFromPicker(BuildContext context, String id, {required String current}) {
  if (id == current) return;
  late final Widget page;
  switch (id) {
    case 'meaning':
      page = const MeaningStoreScreen();
      break;
    case 'ebooks':
      page = const EbooksStoreScreen();
      break;
    case 'signature':
      page = const SignatureStoreScreen();
      break;
    case 'word':
    default:
      page = const WordAtelierScreen();
      break;
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}
