import 'package:flutter/material.dart';
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
    _simulatePermissionRequest();
  }

  // Simular solicitud de permiso de cámara
  Future<void> _simulatePermissionRequest() async {
    print('Simulando solicitud de permiso de cámara...');

    // Simular delay de solicitud de permiso
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _cameraPermissionGranted = true;
    });

    print('Permiso de cámara simulado como concedido');
  }

  // Mostrar diálogo informativo sobre permisos
  void _showPermissionInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Información de Permisos'),
          content: Text('En una aplicación real, aquí se solicitarían los permisos de cámara necesarios para AR. Por ahora están simulados.'),
          actions: [
            TextButton(
              child: Text('Entendido'),
              onPressed: () {
                Navigator.of(context).pop();
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
                  ? 'Permiso de cámara concedido (simulado)'
                  : 'Verificando permisos...',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
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
                  : null,
              child: Text(_cameraPermissionGranted ? 'Abrir AR' : 'Cargando...'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: _cameraPermissionGranted ? Colors.green : Colors.grey,
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: _showPermissionInfo,
              child: Text('Información sobre permisos'),
            ),
          ],
        ),
      ),
    );
  }
}