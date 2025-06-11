import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'model_manager.dart';
import 'model_3d_viewer.dart';

class PlacedObject {
  final String id;
  final String modelId;
  Offset position;
  double scale;
  double rotation;
  final DateTime placedAt;

  // Estado original para reset
  final Offset originalPosition;
  final double originalScale;
  final double originalRotation;

  PlacedObject({
    required this.id,
    required this.modelId,
    required this.position,
    this.scale = 1.5, // Tamaño inicial más grande
    this.rotation = 0.0,
    DateTime? placedAt,
  }) : placedAt = placedAt ?? DateTime.now(),
        originalPosition = position,
        originalScale = scale,
        originalRotation = rotation;

  // Método para resetear transformaciones
  void resetTransformations() {
    position = originalPosition;
    scale = originalScale;
    rotation = originalRotation;
  }

  // Método para aplicar transformaciones
  void updateTransform({
    Offset? newPosition,
    double? newScale,
    double? newRotation,
  }) {
    if (newPosition != null) position = newPosition;
    if (newScale != null) scale = newScale.clamp(0.5, 5.0); // Límites más amplios
    if (newRotation != null) rotation = newRotation % 360; // Normalizar rotación
  }
}

class ARScreen extends StatefulWidget {
  @override
  _ARScreenState createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  String _statusMessage = 'Inicializando AR...';
  bool _isARSupported = false;
  List<PlacedObject> _placedObjects = [];
  String _selectedModelId = 'duck';
  ModelManager _modelManager = ModelManager();
  bool _isLoadingModels = true;

