import 'package:flutter/foundation.dart';
import 'package:tester/ConsoleModels/modelos_faces.dart';


class FacesProvider extends ChangeNotifier {
  final List<FaceView> _faces;
  FacesProvider(this._faces);

  List<FaceView> get faces => _faces;

  FaceView? getByPos(int pos) =>
      _faces.firstWhere((f) => f.pos == pos, orElse: () => throw StateError('POS no encontrado'));
}
