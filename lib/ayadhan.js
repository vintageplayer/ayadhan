var express = require('express')

var app = express()

app.use(express.static('./public'))

app.set('view engine', 'jade')
app.set('views', './views')

app.route('/')
.get(function(req, res) {
	res.render('layout')
})

var srv = app.listen(80, function() {
	console.log('Listening on '+80)
})

app.use('/peerjs', require('peer').ExpressPeerServer(srv, {
	debug: false
}))
