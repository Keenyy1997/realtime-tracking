import 'package:flutter/material.dart';
import 'nombre_usuario.dart'; //NOMBREUSUARIO
import 'map.dart'; //MAPA

void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workana Map App',
      initialRoute: '/',
      routes: {
        '/' : (context) => NombreUsuario(),
        '/map' : (context) => Mapa()
      },
    );
  }
}