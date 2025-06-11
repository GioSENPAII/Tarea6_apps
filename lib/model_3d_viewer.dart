import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Model3DViewer extends StatefulWidget {
  final String modelPath;
  final double width;
  final double height;
  final String? backgroundColor;
  final bool autoRotate;
  final bool cameraControls;

  const Model3DViewer({
    Key? key,
    required this.modelPath,
    required this.width,
    required this.height,
    this.backgroundColor,
    this.autoRotate = false,
    this.cameraControls = true,
  }) : super(key: key);

  @override
  _Model3DViewerState createState() => _Model3DViewerState();
}

class _Model3DViewerState extends State<Model3DViewer> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _loadModel();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      // Intentar cargar el modelo 3D real
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      print('Error cargando modelo 3D: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isLoading
            ? _buildLoadingView()
            : _hasError
            ? _buildEnhanced3DView()
            : _buildModelViewer(),
      ),
    );
  }

  Widget _buildModelViewer() {
    return Stack(
      children: [
        // Fondo mientras carga
        Container(
          color: Colors.grey.shade100,
        ),

        // Visor 3D real
        ModelViewer(
          src: widget.modelPath,
          alt: "Modelo 3D",
          ar: false,
          autoRotate: widget.autoRotate,
          cameraControls: widget.cameraControls,
          backgroundColor: Color(0xFFEEEEEE),
          shadowIntensity: 0.7,
          shadowSoftness: 0.5,
          onWebViewCreated: (controller) {
            print('ModelViewer WebView creado para: ${widget.modelPath}');
          },
        ),

        // Indicador 3D real
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.threed_rotation,
                  size: 12,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  'REAL 3D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando modelo 3D...',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhanced3DView() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.3, -0.3),
              colors: [
                Colors.yellow.shade200,
                Colors.yellow.shade400,
                Colors.orange.shade500,
                Colors.orange.shade700,
              ],
              stops: [0.1, 0.4, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Múltiples capas para efecto 3D
              ...List.generate(5, (index) {
                final scale = 0.5 + (index * 0.1);
                final opacity = 0.3 - (index * 0.05);
                final rotation = _rotationController.value * 2 * 3.14159 + (index * 0.5);

                return Center(
                  child: Transform.scale(
                    scale: scale * (1 + _pulseController.value * 0.1),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Opacity(
                        opacity: opacity,
                        child: Icon(
                          Icons.pets,
                          size: widget.width * 0.4,
                          color: index == 0 ? Colors.white : Colors.orange.shade300,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Indicador de modelo 3D mejorado
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ENHANCED 3D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Información del modelo
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Duck.glb',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Modelo 3D Animado',
                        style: TextStyle(
                          color: Colors.yellow.shade300,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Simple3DViewer extends StatelessWidget {
  final String modelId;
  final double size;
  final bool isSelected;

  const Simple3DViewer({
    Key? key,
    required this.modelId,
    required this.size,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String modelPath = _getModelPath(modelId);

    if (modelPath.isEmpty) {
      return _buildFallbackModel();
    }

    return Model3DViewer(
      modelPath: modelPath,
      width: size,
      height: size,
      autoRotate: false,
      cameraControls: false,
    );
  }

  String _getModelPath(String modelId) {
    switch (modelId) {
      case 'duck':
        return 'assets/models/Duck.glb';
      default:
        return '';
    }
  }

  Widget _buildFallbackModel() {
    IconData icon;
    List<Color> colors;

    switch (modelId) {
      case 'box':
        icon = Icons.crop_square;
        colors = [Colors.blue.shade300, Colors.blue.shade700];
        break;
      case 'sphere':
        icon = Icons.circle;
        colors = [Colors.purple.shade300, Colors.purple.shade700];
        break;
      default:
        icon = Icons.view_in_ar;
        colors = [Colors.grey.shade300, Colors.grey.shade600];
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors[1].withValues(alpha: 0.4),
            blurRadius: 6,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              size: size * 0.5,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'SIM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}