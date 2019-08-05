import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:latlong/latlong.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';


class SocketStatus extends StatelessWidget {
  String status;

  SocketStatus({ @required this.status });

  /* *********** 
    ESTADOS DEL SOCKET
    1) disconnect = Esta full desconectado del socket
    2) connect = Esta conectado al socket
    3) reconnect = Se ha reconectado al socket
    4) reconnecting = Esta intentando reconectarse al socket
    5) reconnect_attempt = Esta intentando hacer un intento de reconectarse 
  
   *********** */

  Widget renderStatus () {

    if (status == "disconnect") {
      return Text("You are disconnected 😢", style: TextStyle(fontSize: 15, color: Colors.redAccent));
    }
    else if (status == "connect") {
      return Text("You are Connected 👍", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,color: Colors.green));
    }
    else if (status == "reconnect") {
      return Text("You are Reconnected!", style: TextStyle(fontSize: 15, color: Colors.green));
    }
    else if (status == "reconnecting") {
      return Text("Reconnecting...", style: TextStyle(fontSize: 20, color: Colors.grey));
    }
    else if (status == "reconnect_attempt") {
      return Text("Trying again in reconnect...", style: TextStyle(fontSize: 15, color: Colors.grey));
    }

    return Text("Waiting for status...");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: renderStatus(),
    );
  }
}

class Mapa extends StatefulWidget {

  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  Map<String, double> userLocation;
  Location location;
  StreamSubscription listener;
  // ~~~~~~~~~~~~~ GPS

  String _usuario;
  List _usuarios = new List();
  // ~~~~~~~~~~~~~ USUARIO

  String _mapToken = "pk.eyJ1Ijoia2Vlbnl5MTk5NyIsImEiOiJjanRjMTEzZGIwcnB6NDlwNGk4cjNmd2FpIn0.RqO1x67kmupEDbltZcqPJw";
  List<Marker> _markers = new List();
  double initLatitude = 0;
  double initLongitude = 0;
  MapController mapController = new MapController();
  bool showSnackbar = false;
  String showText = "";
  // ~~~~~~~~~~~~~ MAPA



  String _socketStatus;
  SocketIO socketIO = null;
  String socketURI = "http://eastcoastresources.com:3000";
  // "http://192.168.1.6:8080";
  //  //";
  String socketNamespace = "/";

  // ~~~~~~~~~~~~~ SOCKET


  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // ~~~~~~~~~~~~~ GLOBAL

  checkGPSPermission() async {

      listener = location.onLocationChanged().listen(updateLocation);
      // LISTENING

      updateLocation(await location.getLocation());
      // print(userLocation);
  }

  updateLocation(Map<String, double> data){
    // print(data);
    userLocation = data;
    actualizarUltimaLocation(data);
  }

  actualizarUltimaLocation(Map<String, double> data) async{
    var prefs = await SharedPreferences.getInstance();

    prefs.setDouble('last_lat', data["latitude"]);
    prefs.setDouble('last_lng', data["longitude"]);
    var message = {
        "user": prefs.getString("user"),
        "lat" : prefs.getDouble("last_lat"),
        "lng" : prefs.getDouble("last_lng")
      };

    socketIO.sendMessage("new_location", json.encode(message));
    agregarUsuario(message["user"], message["lat"], message["lng"]);
  }

