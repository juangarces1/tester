import 'package:tester/ConsoleModels/modelos_faces.dart';

class FaceView {
  final int pumpId;          // Surtidor físico
  final String? pumpName;    // "Surtidor 01"
  final int face;            // 1/2
  final int pos;             // POS global (1..N)
  final List<HoseView> hoses;

  FaceView({
    required this.pumpId,
    required this.pumpName,
    required this.face,
    required this.pos,
    required this.hoses,
  });
}
