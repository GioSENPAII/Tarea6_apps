import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class Model3D {
  final String name;
  final String path;
  final bool isLocal;
  final double scale;
  Uint8List? data;
  bool isLoaded = false;

  Model3D({
    required this.name,
    required this.path,
    this.isLocal = true,
    this.scale = 1.0,
  });
}

class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  final Map<String, Model3D> _models = {};

  // Modelos predefinidos
  void initializeDefaultModels() {
    _models['duck'] = Model3D(
      name: 'Pato 3D',
      path: 'assets/models/Duck.glb',
      isLocal: true,
      scale: 0.5,
    );

    _models['box'] = Model3D(
      name: 'Cubo Simple',
      path: 'simple_box',
      isLocal: false,
      scale: 1.0,
    );

    _models['sphere'] = Model3D(
      name: 'Esfera Simple',
      path: 'simple_sphere',
      isLocal: false,
      scale: 1.0,
    );
  }

  List<Model3D> getAvailableModels() {
    return _models.values.toList();
  }

  Model3D? getModel(String id) {
    return _models[id];
  }

  Future<bool> loadModel(String id) async {
    final model = _models[id];
    if (model == null) return false;

    if (model.isLoaded) return true;

    try {
      if (model.isLocal) {
        // Cargar desde assets
        final byteData = await rootBundle.load(model.path);
        model.data = byteData.buffer.asUint8List();
        print('Modelo ${model.name} cargado desde assets: ${model.data!.length} bytes');
      } else {
        // Para modelos simples, simular datos
        model.data = _generateSimpleModelData(model.path);
        print('Modelo simple ${model.name} generado: ${model.data!.length} bytes');
      }

      model.isLoaded = true;
      return true;
    } catch (e) {
      print('Error cargando modelo ${model.name}: $e');
      return false;
    }
  }

  Future<bool> loadModelFromUrl(String id, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final model = Model3D(
          name: 'Modelo desde URL',
          path: url,
          isLocal: false,
        );
        model.data = response.bodyBytes;
        model.isLoaded = true;
        _models[id] = model;
        print('Modelo cargado desde URL: ${model.data!.length} bytes');
        return true;
      }
    } catch (e) {
      print('Error cargando modelo desde URL: $e');
    }
    return false;
  }

  Uint8List _generateSimpleModelData(String type) {
    // Simular datos de modelo simple
    switch (type) {
      case 'simple_box':
        return Uint8List.fromList(List.generate(1024, (i) => i % 256));
      case 'simple_sphere':
        return Uint8List.fromList(List.generate(2048, (i) => (i * 2) % 256));
      default:
        return Uint8List.fromList([0, 1, 2, 3, 4, 5]);
    }
  }

  Future<void> preloadAllModels() async {
    for (String id in _models.keys) {
      await loadModel(id);
    }
  }

  String getModelInfo(String id) {
    final model = _models[id];
    if (model == null) return 'Modelo no encontrado';

    return '''
Nombre: ${model.name}
Ruta: ${model.path}
Tipo: ${model.isLocal ? 'Local' : 'Remoto'}
Escala: ${model.scale}
Cargado: ${model.isLoaded ? 'Sí' : 'No'}
Tamaño: ${model.data?.length ?? 0} bytes
''';
  }
}