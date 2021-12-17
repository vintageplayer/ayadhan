var express = require('express')
var Chess = require('chess.js');

var app = express();

app.use(express.static('./public'));

app.set('view engine', 'jade');
app.set('views', './views');

app.route('/')
.get(function(req, res) {
	res.render('layout');
});

function hex2a(hexx) {
    var hex = hexx.toString();//force conversion
    var str = '';
    for (var i = 0; i < hex.length; i += 2)
        str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
    return str;
}

/*
	Codes:
	1 - Previous FEN Not Valid
	2 - Current FEN Not Valid
	3 - Current FEN not possible from Previous
	4 - Both FENs are same, game not over
	5 - Both FENs are same, It's a draw
	6 - Both FENs are same, White Won
	7 - Both FENs are same, Black Won
	8 - FENs different, game not over
	9 - FENs different, it's a draw
	10 - FENs different, White Won
	11 - FENs different, Black Won
*/

app.get('/validate/:prevFenHex/:curFenHex', function(req, res) {
	prevFenString = hex2a(req.params.prevFenHex);
	curFenString = hex2a(req.params.curFenHex);
	comparisonCode = 0;
	game = new Chess.Chess();
	if (!game.validate_fen(prevFenString).valid === true){
		comparisonCode = 1
	} else if (!game.validate_fen(curFenString).valid === true){
		comparisonCode = 2;
	} else {
		game.load(prevFenString)
		if (prevFenString == curFenString) {
			comparisonCode = 4;
			if (game.in_draw()) {
				comparisonCode = 5;
			} else if (game.in_checkmate()) {
				comparisonCode = 6;
				if (game.turn === 'w') {
					comparisonCode = 7;
				}
			}
		} else {
			comparisonCode = 3;
			possibleMoves = game.moves();			
			for (let i=0; i<possibleMoves.length; i++) {
				game.move(possibleMoves[i]);
				if (game.fen() == curFenString) {
					comparisonCode = 8;
					if (game.in_draw()) {
						comparisonCode = 9;
					} else if (game.in_checkmate()) {
						comparisonCode = 10;
						if (game.turn === 'w') {
							comparisonCode = 11;
						}
					}
					break;
				}
				game.undo();
			}

		}
	}
	res.send({'comparisonCode': comparisonCode});
});

var srv = app.listen(process.env.PORT, function() {
	console.log('Listening on '+process.env.PORT)
});

app.use('/peerjs', require('peer').ExpressPeerServer(srv, {
	debug: false
}));