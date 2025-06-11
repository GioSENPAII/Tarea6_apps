import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARScreen extends StatefulWidget {
  @override
  _ARScreenState createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = <ARNode>[];
  List<ARAnchor> anchors = <ARAnchor>[];

  String _statusMessage = 'Inicializando AR...';
  bool _isSessionInitialized = false;

  @override
  void dispose() {
    super.dispose();
    arSessionManager?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vista AR'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _clearAnchorsAndNodes,
          ),
        ],
      ),
      body: Container(
        child: Stack(
          children: [
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Botón de limpiar
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _clearAnchorsAndNodes,
                child: Icon(Icons.clear),
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );

    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onPanStart = onPanStarted;
    this.arObjectManager!.onPanChange = onPanChanged;
    this.arObjectManager!.onPanEnd = onPanEnded;
    this.arObjectManager!.onRotationStart = onRotationStarted;
    this.arObjectManager!.onRotationChange = onRotationChanged;
    this.arObjectManager!.onRotationEnd = onRotationEnded;

    setState(() {
      _statusMessage = 'AR inicializado - Busca una superficie y toca para colocar objeto';
      _isSessionInitialized = true;
    });

    print('AR View inicializado correctamente');
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhere(
          (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );

    if (singleHitTestResult != null) {
      var newAnchor = ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      bool? didAddAnchor = await this.arAnchorManager!.addAnchor(newAnchor);

      if (didAddAnchor!) {
        this.anchors.add(newAnchor);
        // Añadir un cubo simple
        var newNode = ARNode(
          type: NodeType.webGLB,
          uri: "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb",
          scale: vector.Vector3(0.2, 0.2, 0.2),
          position: vector.Vector3(0.0, 0.0, 0.0),
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
        );

        bool? didAddNodeToAnchor = await this.arObjectManager!.addNode(newNode, planeAnchor: newAnchor);

        if (didAddNodeToAnchor!) {
          this.nodes.add(newNode);
          setState(() {
            _statusMessage = 'Objeto colocado - Puedes moverlo y rotarlo con gestos';
          });
          print('Nodo añadido correctamente');
        } else {
          this.arAnchorManager!.removeAnchor(newAnchor);
          print('Error añadiendo nodo');
        }
      }
    }
  }

  onPanStarted(String nodeName) {
    print("Comenzó el arrastre del nodo " + nodeName);
  }

  onPanChanged(String nodeName) {
    print("Arrastrando nodo " + nodeName);
  }

  onPanEnded(String nodeName, Matrix4 newTransform) {
    print("Terminó el arrastre del nodo " + nodeName);
    final pannedNode = this.nodes.firstWhere((element) => element.name == nodeName);

    /*
    * Nota: Debido a limitaciones actuales en el plugin, la transformación no se puede
    * actualizar directamente aquí. En versiones futuras esto debería funcionar.
    */
  }

  onRotationStarted(String nodeName) {
    print("Comenzó la rotación del nodo " + nodeName);
  }

  onRotationChanged(String nodeName) {
    print("Rotando nodo " + nodeName);
  }

  onRotationEnded(String nodeName, Matrix4 newTransform) {
    print("Terminó la rotación del nodo " + nodeName);
    final rotatedNode = this.nodes.firstWhere((element) => element.name == nodeName);

    /*
    * Nota: Debido a limitaciones actuales en el plugin, la transformación no se puede
    * actualizar directamente aquí. En versiones futuras esto debería funcionar.
    */
  }

  Future<void> _clearAnchorsAndNodes() async {
    for (var anchor in this.anchors) {
      this.arAnchorManager!.removeAnchor(anchor);
    }
    anchors.clear();

    for (var node in this.nodes) {
      this.arObjectManager!.removeNode(node);
    }
    nodes.clear();

    setState(() {
      _statusMessage = 'Objetos eliminados - Toca para colocar nuevo objeto';
    });

    print('Todos los objetos eliminados');
  }
}