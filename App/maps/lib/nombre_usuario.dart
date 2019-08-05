import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class NombreUsuario extends StatefulWidget {
  @override
  _NombreUsuarioState createState() => _NombreUsuarioState();
}

class _NombreUsuarioState extends State<NombreUsuario> {

  TextEditingController nombreUsuario = TextEditingController();


  void verificarUsuario(BuildContext context, String value) async {

    print("Verificando Usuario!");

    if (value.isNotEmpty) {

      print(value);
      var prefs = await SharedPreferences.getInstance();

      prefs.setString('user', value);
      Navigator.pushReplacementNamed(context, '/map');
    } else {

      print("Entrando en el dialog!");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Usuario requerido'),
            content: Text("Debes de introducir un nombre de usuario para entrar al mapa."),
            actions: <Widget>[
              FlatButton(
                child: Text("Aceptar"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
      );
    }
  }

  @override
  void initState() {
    super.initState();

    checkUser();
  }

  void checkUser() async {
    var prefs = await SharedPreferences.getInstance();
    var usuario = prefs.getString('user');

    if (usuario.isNotEmpty) {
      Navigator.pushNamed(context, '/map');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Escribe tu nombre de usuario"),
        automaticallyImplyLeading: false
      ),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Tu nombre de usuario",
                    contentPadding: EdgeInsets.only(bottom: 5)
                  ),
                  style: TextStyle(fontSize: 30.0),
                  controller:nombreUsuario,
                ),
                width: 300,
                margin: EdgeInsets.only(bottom: 20),
              ),
              Container(
                child: RaisedButton(
                        color: Colors.blue,
                        textColor: Colors.white,
                        child: Text("ASIGNAR"),
                        onPressed: () {
                          print("Boton presionado!");
                          verificarUsuario(context, nombreUsuario.text);
                        },
                      ),
                width: 300,
              )
            ],
          ),
        ),
      ),
    );
  }
}