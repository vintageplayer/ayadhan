var board = null;
var game = new Chess();
var $status = $('#status')
var $fen = $('#fen')
var $pgn = $('#pgn')
var whiteSquareGrey = '#a9a9a9';
var blackSquareGrey = '#696969';
var orientation = 'white';
var onMoveCallback = null;
var gameId;
var squareClass = 'square-55d63';
var $board = $('#myBoard');
var drawRequested = false;
var gameOver = false;

function removeGreySquares () {
  $('#myBoard .square-55d63').css('background', '')
}

function greySquare (square) {
  var $square = $('#myBoard .square-' + square)

  var background = whiteSquareGrey
  if ($square.hasClass('black-3c85d')) {
    background = blackSquareGrey
  }

  $square.css('background', background)
}

function removeHighlights (color) {
  $board.find('.' + squareClass)
    .removeClass('highlight-' + color);
}

function onDragStart (source, piece, position, orientation) {
  // do not pick up pieces if the game is over
  if (game.game_over() || gameOver) return false;

  // only pick up pieces for White
  if ((game.turn() === 'w' && piece.search(/^b/) !== -1) || (game.turn() === 'b' && piece.search(/^w/) !== -1)) {
  	return false
  }

  if (game.turn() !== orientation[0]) {
    return false
  }
}

function endBet(resultCode) {
	betInstance.methods.updateWinner(gameId, resultCode).send({from: account}).then( () => {
		alert('Transferred Winnings');
	});
}

function onDrop (source, target) {
  // see if the move is legal
  var move = game.move({
    from: source,
    to: target,
    promotion: 'q' // NOTE: always promote to a queen for example simplicity
  });

  // illegal move
  if (move === null) return 'snapback';

  updateStatus();

  if (move.color === 'w') {
  	removeHighlights('white');

    $board.find('.square-' + source).addClass('highlight-white')
    $board.find('.square-' + target).removeClass('highlight-black').addClass('highlight-white')
  } else {
  	removeHighlights('black');
    $board.find('.square-' + source).addClass('highlight-black')
    $board.find('.square-' + target).removeClass('highlight-white').addClass('highlight-black')
  }
  
  // make random legal move for black
  if (game.turn() !== orientation[0]) {
  	onMoveCallback(['move', source, target]);
	  if (game.in_checkmate()) {
	    if (orientation[0]=='w')
	    	endBet(2);
	    else
	    	endBet(1);
	  }
	  // draw?
	  else if (game.in_draw()) {
	    endBet(0);
	  }
  } else {
  	board.position(game.fen());
  }
}

function onMouseoverSquare (square, piece) {
  if (game.turn() !== orientation[0] || gameOver) {
    return false
  }

  // get list of possible moves for this square
  var moves = game.moves({
    square: square,
    verbose: true
  })

  // exit if there are no moves available for this square
  if (moves.length === 0) return

  // highlight the square they moused over
  greySquare(square)

  // highlight the possible squares for this piece
  for (var i = 0; i < moves.length; i++) {
    greySquare(moves[i].to)
  }
}

function onMouseoutSquare (square, piece) {
	removeGreySquares()
}

// update the board position after the piece snap
// for castling, en passant, pawn promotion
function onSnapEnd () {
  board.position(game.fen());
}

function setStatusMessage(status) {
  $status.html(status);
  $fen.html(game.fen());
  $pgn.html(game.pgn().replace(/ ([0-9]+[.])/g, '<br/>$1'));
}

function updateStatus() {
  var status = ''

  var moveColor = 'White'
  if (game.turn() === 'b') {
    moveColor = 'Black'
  }

  // checkmate?
  if (game.in_checkmate()) {
    status = 'Game over, ' + moveColor + ' is in checkmate.'
  }

  // draw?
  else if (game.in_draw()) {
    status = 'Game over, drawn position'
  }

  // game still on
  else {
    status = moveColor + ' to move'

    // check?
    if (game.in_check()) {
      status += ', ' + moveColor + ' is in check'
    }
  }

  setStatusMessage(status);
}

function createChessBoard() {
	var config = {
	  draggable: true,
	  pieceTheme: '/assets/img/chesspieces/basic/{piece}.png',
	  position: 'start',
	  orientation: orientation,
	  onDragStart: onDragStart,
	  onDrop: onDrop,
	  onMouseoutSquare: onMouseoutSquare,
	  onMouseoverSquare: onMouseoverSquare,
	  onSnapEnd: onSnapEnd,
	  showNotaion: true,
	};
	board = Chessboard('myBoard', config);
	updateStatus();
};

