// Stub for future `flutterfire configure` output.
//
// The MVP intentionally runs without Firebase initialization so local demos do
// not need credentials and do not emit analytics, crash logs, or PHI-adjacent
// telemetry by default.
class FirebaseProjectStub {
  const FirebaseProjectStub({
    required this.projectId,
    required this.authDomain,
  });

  final String projectId;
  final String authDomain;
}

const firebaseProjectStub = FirebaseProjectStub(
  projectId: 'nguyenindoubt-demo',
  authDomain: 'nguyenindoubt-demo.firebaseapp.com',
);
