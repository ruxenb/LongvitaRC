// NC-02 manual QA entry point, not a widget-test suite.
// Runs ONLY on an isolated Android app with the three pinned FlutterFire
// packages. Auth/Firestore targets are local demo-longvita emulators.
// The administrative REST calls below are GET-only independent server probes;
// every tested write uses the real client repository and Firebase Auth.
// See evidence/firebase/NC-02-metadata-20261109/README.md for reproduction.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// File-based imports compile the checked-out source in the isolated minimal
// QA app, which only configures Auth/Firestore emulators.
// ignore: avoid_relative_lib_imports
import 'package:longvita_core/services/firestore_report_metadata_repository.dart';
// ignore: avoid_relative_lib_imports
import 'package:longvita_core/models/report_metadata.dart';

const project = 'demo-longvita';
const emulatorHost = '10.0.2.2';
void emit(String step, Map<String, Object?> fields) =>
    debugPrint('NC02 ${jsonEncode({'step': step, ...fields})}');
void check(bool value, String message) {
  if (!value) throw StateError(message);
}

class Observation {
  String state = 'pending';
  Object? error;
  final done = Completer<void>();
  Observation(Future<void> original) {
    original.then(
      (_) {
        state = 'confirmed';
        done.complete();
      },
      onError: (Object e) {
        state = 'error';
        error = e;
        done.complete();
      },
    );
  }
}

Future<Map<String, dynamic>?> serverDocument(String path) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final url = Uri.parse(
      'http://$emulatorHost:8185/v1/projects/$project/databases/(default)/documents/$path',
    );
    check(
      url.host == emulatorHost &&
          url.port == 8185 &&
          project == 'demo-longvita',
      'Unsafe emulator target',
    );
    final req = await client.getUrl(url);
    // Emulator administrative GET only, independent of the client cache/auth.
    req.headers.set('Authorization', 'Bearer owner');
    final response = await req.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode == 404) return null;
    check(
      response.statusCode == 200,
      'Emulator GET status ${response.statusCode}',
    );
    return jsonDecode(body) as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

Future<void> verifyClientDocument(
  FirebaseFirestore db,
  String path,
  ReportMetadata value,
) async {
  final doc = await db.doc(path).get(const GetOptions(source: Source.server));
  final data = doc.data();
  final expected = value.toMap();
  check(
    data != null &&
        data.length == expected.length &&
        expected.entries.every((e) => data[e.key] == e.value),
    'Client readback mismatch',
  );
}

Future<void> runProbe() async {
  final app = await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSy000000000000000000000000000000000',
      appId: '1:1234567890:android:abcdef1234567890',
      messagingSenderId: '1234567890',
      projectId: project,
    ),
  );
  check(app.options.projectId == project, 'Not a demo project');
  final auth = FirebaseAuth.instanceFor(app: app);
  await auth.useAuthEmulator(emulatorHost, 9099);
  final db = FirebaseFirestore.instanceFor(app: app);
  db.settings = const Settings(persistenceEnabled: true);
  db.useFirestoreEmulator(emulatorHost, 8185);
  final repository = FirestoreReportMetadataRepository(firestore: db);
  final run = DateTime.now().microsecondsSinceEpoch;
  final password = 'nc02-test-only-password';
  final emailA = 'nc02-a-$run@example.test';
  final a = await auth.createUserWithEmailAndPassword(
    email: emailA,
    password: password,
  );
  final uidA = a.user!.uid;
  final first = ReportMetadata.forNewExport(
    createdAt: DateTime.now().toUtc(),
    planId: null,
    sizeBytes: 20000,
  );
  final firstPath = FirestoreReportMetadataRepository.documentPath(
    uidA,
    first.exportId,
  );
  await db.disableNetwork();
  final s1 = Observation(repository.save(uidA, first));
  final local1 = await db
      .doc(firstPath)
      .snapshots(includeMetadataChanges: true)
      .firstWhere((d) => d.exists && d.metadata.hasPendingWrites)
      .timeout(const Duration(seconds: 15));
  final before1 = await serverDocument(firstPath);
  check(
    s1.state == 'pending' &&
        before1 == null &&
        local1.metadata.hasPendingWrites,
    'S1 did not observe offline pending',
  );
  emit('S1-offline', {
    'localPendingWrites': true,
    'originalFuture': s1.state,
    'serverExists': false,
  });
  await db.enableNetwork();
  await s1.done.future.timeout(const Duration(seconds: 20));
  check(s1.state == 'confirmed', 'S1 failed to ack');
  await verifyClientDocument(db, firstPath, first);
  check(
    await serverDocument(firstPath) != null,
    'S1 no independent server record',
  );
  final own = await db
      .collection('users/$uidA/report_exports')
      .get(const GetOptions(source: Source.server));
  check(own.docs.length == 1, 'S1 duplicate documents');
  emit('S1-online', {
    'originalFuture': s1.state,
    'serverPayloadMatches': true,
    'documentCount': own.docs.length,
  });

  final second = ReportMetadata.forNewExport(
    createdAt: DateTime.now().toUtc(),
    planId: null,
    sizeBytes: 21000,
  );
  final secondPath = FirestoreReportMetadataRepository.documentPath(
    uidA,
    second.exportId,
  );
  await db.disableNetwork();
  final s2 = Observation(repository.save(uidA, second));
  await db
      .doc(secondPath)
      .snapshots(includeMetadataChanges: true)
      .firstWhere((d) => d.exists && d.metadata.hasPendingWrites)
      .timeout(const Duration(seconds: 15));
  check(
    await serverDocument(secondPath) == null && s2.state == 'pending',
    'S2 not initially pending',
  );
  emit('S2-A-offline', {'originalFuture': s2.state, 'serverAExists': false});
  await auth.signOut();
  final b = await auth.createUserWithEmailAndPassword(
    email: 'nc02-b-$run@example.test',
    password: password,
  );
  final uidB = b.user!.uid;
  check(uidA != uidB, 'Not distinct test users');
  await db.enableNetwork();
  final bPath = FirestoreReportMetadataRepository.documentPath(
    uidB,
    second.exportId,
  );
  final bRead = await db
      .doc(bPath)
      .get(const GetOptions(source: Source.server));
  check(!bRead.exists, 'B received A record');
  final aWhileB = await serverDocument(secondPath);
  check(await serverDocument(bPath) == null, 'B server record exists');
  emit('S2-B-online', {
    'originalFuture': s2.state,
    'serverAExists': aWhileB != null,
    'serverBExists': false,
    'BClientRead': 'missing',
  });
  await auth.signOut();
  await auth.signInWithEmailAndPassword(email: emailA, password: password);
  await s2.done.future.timeout(const Duration(seconds: 20));
  check(s2.state == 'confirmed', 'Original A write did not finish on re-login');
  await verifyClientDocument(db, secondPath, second);
  check(
    await serverDocument(secondPath) != null &&
        await serverDocument(bPath) == null,
    'S2 server readback mismatch',
  );
  emit('S2-A-return', {
    'originalFuture': s2.state,
    'serverAExists': true,
    'serverBExists': false,
    'payloadMatches': true,
    'additionalWrites': 0,
  });
  await auth.signOut();
  emit('RESULT', {
    'passed': true,
    'sdk': 'cloud_firestore 5.6.12 / firebase_auth 5.7.0',
    'project': project,
    'productionWrites': 0,
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('NC-02 isolated SDK probe'))),
    ),
  );
  runProbe().catchError((Object error, StackTrace trace) {
    emit('RESULT', {'passed': false, 'error': error.toString()});
  });
}
