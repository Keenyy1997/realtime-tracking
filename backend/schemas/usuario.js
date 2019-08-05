const mongoose = require('mongoose')

var Schema = mongoose.Schema;

var usuarioSchema = new Schema({
    user: String,
    lat: Number,
    lng: Number,
    date: {
        type: Date,
        default: Date.now
    }
})

module.exports = usuarioSchema;