  agregarUsuario(String user, double lat, double lng) {
      var usuarioItem;

      for(var i = 0;i < _usuarios.length;i++) {
        if (_usuarios[i]["user"] == user) {
          usuarioItem = _usuarios[i];
          break;
        }
      }
  
      final marker = Marker(
          width:30.0,
          height: 30.0,
          point: LatLng(lat, lng),
          builder: (ctx) => Container(
            child: GestureDetector(
              child: Image.asset('images/marker-icon.png'),
              onTap: () {
                _mostrarSnackbar(user, 1);
              },
            )
          )
        );

      if (usuarioItem == null) {
        print("USUARIO CREADO!!");

        _usuarios.add({
          "user": user,
          "lat": lat,
          "lng": lng,
          "marker": marker
        });
        _deleteMarker(marker);
        // EN CASO DE QUE EXISTA
        _insertMarker(marker);
      } // EN CASO DE QUE NO EXISTA
      else {
        // EN CASO DE QUE EL USUARIO EXISTA
        // PROCEDEMOS A ACTUALIZAR SUS LAT LNG Y EL MARKER
        print("ACTUALIZADNO USUARIO!");

        var index = _usuarios.indexOf(usuarioItem);

        _usuarios[index]["lat"] = lat;
        _usuarios[index]["lng"] = lng;
       
        
        _deleteMarker(_usuarios[index]["marker"]);
        // ELIMINAMOS EL ANTIGUO MARCADOR
        _usuarios[index]["marker"] = marker;
        // ACTUALIZAMOS AL MARCADOR ACTUAL
        _insertMarker(marker);
        // AGREGAMOS EL MARCADOR ACTUAL
        setState(() {});
        // ACTUALIZAMOS EL ESTADO PARA QUE SE HAGA EFECTIVO
      }
  }

  eliminarUsuario(String user) {
    var result;

    for(var i = 0;i < _usuarios.length;i++) {
      if (_usuarios[i]["user"] == user) {
        _markers.remove(_usuarios[i]["marker"]);
        _usuarios.remove(_usuarios[i]);
        break;
      }
    }

    setState(() {});
  }

  _deleteMarker(Marker marker) {
    var result;
    for(var i = 0;i < _markers.length;i++) {
      if (_markers[i] == marker) {
        result = _markers[i];
        break;
      }
    }

    if (result != null) {
      _markers.remove(result);
      setState(() {});
    }
  }

  _insertMarker(marker) {
    var result;

    for(var i = 0;i < _markers.length;i++) {
      if (_markers[i] == marker) {
        result = _markers[i];
        break;
      }
    }

    if (result == null) {
      _markers.add(marker);
      setState(() {});
    }
  }