  // Variables para gestos
  PlacedObject? _selectedObject;
  bool _isManipulating = false;
  double _lastScale = 1.0;
  double _lastRotation = 0.0;
  Offset _initialFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initializeAR();
  }

  Future<void> _initializeAR() async {
    setState(() {
      _statusMessage = 'Cargando modelos 3D...';
    });

    // Inicializar modelos
    _modelManager.initializeDefaultModels();

    // Precargar modelos
    await _modelManager.preloadAllModels();

    setState(() {
      _isLoadingModels = false;
      _isARSupported = true;
      _statusMessage = 'AR listo - Selecciona un modelo y toca para colocarlo';
    });

    // Mostrar tutorial inicial
    _showInitialTutorial();
  }

  void _showInitialTutorial() {
    Future.delayed(Duration(seconds: 1), () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('¡Bienvenido a AR!', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎯 Cómo usar la aplicación:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('1. Selecciona un modelo de la lista inferior'),
                Text('2. Toca el área azul central para colocar el objeto'),
                Text('3. Toca un objeto para seleccionarlo'),
                SizedBox(height: 10),
                Text('🎮 Gestos de manipulación:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('• Un dedo: Mover objeto'),
                Text('• Dos dedos: Pellizcar para escalar'),
                Text('• Dos dedos: Rotar para girar'),
                Text('• Botón restore: Restablecer'),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📦 Sobre los modelos 3D:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• El pato carga un archivo GLTF real (Duck.glb)',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                      ),
                      Text(
                        '• Se muestra como representación visual',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                      ),
                      Text(
                        '• El archivo 3D real está cargado en memoria',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Más Info'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showModelInfo();
                },
              ),
              TextButton(
                child: Text('¡Entendido!', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    });
  }

  void _onScreenTap(TapDownDetails details) {
    if (_isARSupported && !_isLoadingModels) {
      // Usar la posición real del toque
      _placeObject(details.localPosition);
    }
  }

  void _placeObject(Offset position) {
    final model = _modelManager.getModel(_selectedModelId);
    if (model == null || !model.isLoaded) {
      _showMessage('Error: Modelo no disponible');
      return;
    }

    final newObject = PlacedObject(
      id: 'obj_${DateTime.now().millisecondsSinceEpoch}',
      modelId: _selectedModelId,
      position: position,
    );

    setState(() {
      _placedObjects.add(newObject);
      _statusMessage = '${model.name} colocado - ${_placedObjects.length} objetos en escena';
    });
  }

  void _removeObject(String objectId) {
    setState(() {
      _placedObjects.removeWhere((obj) => obj.id == objectId);
      _statusMessage = 'Objeto eliminado - ${_placedObjects.length} objetos en escena';
    });
  }

  void _resetScene() {
    setState(() {
      _placedObjects.clear();
      _selectedObject = null;
      _statusMessage = 'Escena reiniciada - Toca para colocar objeto';
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Métodos para gestos de manipulación (solo usando Scale gestures)
  void _onObjectScaleStart(PlacedObject object, ScaleStartDetails details) {
    setState(() {
      _selectedObject = object;
      _isManipulating = true;
      _lastScale = object.scale;
      _lastRotation = object.rotation;
      _initialFocalPoint = details.focalPoint;
      _statusMessage = 'Manipulando ${_modelManager.getModel(object.modelId)?.name} - Usa 1 dedo para mover, 2 para escalar/rotar';
    });
  }

  void _onObjectScaleUpdate(ScaleUpdateDetails details) {
    if (_selectedObject != null) {
      setState(() {
        // Si es solo un dedo (movimiento)
        if (details.pointerCount == 1) {
          // Mover el objeto
          final delta = details.focalPoint - _initialFocalPoint;
          _selectedObject!.updateTransform(
            newPosition: _selectedObject!.position + delta,
          );
          _initialFocalPoint = details.focalPoint;
          _statusMessage = 'Moviendo ${_modelManager.getModel(_selectedObject!.modelId)?.name}';
        }
        // Si son dos dedos (escalar y rotar)
        else if (details.pointerCount >= 2) {
          // Escalar
          final newScale = _lastScale * details.scale;

          // Rotar con mayor sensibilidad
          final rotationSensitivity = 2.0;
          final newRotation = _lastRotation + (details.rotation * 180 / 3.14159 * rotationSensitivity);

          _selectedObject!.updateTransform(
            newScale: newScale,
            newRotation: newRotation,
          );

          _statusMessage = '${_modelManager.getModel(_selectedObject!.modelId)?.name} - Escala: ${newScale.toStringAsFixed(1)}x, Rotación: ${(newRotation % 360).toStringAsFixed(0)}°';
        }
      });
    }
  }

  void _onObjectScaleEnd(ScaleEndDetails details) {
    if (_selectedObject != null) {
      final finalScale = _selectedObject!.scale;
      final finalRotation = _selectedObject!.rotation % 360;

      setState(() {
        _isManipulating = false;
        _statusMessage = 'Transformación completada - Escala: ${finalScale.toStringAsFixed(1)}x, Rotación: ${finalRotation.toStringAsFixed(0)}°';
      });

      // Mostrar información detallada
      _showTransformationComplete(finalScale, finalRotation);
    }
  }

  void _showTransformationComplete(double scale, double rotation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Objeto transformado: ${scale.toStringAsFixed(1)}x escala, ${rotation.toStringAsFixed(0)}° rotación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetObjectTransformations(PlacedObject object) {
    setState(() {
      object.resetTransformations();
      _statusMessage = '${_modelManager.getModel(object.modelId)?.name} restablecido';
    });
  }

  void _selectObject(PlacedObject object) {
    setState(() {
      _selectedObject = _selectedObject?.id == object.id ? null : object;
      _statusMessage = _selectedObject != null
          ? '${_modelManager.getModel(object.modelId)?.name} seleccionado - Usa gestos para manipular'
          : 'Objeto deseleccionado';
    });
  }

  Widget _buildModelSelector() {
    final models = _modelManager.getAvailableModels();

    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10),
        itemCount: models.length,
        itemBuilder: (context, index) {
          final model = models[index];
          final modelId = ['duck', 'box', 'sphere'][index];
          final isSelected = _selectedModelId == modelId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedModelId = modelId;
                _statusMessage = '${model.name} seleccionado - Toca el área azul para colocar';
              });
            },
            child: Container(
              width: 100,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getModelIcon(modelId),
                    size: 40,
                    color: isSelected ? Colors.white : Colors.blue,
                  ),
                  SizedBox(height: 5),
                  Text(
                    model.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (model.isLoaded)
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.green,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getModelIcon(String modelId) {
    switch (modelId) {
      case 'duck':
        return Icons.pets;
      case 'box':
        return Icons.crop_square;
      case 'sphere':
        return Icons.circle;
      default:
        return Icons.view_in_ar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vista AR - Modelos 3D'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => _showModelInfo(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetScene,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Área de AR
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade100,
                  Colors.blue.shade300,
                ],
              ),
            ),
            child: _isLoadingModels
                ? _buildLoadingView()
                : _buildARView(),
          ),

          // Overlay con información
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.black54,
              child: Text(
                _statusMessage,
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Selector de modelos
          if (!_isLoadingModels)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: _buildModelSelector(),
            ),

          // Controles
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "reset",
                  onPressed: _resetScene,
                  child: Icon(Icons.clear),
                  backgroundColor: Colors.red,
                ),
                if (_selectedObject != null)
                  FloatingActionButton(
                    heroTag: "resetTransform",
                    onPressed: () => _resetObjectTransformations(_selectedObject!),
                    child: Icon(Icons.restore),
                    backgroundColor: Colors.orange,
                  ),
                FloatingActionButton(
                  heroTag: "info",
                  onPressed: () => _showModelInfo(),
                  child: Icon(Icons.info),
                  backgroundColor: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARView() {
    return Stack(
      children: [
        // Objetos colocados
        ..._placedObjects.map((obj) => _buildPlacedObject(obj)).toList(),

        // Área central para colocar objetos
        Center(
          child: GestureDetector(
            onTapDown: _onScreenTap,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_in_ar, size: 60, color: Colors.blue),
                  SizedBox(height: 10),
                  Text('Área AR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text('${_placedObjects.length} objetos', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text('Toca para colocar', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlacedObject(PlacedObject obj) {
    final model = _modelManager.getModel(obj.modelId);
    final isSelected = _selectedObject?.id == obj.id;
    final baseSize = 80.0;
    final size = baseSize * obj.scale;

    return Positioned(
      left: obj.position.dx - (size / 2),
      top: obj.position.dy - (size / 2),
      child: GestureDetector(
        onTap: () => _selectObject(obj),
        onScaleStart: (details) => _onObjectScaleStart(obj, details),
        onScaleUpdate: _onObjectScaleUpdate,
        onScaleEnd: _onObjectScaleEnd,
        child: Transform.rotate(
          angle: obj.rotation * 3.14159 / 180,
          child: Container(
            width: size,
            height: size,
            child: Stack(
              children: [
                // Objeto 3D principal
                _build3DModel(obj.modelId, size, isSelected),
                // Indicador de selección
                if (isSelected)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(size / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.6),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                // Info del objeto
                if (isSelected)
                  Positioned(
                    top: -25,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${model?.name ?? 'Objeto'}\nEscala: ${obj.scale.toStringAsFixed(1)}x',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DModel(String modelId, double size, bool isSelected) {
    // Usar el visor 3D real solo para el pato
    if (modelId == 'duck') {
      return Simple3DViewer(
        modelId: modelId,
        size: size,
        isSelected: isSelected,
      );
    }

    // Fallback para otros modelos
    return _buildFallbackModel(modelId, size, isSelected);
  }

  Widget _buildFallbackModel(String modelId, double size, bool isSelected) {
    switch (modelId) {
      case 'box':
        return _buildBoxModel3D(size, isSelected);
      case 'sphere':
        return _buildSphereModel3D(size, isSelected);
      default:
        return _buildDefaultModel3D(size, isSelected);
    }
  }

  Widget _buildBoxModel3D(double size, bool isSelected) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade300,
            Colors.blue.shade600,
            Colors.blue.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Indicador 3D
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '3D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.crop_square,
              size: size * 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSphereModel3D(double size, bool isSelected) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [
            Colors.purple.shade100,
            Colors.purple.shade300,
            Colors.purple.shade600,
            Colors.purple.shade900,
          ],
          stops: [0.1, 0.4, 0.7, 1.0],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: Offset(3, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Brillo realista
          Positioned(
            top: size * 0.15,
            left: size * 0.2,
            child: Container(
              width: size * 0.3,
              height: size * 0.2,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          // Indicador 3D
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '3D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.circle,
              size: size * 0.4,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultModel3D(double size, bool isSelected) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade300, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        Icons.view_in_ar,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoadingModel(double size, bool isSelected, String modelId) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 5),
          Text(
            'Cargando...',
            style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text('Cargando modelos 3D...', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  void _showModelInfo() {
    final model = _modelManager.getModel(_selectedModelId);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Información del Modelo'),
          content: SingleChildScrollView(
            child: Text(_modelManager.getModelInfo(_selectedModelId)),
          ),
          actions: [
            TextButton(
              child: Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}