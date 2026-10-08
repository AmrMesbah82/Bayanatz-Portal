// ******************* FILE INFO *******************
// File Name: flat_codec.dart
// Description: Converts between the app's nested model maps and the FLAT,
//              VERSIONED-ARRAY representation stored in Firestore.
//
//   Storage rules (confirmed with product owner):
//   • Keys are flattened PascalCase_With_Underscores (imageUrl -> Image_Url,
//     en/ar -> En/Ar, digits stay attached: text1 -> Text1).
//   • Nested objects join with "_"      (branding.logoUrl -> Branding_Logo_Url).
//   • Model lists expand to indexed keys plus a "<Prefix>_Count" key
//     (Nav_Buttons_0_Id, Nav_Buttons_1_Id, …, Nav_Buttons_Count).
//   • EVERY field is stored as an ARRAY that keeps value history: on save, if
//     the new value differs from the last element, it is appended as a NEW
//     index; if unchanged, the array is left as-is. The CURRENT value is the
//     LAST element.
//   • Values keep their NATIVE types inside the array (String, bool, int, null).
//   • "Last_Updated_At" is written by the repo as a SCALAR Firestore timestamp
//     (not an array).
//
//   Usage:
//     WRITE:  await FlatCodec.writeVersioned(docRef, model.toMap());
//     READ :  Model.fromMap(FlatCodec.decode(snapshot.data()!, Model.flatTemplate));
// Created by: Amr Mesbah

import 'package:cloud_firestore/cloud_firestore.dart';

class FlatCodec {
  // ── camelCase segment -> PascalCase_With_Underscores ───────────────────────
  static bool _isLower(String c) => c.compareTo('a') >= 0 && c.compareTo('z') <= 0;
  static bool _isUpper(String c) => c.compareTo('A') >= 0 && c.compareTo('Z') <= 0;
  static bool _isDigit(String c) => c.compareTo('0') >= 0 && c.compareTo('9') <= 0;

  static String _pascal(String seg) {
    final buf = StringBuffer();
    for (var i = 0; i < seg.length; i++) {
      final c = seg[i];
      if (i > 0) {
        final prev = seg[i - 1];
        if ((_isLower(prev) || _isDigit(prev)) && _isUpper(c)) buf.write(' ');
      }
      buf.write(c);
    }
    return buf
        .toString()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join('_');
  }

  // ── Flatten a nested model map into {flatKey: nativeValue} ─────────────────
  static void _flatten(Map<String, dynamic> nested, String prefix, Map<String, dynamic> out) {
    nested.forEach((k, v) {
      final kp = prefix + _pascal(k);
      if (v is Map) {
        _flatten(_strKeys(v), '${kp}_', out);
      } else if (v is List) {
        out['${kp}_Count'] = v.length; // int
        for (var i = 0; i < v.length; i++) {
          final e = v[i];
          if (e is Map) {
            _flatten(_strKeys(e), '${kp}_${i}_', out);
          } else {
            out['${kp}_$i'] = e; // native
          }
        }
      } else {
        out[kp] = v; // native (String / bool / num / null)
      }
    });
  }

  /// Build the versioned flat map to write with `SetOptions(merge: true)`.
  /// Only changed/new keys are returned (append-on-change); unchanged keys are
  /// omitted so the merge keeps their existing history.
  static Map<String, dynamic> encodeVersioned(
    Map<String, dynamic> nested,
    Map<String, dynamic> existing,
  ) {
    final flat = <String, dynamic>{};
    _flatten(nested, '', flat);

    final out = <String, dynamic>{};
    flat.forEach((k, v) {
      final ex = existing[k];
      if (ex is List && ex.isNotEmpty) {
        if (ex.last != v) out[k] = [...ex, v]; // changed -> append new index
        // unchanged -> omit
      } else {
        out[k] = [v]; // first time -> single-element array
      }
    });
    return out;
  }

  /// Read + append + write in one call. Adds a scalar `Last_Updated_At`
  /// server timestamp unless [stampKey] is null.
  static Future<void> writeVersioned(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> nested, {
    String? stampKey = 'Last_Updated_At',
    Map<String, dynamic>? scalars,
  }) async {
    final snap = await ref.get();
    final existing = snap.data() ?? <String, dynamic>{};
    final data = encodeVersioned(nested, existing);
    if (stampKey != null) data[stampKey] = FieldValue.serverTimestamp();
    // Plain (non-versioned) fields written as-is, e.g. jobListings'
    // `Public_Listed` flag that the security rules read (BUG-01 / BUG-99).
    if (scalars != null) data.addAll(scalars);
    await ref.set(data, SetOptions(merge: true));
  }

  /// Build the map for a brand-new document (no existing history to read).
  static Map<String, dynamic> encodeNew(
    Map<String, dynamic> nested, {
    String? stampKey = 'Last_Updated_At',
  }) {
    final data = encodeVersioned(nested, const {});
    if (stampKey != null) data[stampKey] = FieldValue.serverTimestamp();
    return data;
  }

  // ── READ: raw versioned doc -> nested model map (guided by template) ───────
  static Map<String, dynamic> decode(Map<String, dynamic> raw, Map<String, dynamic> template) {
    // collapse every array to its current (last) value; pass scalars through
    final current = <String, dynamic>{};
    raw.forEach((k, v) {
      if (v is List) {
        current[k] = v.isEmpty ? null : v.last;
      } else {
        current[k] = v;
      }
    });
    return _unflatten(current, template, '');
  }

  static Map<String, dynamic> _unflatten(
    Map<String, dynamic> current,
    Map<String, dynamic> template,
    String prefix,
  ) {
    final out = <String, dynamic>{};
    template.forEach((k, tv) {
      final kp = prefix + _pascal(k);
      if (tv is Map) {
        out[k] = _unflatten(current, _strKeys(tv), '${kp}_');
      } else if (tv is List) {
        final rawCnt = current['${kp}_Count'];
        final cnt = rawCnt is int ? rawCnt : int.tryParse('${rawCnt ?? 0}') ?? 0;
        final et = tv.isNotEmpty ? tv[0] : '';
        final arr = <dynamic>[];
        for (var i = 0; i < cnt; i++) {
          if (et is Map) {
            arr.add(_unflatten(current, _strKeys(et), '${kp}_${i}_'));
          } else {
            arr.add(current['${kp}_$i']);
          }
        }
        out[k] = arr;
      } else {
        out[k] = current.containsKey(kp) ? current[kp] : tv;
      }
    });
    return out;
  }

  static Map<String, dynamic> _strKeys(Map m) =>
      m.map((key, value) => MapEntry(key.toString(), value));
}
