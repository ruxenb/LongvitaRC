// PM-S3-5-03 at the service boundary: the cached profile behind
// `AuthService.currentUser` must come from the latest load of the current
// session. Minimal Firebase fakes; only the members AuthService uses exist.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:longvita/services/auth_service.dart';

class _User implements User {
  _User(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements FirebaseAuth {
  final changes = StreamController<User?>.broadcast();
  User? user;

  void emit(String? uid) {
    user = uid == null ? null : _User(uid);
    changes.add(user);
  }

  @override
  User? get currentUser => user;

  @override
  Stream<User?> authStateChanges() => changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.id, this.name);

  @override
  final String id;
  final String name;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => {
        'email': '$id@example.test',
        'displayName': name,
        'role': 'user',
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Each `get()` waits until the test completes it.
class _Firestore implements FirebaseFirestore {
  final reads = <Completer<DocumentSnapshot<Map<String, dynamic>>>>[];

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.store);

  final _Firestore store;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Doc(store);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Doc implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.store);

  final _Firestore store;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    final read = Completer<DocumentSnapshot<Map<String, dynamic>>>();
    store.reads.add(read);
    return read.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Google implements GoogleSignIn {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Auth auth;
  late _Firestore store;
  late AuthService service;
  late StreamSubscription<String?> listening;

  setUp(() {
    auth = _Auth();
    store = _Firestore();
    service =
        AuthService(auth: auth, firestore: store, googleSignIn: _Google());
    listening = service.authUidChanges.listen((_) {});
  });

  tearDown(() => listening.cancel());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a single load fills the cached profile', () async {
    auth.emit('uid-a');
    await settle();

    final load = service.loadProfile('uid-a');
    store.reads.single.complete(_Snapshot('uid-a', 'A'));
    await load;

    expect(service.currentUser?.displayName, 'A');
  });

  test('an older load finishing last does not replace the newer profile',
      () async {
    auth.emit('uid-a');
    await settle();
    final old = service.loadProfile('uid-a');
    auth.emit(null);
    await settle();
    auth.emit('uid-a');
    await settle();
    final fresh = service.loadProfile('uid-a');

    store.reads[1].complete(_Snapshot('uid-a', 'new'));
    await fresh;
    store.reads[0].complete(_Snapshot('uid-a', 'old'));
    await old;

    expect(service.currentUser?.displayName, 'new');
  });

  test('a load of an ended session leaves no profile behind', () async {
    auth.emit('uid-a');
    await settle();
    final old = service.loadProfile('uid-a');
    auth.emit(null);
    await settle();
    auth.emit('uid-a');
    await settle();

    store.reads.single.complete(_Snapshot('uid-a', 'old'));
    await old;

    expect(service.currentUser, isNull,
        reason: 'the new session has not loaded its profile yet');
  });
}
