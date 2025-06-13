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
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Solicitar permiso de cámara
    var status = await Permission.camera.status;

    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    setState(() {
      _cameraPermissionGranted = status.isGranted;
      _isCheckingPermission = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Flutter App'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: _isCheckingPermission
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_in_ar,
              size: 100,
              color: _cameraPermissionGranted ? Colors.blue : Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              _cameraPermissionGranted
                  ? '¡Permiso de cámara concedido!'
                  : 'Permiso de cámara denegado',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _cameraPermissionGranted
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ARScreen()),
                );
              }
                  : _checkPermissions,
              icon: Icon(_cameraPermissionGranted ? Icons.camera : Icons.refresh),
              label: Text(_cameraPermissionGranted ? 'Abrir AR' : 'Solicitar permisos'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: _cameraPermissionGranted ? Colors.blue : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}