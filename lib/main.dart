import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ar_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _cameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  // Función para solicitar permiso de cámara
  Future<void> _requestCameraPermission() async {
    print('Solicitando permiso de cámara...');

    final status = await Permission.camera.request();

    setState(() {
      _cameraPermissionGranted = status == PermissionStatus.granted;
    });

    if (_cameraPermissionGranted) {
      print('Permiso de cámara concedido');
    } else {
      print('Permiso de cámara denegado');
      _showPermissionDialog();
    }
  }

  // Mostrar diálogo si se deniega el permiso
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permiso Requerido'),
          content: Text('Esta aplicación necesita acceso a la cámara para funcionar correctamente.'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Configuración'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Flutter App'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 100,
              color: _cameraPermissionGranted ? Colors.green : Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              _cameraPermissionGranted
                  ? 'Permiso de cámara concedido'
                  : 'Permiso de cámara requerido',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _cameraPermissionGranted
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ARScreen()),
                );
              }
                  : _requestCameraPermission,
              child: Text(_cameraPermissionGranted ? 'Abrir AR' : 'Solicitar Permiso'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: _cameraPermissionGranted ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}