(function() {
	var peer = null;
	var peerId = null;
	var conn = null;
	var opponent = {
		peerId: null
	};
	var turn = false;
	var ended = false;

	function requestDraw() {
		drawRequested = true;
		sendData(['DrawRequest']);
	}

	function resign() {
		gameOver = true;
		sendData(['OpponentResigned']);
		setStatusMessage("Game Over! You resigned.");
	}

	function opponentResigned() {
		gameOver = true;
		alert('Opponent Resigned');
		if (orientation[0]=='w')
			endBet(2);
		else
			endBet(1);
		setStatusMessage("Game Over! Opponent resigned.");
	}

	function begin() {
		conn.on('data', function(data) {
			if(data[0] === 'move'){
				onDrop(data[0], data[1]);
			} else if (data[0] === 'OpponentResigned') {
				opponentResigned();
			} else if (data[0] === 'DrawRequest') {
				if (confirm('Opponent Request for Draw. Do you accept?')) {
					gameOver = true;
					sendData(['DrawAccepted']);
					setStatusMessage("Players Agreed for a Draw!");
				} else {
					sendData(['DrawRejected']);
				}
			} else if (data[0] === 'DrawAccepted' && drawRequested) {
				gameOver = true;
				alert('Draw Request Accepted!');
				setStatusMessage("Players Agreed for a Draw!");
				endBet(0);
			} else if (data[0] === 'DrawRejected' && drawRequested) {
				drawRequested = false;
				alert('Draw Request Declined!');
			}
		});

		conn.on('close', function() {
			if(!ended) {
				$('#game .alert p').text('Opponent forfeited!')
			}
			turn = false
		})
		peer.on('error', function(err) {
			alert(''+err)
			turn = false
		})
	}

	function sendData(data) {
		conn.send(data)
	}

	function initialize() {
		console.log('Creating peer connection');
		peer = new Peer('', {
			host: location.hostname,
			port: location.port || (location.protocol === 'https:' ? 443 : 80),
			path: '/peerjs',
			debug: 3
		})
		peer.on('open', function(id) {
			peerId = id
		})
		peer.on('error', function(err) {
			alert(''+err)
		})

		// Heroku HTTP routing timeout rule (https://devcenter.heroku.com/articles/websockets#timeouts) workaround
		function ping() {
			console.log(peer)
			peer.socket.send({
				type: 'ping'
			})
			setTimeout(ping, 16000)
		}
		ping()
		onMoveCallback = sendData;
	}

	function start() {
		betAmount = parseInt(document.getElementById("betAmount").value);
		if (betAmount <= 0){
			alert('Invalid Bet betAmount');
			return;
		}
		initialize();
		peer.on('open', function() {
			betAmount = parseInt(document.getElementById("betAmount").value);
			betInstance.methods.createGame(1639722618).send({from: account, value: betAmount}).then( (receipt) => {
				// console.log(receipt);
				gameId = receipt.events.GameCreated.returnValues.gameId;
				var inviteCode = gameId+'_' +peerId;
				$('#game .alert p').text('Waiting for opponent').append($('<span class="pull-right"></span>').text('Peer ID: '+inviteCode));
				$('#game').show().siblings('section').hide();
				orientation = 'black';
				createChessBoard();
			});
			// alert('Ask your friend to join using your peer ID: '+inviteCode);
		});
		peer.on('connection', function(c) {
			if(conn) {
				c.close();
				return;
			}
			conn = c;
			turn = true;
			$('#game .alert p').text('Your move!');
			begin()
		})
	}

	function join() {
		initialize();
		peer.on('open', function() {
			var inviteCode = prompt("Enter invite code:");
			gameId = inviteCode.split('_')[0];
			var destId = inviteCode.split('_').slice(1).join('_');
			betInstance.methods.getGameDetails(gameId).call().then( (gameDetails) => {
				betAmount = parseInt(gameDetails.amount);
				betInstance.methods.acceptGame(gameId).send({from: account, value: betAmount}).then( (receipt) => {
					conn = peer.connect(destId, {
						reliable: true
					});
					conn.on('open', function() {
						opponent.peerId = destId;
						$('#game .alert p').text("Waiting for opponent's move");
						$('#game').show().siblings('section').hide();
						orientation = 'white';
						createChessBoard();
						turn = false;
						begin();
					});
				});
			});
		});
	}

	$('a[href="#start"]').on('click', function (event) {
		console.log('Starting Game!');
		event.preventDefault();
		start();
	});

	$('a[href="#join"]').on('click', function (event)  {
		event.preventDefault()
		join();
	});

	$('a[href="#resign"]').on('click', function (event) {
		console.log('Resigning Game!');
		event.preventDefault();
		resign();
	});

	$('a[href="#draw"]').on('click', function (event)  {
		console.log('Requesting for draw');
		event.preventDefault();
		requestDraw();
	});	
})();
