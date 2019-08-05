const express = require('express')
const http = require('http').createServer(express)
const io = require('socket.io')(http)
const app = express()

const config = require('./config')
// ARCHIVO DE CONFIGURACION DE MONGODB

const mongoose = require('mongoose')
const usuarioSchema = require('./schemas/usuario')

const mongo = `mongodb://${config.host}:${config.port}/${config.db}`
console.log(`Connecting MONGODB to: ${mongo} 👀`)

mongoose.connect(mongo, { useNewUrlParser: true })
mongoose.Promise = global.Promise;

const db = mongoose.connection;

const usuarioModel = db.model('Usuario', usuarioSchema)

db.on('error', (error) => {
    console.log(`Error connecting mongo 😢`)
    console.log(error)
})
console.log(`Connected to MONGODB ✔🔥`)

const PORT = 8080;


var Users = new Array();

io.on('connection', (socket) => {

    console.log(socket);
    console.log('New user connected to our socket 🔥!')
    var Query = socket.handshake.query;

    Users.push({
        user: Query.user,
        conn: socket,
        lat: Query.lat,
        lng: Query.lng
    })
    // AGREGANDO A LA LISTA DE USERS EL USUARIO NUEVO
    console.log(`Welcome: ${Query.user} 😉`)
    console.log(`We already have ${Users.length} users connected!`)

    socket.emit('old_connections', Users.map(item => {
        return {
            user: item.user,
            lat: parseFloat(item.lat),
            lng: parseFloat(item.lng)
        }
    }))
    // OLD CONNECTIONS

    socket.broadcast.emit('new_connection', {
        user: Query.user,
        lat: parseFloat(Query.lat),
        lng: parseFloat(Query.lng)
    })
    // NEW CONNECTION SEND BACK The PARAMS

    socket.on('disconnect', function() {
        var User = Users.find(x => x.conn == socket)
        var Index = Users.indexOf(User);
        Users.splice(Index, 1);
        console.log(`Good bye: ${User.user} 😢`)

        io.emit('new_disconnect', {
            user: User.user
        })
    })
    // ~~~~~ CASO DE DESCONEXION

    socket.on('new_location', (data) => {
        console.log(`New Location:`, data);

        for(let i = 0;i < Users.length;i++) {
            if (Users[i]["user"] == data.user) {
                Users[i]["lat"] = data.lat;
                Users[i]["lng"] = data.lng;
                break;
            }
        }

        var newUsuario = new usuarioModel({
            user: data.user,
            lat: parseFloat(data.lat),
            lng: parseFloat(data.lng)
        })

        newUsuario.save((err) => {
            if(err) console.error(`We have an error: ${err.message}`)

            console.log(`SAVED IN MONGO 🔥🔥🔥🔥🔥🔥`)
        })
        // GUARDAMOS EL REGISTRO EN MONGODB

        io.emit('new_location', data);
    })
    // NEW LOCATION -> ADD / UPDATE
})

console.log(`SOCKET READY 🔥`)

http.listen(PORT, () => {
    console.log(`SERVER READY ON ${PORT} 🔥🔥🔥`)
})