  _cambiarUsuario(BuildContext context) async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('user', '');
    disconnectSocket();
    listener.cancel();
    Navigator.popAndPushNamed(context, '/');
    // dispose();
  }

  _obtenerUsuario() async {
    var prefs = await SharedPreferences.getInstance();
    _usuario = prefs.getString('user');
    initLatitude = prefs.getDouble('last_lat');
    initLongitude = prefs.getDouble('last_lng');
    setState(() {
    }); 

    agregarUsuario(_usuario, initLatitude, initLongitude);
    mapController.move(LatLng(initLatitude, initLongitude), 15);
  }

  _mostrarSnackbar(texto, seconds) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(texto),
        duration: Duration(seconds: seconds),
      )
    );
  }
  // COMENZAR CON SOCKETS

  initSocket() async {
    var prefs = await SharedPreferences.getInstance();
    var usuario = prefs.getString('user') ?? "";

    print("ENTRANDO AL SOCKET CON EL USER: $usuario");

    SocketIOManager().destroyAllSocket();
    // DESTROY EVERY SOCKET

    socketIO = SocketIOManager().createSocketIO(socketURI, socketNamespace, query: "user=$usuario&lat=$initLatitude&lng=$initLongitude", socketStatusCallback: socketStatus);
    socketIO.init();


    socketIO.subscribe("socket_status", (dynamic data) {
      print("STATUS: $data");
    });

    socketIO.subscribe("old_connections", viejasConnections);
    socketIO.subscribe("new_connection", nuevaConnection);
    socketIO.subscribe("new_disconnect", nuevaDisconnection);
    socketIO.subscribe("new_location", nuevaLocation);

    socketIO.connect();
  }

  nuevaLocation(dynamic data) {
    print("Nuevo movimiento");
    print(data);
    var tmp = json.decode(data);
    agregarUsuario(tmp["user"], tmp["lat"], tmp["lng"]);
  }

  nuevaDisconnection(dynamic data) {
    print("Nueva desconexion.");
    print(data);
    var tmp = json.decode(data);
    eliminarUsuario(tmp["user"]);
  }

  nuevaConnection(dynamic data) {
    print("Nueva conexion!");
    print(data);
    var tmp = json.decode(data);
    agregarUsuario(tmp["user"], tmp["lat"], tmp["lng"]);
  }

  viejasConnections(dynamic data) {
    print("Viejas conexiones");
    print(data);

    var tmp = json.decode(data);
    print(tmp);
    
    for(var i = 0;i < tmp.length;i++) {
        print("#$i");
        print(tmp[i]);
        agregarUsuario(tmp[i]["user"], tmp[i]["lat"], tmp[i]["lng"]);
    }
  }


  socketStatus(dynamic data) {
    _socketStatus = data;
    setState(() { });
    print("Status: $data");
  }

  ReconnectSocket() async {
    print("Intenado reconectar...");
    var prefs = await SharedPreferences.getInstance();
      var usuario = prefs.getString('user') ?? "";

      Timer(Duration(seconds: 1), () {
        if (socketIO == null) {
          socketIO = SocketIOManager().createSocketIO(socketURI, socketNamespace, query: "user=$usuario&lat=$initLatitude&lng=$initLongitude", socketStatusCallback: socketStatus);
          socketIO.init();
          socketIO.connect();
        } else {
          socketIO.connect();
        }
      });
  }

  disconnectSocket() {
    try {
      if (socketIO != null)
        socketIO.destroy();
    } catch(e) {
      print("ERROR DISCONNECTING SOCKET: $e");
    }
  }

  @override
  void dispose() {  
    print("DISPOSING...");
    disconnectSocket();
    listener.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (listener != null) 
      listener.cancel();

    _obtenerUsuario();
    // PRIMERO OBTENEMOS EL USUARIO Y YA LUEGO PROSEGUIMOS.

    location = new Location();
    // ASIGNAMOS EN QUE LOCATION SERA UNA CLASE DE TIPO LOCATION(SE ENCARGA DE LAS MOVIDAS DEL GPS)

    checkGPSPermission();
    // CHEQUEAMOS LOS PERMISOS
    if (socketIO == null)
      initSocket();
    else 
      socketIO.connect();

    // getFirstLocation();
    // CONSEGUIMOS LA PRIMERA LOCATION
  }

  _mostrarUsuarios(BuildContext context) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Usuarios Conectados'),
          content: _usuarios.length > 0 ?
            Container(
              width: 300.0,
              height:300.0,
              child: ListView.builder(
                      itemCount: _usuarios.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Container(
                          child: RaisedButton(
                            child: Text(_usuarios[index]["user"], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            onPressed: () {
                              print(_usuarios[index]["user"]);
                              mapController.move(LatLng(_usuarios[index]["lat"], _usuarios[index]["lng"]), 15);
                            },
                            color: Colors.blueAccent
                          ),
                          margin: EdgeInsets.only(bottom: 1),
                        );
                      },
                    )
            )
            :
            Container(
              child: Text("No hay usuarios conectados 😢"),
              margin: EdgeInsets.only(top:20),
            )
        );
      }
    );
    
  }

  @override
  Widget build(BuildContext context) {

    Size width = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Mapa con socket'),
        leading: IconButton(
          icon: Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            _cambiarUsuario(context);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.people, color: Colors.white),
            onPressed: () {
              _mostrarUsuarios(context);
            },
          )
        ],
      ),
      body: Container(
        child: Stack(
          children: <Widget>[
            Container(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: LatLng(10.9700342, -74.7843947),
                  zoom: 15.0,
                  maxZoom: 20.0,
                  minZoom: 12.0
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate: "https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}@2x.png?access_token=$_mapToken",
                    additionalOptions: {
                      'accessToken': "$_mapToken",
                      'id' : 'mapbox.streets',
                    }
                  ),
                  MarkerLayerOptions(
                    markers: _markers.toList()
                  )
                ]
              ),
              width: double.maxFinite,
              height: width.height,
            ),
            Positioned(
              bottom:10,
              left: 0,
              child: Container(
                color: Colors.white70,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Text("$_usuario", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SocketStatus(status: _socketStatus),
                      _socketStatus == null ? FlatButton(child: Text("Click to reconnect"), onPressed: () {
                        ReconnectSocket();
                      }) : Container()
                    ],
                  ),
                ),
                margin: EdgeInsets.only(top:10),
                width: width.width,
              ),
            )
          ],
        )
      ),
    );
  }
}