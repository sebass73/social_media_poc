import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uni_links/uni_links.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Login Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SocialLoginPage(),
    );
  }
}

class SocialLoginPage extends StatefulWidget {
  @override
  _SocialLoginPageState createState() => _SocialLoginPageState();
}

class _SocialLoginPageState extends State<SocialLoginPage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? _token;
  String? _displayName;
  String? _message;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  // Escuchar enlaces entrantes (deep links)
  void _initDeepLinkListener() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      linkStream.listen((String? link) {
        if (link != null) {
          _handleDeepLink(link);
        }
      });
    } catch (e) {
      print('Error obteniendo el enlace: $e');
    }
  }

  // Manejar el deep link
  void _handleDeepLink(String link) async {
    final Uri uri = Uri.parse(link);

    // Verifica que sea el callback correcto
    if (uri.scheme == 'com.mypoc' && uri.host == 'callback') {
      final String? token =
          uri.queryParameters['token']; // Extraer el token de la URL

      final String? displayName =
          uri.queryParameters['displayName']; // Extraer el displayName
      final String? email = uri.queryParameters['email']; // Extraer el email

      if (token != null) {
        await _secureStorage.write(key: 'jwt_token', value: token);
        setState(() {
          _token = token;
          _displayName = displayName;
        });
        print('Token recibido: $token');
        print('Nombre de usuario: $displayName');
      }
    }
  }

  Future<void> loginGoogle() async {
    try {
      // Abre el navegador para que el usuario inicie sesión
      final result = await FlutterWebAuth.authenticate(
        url:
            "https://2188-2800-2202-4000-272-596a-b1b8-ee1d-815d.ngrok-free.app/auth/google", // URL del backend que redirige a Google
        callbackUrlScheme: "com.mypoc", // Tu esquema de URL personalizado
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  // Logout
  Future<void> _logout() async {
    // Hacer una solicitud al backend para cerrar la sesión
    final response = await http.get(
      Uri.parse(
          'https://2188-2800-2202-4000-272-596a-b1b8-ee1d-815d.ngrok-free.app/logout'),
    );

    if (response.statusCode == 200) {
      // Si la sesión fue cerrada correctamente, borrar el token almacenado
      await _secureStorage.delete(key: 'jwt_token');

      setState(() {
        _token = null;
        _displayName = null;
        _message = "Sesión cerrada exitosamente.";
      });
    } else {
      setState(() {
        _message = "Error al cerrar la sesión.";
      });
    }
  }

  Future<void> accessDashboard() async {
    // Recuperar el token almacenado
    String? token = await _secureStorage.read(key: 'jwt_token');

    if (token == null) {
      setState(() {
        _message = "No estás autenticado. Por favor, inicia sesión.";
      });
      return;
    }

    try {
      // Realizar una solicitud GET a /dashboard con el token en el encabezado
      final response = await http.get(
        Uri.parse(
            'https://2188-2800-2202-4000-272-596a-b1b8-ee1d-815d.ngrok-free.app/dashboard'),
        headers: {
          'Authorization': 'Bearer $token', // Enviar el token en el encabezado
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _message = data['message']; // Mostrar el mensaje del backend
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _message = "No estás autenticado o tu sesión ha expirado.";
        });
      } else {
        setState(() {
          _message = "Error al acceder al dashboard.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error al conectar con el servidor.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login con Redes Sociales'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_displayName != null) Text('Bienvenido, $_displayName'),
            if (_token == null) ...[
              ElevatedButton.icon(
                icon: Icon(Icons.login),
                label: Text('Login con Google'),
                onPressed: () {
                  loginGoogle();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Botón de google
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.facebook),
                label: Text('Login con Facebook'),
                onPressed: () {
                  // Aquí irá el código para login con Facebook
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Botón de facebook
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                onPressed: () {
                  _logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen, // Botón de logout
                ),
              ),
            ],
            ElevatedButton(
              onPressed: accessDashboard,
              child: Text('Acceder al Dashboard'),
            ),
            SizedBox(height: 20),
            if (_message != null) Text(_message!), // Mostrar el mensaje
          ],
        ),
      ),
    );
  }
}
