import 'package:flutter/material.dart' as material;
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'dart:typed_data';

class ARScreen extends material.StatefulWidget {
  @override
  _ARScreenState createState() => _ARScreenState();
}

class _ARScreenState extends material.State<ARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  ARNode? selectedNode;

  // Variables para gestos
  double initialScale = 0.2;
  String statusMessage = 'Inicializando AR...';

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      appBar: material.AppBar(
        title: material.Text('AR - Modelos 3D'),
        backgroundColor: material.Colors.blue,
        actions: [
          material.IconButton(
            icon: material.Icon(material.Icons.info),
            onPressed: _showInfo,
          ),
          material.IconButton(
            icon: material.Icon(material.Icons.refresh),
            onPressed: _resetScene,
          ),
        ],
      ),
      body: material.Stack(
        children: [
          // Vista AR
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          // Información superior
          material.Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: material.Container(
              padding: material.EdgeInsets.all(16),
              color: material.Colors.black54,
              child: material.Text(
                statusMessage,
                style: material.TextStyle(color: material.Colors.white, fontSize: 16),
                textAlign: material.TextAlign.center,
              ),
            ),
          ),

          // Controles inferiores
          material.Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: material.Column(
              children: [
                // Información del modelo
                material.Container(
                  margin: material.EdgeInsets.symmetric(horizontal: 20),
                  padding: material.EdgeInsets.all(12),
                  decoration: material.BoxDecoration(
                    color: material.Colors.white,
                    borderRadius: material.BorderRadius.circular(10),
                    boxShadow: [
                      material.BoxShadow(
                        color: material.Colors.black26,
                        blurRadius: 4,
                        offset: material.Offset(0, 2),
                      ),
                    ],
                  ),
                  child: material.Row(
                    mainAxisAlignment: material.MainAxisAlignment.center,
                    children: [
                      material.Icon(material.Icons.pets, color: material.Colors.orange, size: 30),
                      material.SizedBox(width: 10),
                      material.Column(
                        crossAxisAlignment: material.CrossAxisAlignment.start,
                        children: [
                          material.Text(
                            'Modelo: Duck.glb',
                            style: material.TextStyle(
                              fontWeight: material.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          material.Text(
                            'Toca un plano para colocar',
                            style: material.TextStyle(
                              color: material.Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                material.SizedBox(height: 10),

                // Botón de reset transformaciones
                if (nodes.isNotEmpty)
                  material.FloatingActionButton.extended(
                    onPressed: () {
                      if (selectedNode != null) {
                        _resetNodeTransform();
                      }
                    },
                    label: material.Text('Restablecer Transformaciones'),
                    icon: material.Icon(material.Icons.restore),
                    backgroundColor: material.Colors.orange,
                  ),
              ],
            ),
          ),

          // Contador de objetos
          material.Positioned(
            top: 80,
            right: 20,
            child: material.Container(
              padding: material.EdgeInsets.all(8),
              decoration: material.BoxDecoration(
                color: material.Colors.blue,
                borderRadius: material.BorderRadius.circular(20),
              ),
              child: material.Text(
                'Objetos: ${nodes.length}',
                style: material.TextStyle(
                  color: material.Colors.white,
                  fontWeight: material.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );
    this.arObjectManager!.onInitialize();

    // Configurar callbacks - Usando las firmas correctas
    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onNodeTap = onNodeTapped;

    // Callbacks simplificados - el plugin maneja los gestos internamente

    setState(() {
      statusMessage = 'AR listo - Busca y toca un plano para colocar el pato';
    });
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhere(
            (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
        orElse: () => hitTestResults.first);

    if (singleHitTestResult != null) {
      await _addDuck(singleHitTestResult);
    }
  }

  Future<void> _addDuck(ARHitTestResult hitTestResult) async {
    // Crear nodo del pato
    var newNode = ARNode(
      type: NodeType.localGLTF2,
      uri: "assets/models/Duck.glb",
      scale: Vector3(initialScale, initialScale, initialScale),
      position: Vector3(
        hitTestResult.worldTransform.storage[12],
        hitTestResult.worldTransform.storage[13],
        hitTestResult.worldTransform.storage[14],
      ),
      rotation: Vector4(1, 0, 0, 0),
    );

    // Añadir el nodo
    bool? didAddNode = await arObjectManager!.addNode(newNode);

    if (didAddNode == true) {
      nodes.add(newNode);
      setState(() {
        statusMessage = 'Pato colocado - Total: ${nodes.length} objetos';
      });

      // Mostrar mensaje de éxito
      if (mounted) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text('🦆 Pato colocado exitosamente'),
            backgroundColor: material.Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void onNodeTapped(List<String> nodeNames) {
    if (nodeNames.isNotEmpty) {
      var tappedNode = nodes.firstWhere(
            (node) => node.name == nodeNames.first,
        orElse: () => nodes.first,
      );

      setState(() {
        selectedNode = tappedNode;
        statusMessage = 'Pato seleccionado - El plugin maneja los gestos automáticamente';
      });

      // Mostrar info de gestos
      if (mounted) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text('Usa 1 dedo para mover, 2 para rotar/escalar'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _resetNodeTransform() {
    if (selectedNode != null) {
      // Eliminar nodo actual
      arObjectManager!.removeNode(selectedNode!);
      nodes.remove(selectedNode!);

      // Crear nuevo nodo con transformaciones iniciales
      var resetNode = ARNode(
        type: NodeType.localGLTF2,
        uri: "assets/models/Duck.glb",
        scale: Vector3(initialScale, initialScale, initialScale),
        position: selectedNode!.position ?? Vector3.zero(),
        rotation: Vector4(1, 0, 0, 0),
      );

      // Añadir el nuevo nodo
      arObjectManager!.addNode(resetNode).then((didAdd) {
        if (didAdd == true) {
          nodes.add(resetNode);
          selectedNode = resetNode;
          setState(() {
            statusMessage = 'Transformaciones restablecidas';
          });
        }
      });
    }
  }

  void _resetScene() {
    // Eliminar todos los nodos
    for (var node in nodes) {
      arObjectManager!.removeNode(node);
    }

    nodes.clear();
    selectedNode = null;

    setState(() {
      statusMessage = 'Escena reiniciada - Toca un plano para comenzar';
    });
  }

  void _showInfo() {
    material.showDialog(
      context: context,
      builder: (material.BuildContext context) {
        return material.AlertDialog(
          title: material.Text('Información AR'),
          content: material.SingleChildScrollView(
            child: material.Column(
              crossAxisAlignment: material.CrossAxisAlignment.start,
              mainAxisSize: material.MainAxisSize.min,
              children: [
                material.Text('🎯 Cómo usar:', style: material.TextStyle(fontWeight: material.FontWeight.bold)),
                material.SizedBox(height: 10),
                material.Text('1. Mueve el dispositivo para detectar planos'),
                material.Text('2. Los planos aparecerán como superficies detectadas'),
                material.Text('3. Toca un plano para colocar el pato'),
                material.Text('4. Toca el pato para seleccionarlo'),
                material.SizedBox(height: 10),
                material.Text('🎮 Gestos automáticos:', style: material.TextStyle(fontWeight: material.FontWeight.bold)),
                material.SizedBox(height: 5),
                material.Text('• 1 dedo: Mover objeto'),
                material.Text('• 2 dedos pellizcar: Escalar'),
                material.Text('• 2 dedos rotar: Girar objeto'),
                material.Text('• Los gestos son manejados por el plugin'),
                material.SizedBox(height: 10),
                material.Text('📦 Modelo 3D:', style: material.TextStyle(fontWeight: material.FontWeight.bold)),
                material.SizedBox(height: 5),
                material.Text('• Archivo: Duck.glb'),
                material.Text('• Formato: glTF Binary'),
                material.Text('• Renderizado en tiempo real con ARCore/ARKit'),
                material.SizedBox(height: 10),
                material.Container(
                  padding: material.EdgeInsets.all(8),
                  decoration: material.BoxDecoration(
                    color: material.Colors.blue.shade50,
                    borderRadius: material.BorderRadius.circular(8),
                  ),
                  child: material.Row(
                    children: [
                      material.Icon(material.Icons.info_outline, color: material.Colors.blue),
                      material.SizedBox(width: 8),
                      material.Expanded(
                        child: material.Text(
                          'Nota: Los gestos de manipulación son manejados automáticamente por ar_flutter_plugin',
                          style: material.TextStyle(fontSize: 12, color: material.Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            material.TextButton(
              child: material.Text('Entendido'),
              onPressed: () => material.Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}