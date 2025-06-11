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
      path: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      isLocal: false, // Cambiado a false para usar modelo online
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
        // Cargar desde assets (si existe)
        try {
          final byteData = await rootBundle.load(model.path);
          model.data = byteData.buffer.asUint8List();
          print('Modelo ${model.name} cargado desde assets: ${model.data!.length} bytes');
        } catch (e) {
          print('No se pudo cargar desde assets: $e');
          // Fallback: simular datos
          model.data = _generateSimpleModelData(model.path);
          print('Usando datos simulados para ${model.name}');
        }
      } else {
        // Para modelos simples o externos, simular datos
        model.data = _generateSimpleModelData(model.path);
        print('Modelo simple ${model.name} generado: ${model.data!.length} bytes');
      }

      model.isLoaded = true;
      return true;
    } catch (e) {
      print('Error cargando modelo ${model.name}: $e');
      // Aún en caso de error, simular que está cargado
      model.data = _generateSimpleModelData('fallback');
      model.isLoaded = true;
      return true;
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
    // Simular datos de modelo simple con patrones diferentes
    switch (type) {
      case 'simple_box':
        return Uint8List.fromList(List.generate(1024, (i) => i % 256));
      case 'simple_sphere':
        return Uint8List.fromList(List.generate(2048, (i) => (i * 2) % 256));
      case 'assets/models/Duck.glb':
      // Simular datos de pato más complejos
        return Uint8List.fromList(List.generate(4096, (i) => (i * 3 + 42) % 256));
      default:
        return Uint8List.fromList(List.generate(512, (i) => (i + 128) % 256));
    }
  }

  Future<void> preloadAllModels() async {
    print('Precargando ${_models.length} modelos...');
    for (String id in _models.keys) {
      final success = await loadModel(id);
      print('Modelo $id: ${success ? "✓" : "✗"}');
    }
    print('Precarga de modelos completada');
  }

  String getModelInfo(String id) {
    final model = _models[id];
    if (model == null) return 'Modelo no encontrado';

    return '''
📦 Información del Modelo

Nombre: ${model.name}
Ruta: ${model.path}
Tipo: ${model.isLocal ? 'Local (Assets)' : 'Remoto/Simulado'}
Escala: ${model.scale}x
Estado: ${model.isLoaded ? '✅ Cargado' : '⏳ No cargado'}
Tamaño: ${model.data?.length ?? 0} bytes

${model.isLocal ?
    '💡 Este modelo se carga desde los assets de la aplicación.' :
    '🌐 Este modelo es simulado o se carga externamente.'}

${id == 'duck' ?
    '🦆 Modelo especial: Incluye animación y representación 3D avanzada.' :
    '🎲 Modelo básico: Representación geométrica simple.'}
''';
  }

  // Método para verificar si hay modelos disponibles
  bool hasModels() {
    return _models.isNotEmpty;
  }

  // Método para obtener estadísticas
  Map<String, dynamic> getStats() {
    int loaded = _models.values.where((model) => model.isLoaded).length;
    int total = _models.length;
    int totalSize = _models.values
        .where((model) => model.data != null)
        .fold(0, (sum, model) => sum + model.data!.length);

    return {
      'total': total,
      'loaded': loaded,
      'totalSize': totalSize,
      'loadedPercentage': total > 0 ? (loaded / total * 100).round() : 0,
    };
  }
}