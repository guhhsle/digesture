import 'package:flutter/material.dart';
import 'animations.dart';
import 'visual.dart';
import 'clear.dart';
import 'book.dart';
import '../data.dart';

extension Cursor on Book {
  Map<String, void Function()> get moveCursorEnd {
    return {
      '2 Syllables': moveCursorEndBy2Syllables,
      'Syllable': moveCursorEndBySyllable,
      'Word': moveCursorEndByWord,
      '1': moveCursorEndBy1,
      '2': moveCursorEndBy2,
      '5': moveCursorEndBy5,
    };
  }

  Future<bool> moveCursor({List<List<int>>? checkpoints}) async {
    bool hasParent = checkpoints != null;
    if (!valid && !hasParent) return false;
    checkpoints ??= [];
    checkpoints.add(dots.toList());
    jumping = true;
    if (dots[2] >= dots[3]) await nextSentence();
    checkpoints.add(dots.toList());
    dots[1] = dots[2];

    skipCursorStartToChar();
    moveCursorEnd[Pref.cursorShift.value]!.call();

    if (dots[2] > dots[3]) dots[2] = dots[3];
    checkpoints.add(dots.toList());
    if (!valid || !loadedText[dots[1]].isNormal) {
      debugPrint('Special situation: $dots');
      checkpoints.add(dots.toList());
      if (!hasParent) {
        if (await moveCursor(checkpoints: checkpoints)) return true;
      }
    }
    for (var checkpoint in checkpoints.reversed) {
      if (valid) break;
      dots = checkpoint.toList();
    }
    if (!valid) {
      dots = checkpoints[0];
      return false;
    }
    await animateDots(checkpoints[0], dots.toList());
    jumping = false;
    notify();
    checkForClearing();
    return true;
  }

  void skipCursorStartToChar() {
    while (!loadedText[dots[1]].isNormal) {
      if (dots[1] >= dots[2] - 1) {
        if (dots[2] >= dots[3]) break;
        dots[2]++;
      }
      dots[1]++;
    }
  }

  void skipSentenceStartToChar() {
    while (!loadedText[dots[0]].isNormal) {
      if (dots[0] >= dots[3]) break;
      dots[0]++;
    }
    dots[2] = dots[1] = dots[0];
  }

  void moveCursorEndBySyllable() {
    dots[2] += 2;
    while (!loadedText[dots[2]].isSyllable) {
      if (!loadedText[dots[2]].isNormal) break;
      if (dots[2] > dots[3]) break;
      dots[2]++;
    }
  }

  void moveCursorEndBy2Syllables() {
    moveCursorEndBySyllable();
    moveCursorEndBySyllable();
  }

  void moveCursorEndByWord() {
    dots[2] += 2;
    while (loadedText[dots[2]].isNormal) {
      if (dots[2] > dots[3]) break;
      dots[2]++;
    }
  }

  void moveCursorEndBy1() => dots[2] += 1;
  void moveCursorEndBy2() => dots[2] += 2;
  void moveCursorEndBy5() => dots[2] += 5;

  Future nextSentence() async {
    dots[0] = dots[1] = dots[2] = dots[3];
    dots[3] += 16;
    while (dots[3] + 1 < loadedTextLength) {
      if (loadedText[dots[3]].endsSentence) break;
      dots[3]++;
    }
    skipSentenceStartToChar();
  }
}
