var BetContract = {
	"contractName": "Bet",
	"abi": [
			{
				"inputs": [],
				"stateMutability": "nonpayable",
				"type": "constructor"
			},
			{
				"anonymous": false,
				"inputs": [
					{
						"indexed": false,
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					},
					{
						"indexed": false,
						"internalType": "address",
						"name": "acceptor",
						"type": "address"
					},
					{
						"indexed": false,
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					}
				],
				"name": "GameAccepted",
				"type": "event"
			},
			{
				"anonymous": false,
				"inputs": [
					{
						"indexed": false,
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					},
					{
						"indexed": false,
						"internalType": "address",
						"name": "creator",
						"type": "address"
					},
					{
						"indexed": false,
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					}
				],
				"name": "GameCancelled",
				"type": "event"
			},
			{
				"anonymous": false,
				"inputs": [
					{
						"indexed": false,
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					},
					{
						"indexed": false,
						"internalType": "address",
						"name": "creator",
						"type": "address"
					},
					{
						"indexed": false,
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					}
				],
				"name": "GameCreated",
				"type": "event"
			},
			{
				"anonymous": false,
				"inputs": [
					{
						"indexed": false,
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					},
					{
						"indexed": false,
						"internalType": "address",
						"name": "player1",
						"type": "address"
					},
					{
						"indexed": false,
						"internalType": "address",
						"name": "player2",
						"type": "address"
					},
					{
						"indexed": false,
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					}
				],
				"name": "GameDraw",
				"type": "event"
			},
			{
				"anonymous": false,
				"inputs": [
					{
						"indexed": false,
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					},
					{
						"indexed": false,
						"internalType": "address",
						"name": "winner",
						"type": "address"
					},
					{
						"indexed": false,
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					}
				],
				"name": "GameFinished",
				"type": "event"
			},
			{
				"inputs": [
					{
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					}
				],
				"name": "acceptGame",
				"outputs": [],
				"stateMutability": "payable",
				"type": "function"
			},
			{
				"inputs": [
					{
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					}
				],
				"name": "cancelGame",
				"outputs": [],
				"stateMutability": "payable",
				"type": "function"
			},
			{
				"inputs": [
					{
						"internalType": "uint256",
						"name": "_acceptDeadline",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "_isSigned",
						"type": "bool"
					}
				],
				"name": "createGame",
				"outputs": [
					{
						"internalType": "uint256",
						"name": "",
						"type": "uint256"
					}
				],
				"stateMutability": "payable",
				"type": "function"
			},
			{
				"inputs": [
					{
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					}
				],
				"name": "getGameDetails",
				"outputs": [
					{
						"components": [
							{
								"internalType": "address",
								"name": "player1",
								"type": "address"
							},
							{
								"internalType": "address",
								"name": "player2",
								"type": "address"
							},
							{
								"internalType": "uint256",
								"name": "amount",
								"type": "uint256"
							},
							{
								"internalType": "uint256",
								"name": "acceptDeadline",
								"type": "uint256"
							},
							{
								"internalType": "uint8",
								"name": "result",
								"type": "uint8"
							},
							{
								"internalType": "enum Bet.GameStatus",
								"name": "status",
								"type": "uint8"
							},
							{
								"internalType": "bool",
								"name": "isSigned",
								"type": "bool"
							},
							{
								"internalType": "uint256",
								"name": "latestSignedMove",
								"type": "uint256"
							}
						],
						"internalType": "struct Bet.Game",
						"name": "",
						"type": "tuple"
					}
				],
				"stateMutability": "view",
				"type": "function"
			},
			{
				"inputs": [
					{
						"internalType": "bytes",
						"name": "rawMessage",
						"type": "bytes"
					}
				],
				"name": "getMessageParts",
				"outputs": [
					{
						"components": [
							{
								"internalType": "uint256",
								"name": "gameId",
								"type": "uint256"
							},
							{
								"internalType": "uint256",
								"name": "moveNo",
								"type": "uint256"
							},
							{
								"internalType": "uint8",
								"name": "gameStatus",
								"type": "uint8"
							},
							{
								"internalType": "bytes",
								"name": "fen_string",
								"type": "bytes"
							}
						],
						"internalType": "struct Bet.MessageParts",
						"name": "",
						"type": "tuple"
					}
				],
				"stateMutability": "pure",
				"type": "function"
			},
			{
				"inputs": [],
				"name": "getUserGames",
				"outputs": [
					{
						"internalType": "uint256[]",
						"name": "",
						"type": "uint256[]"
					}
				],
				"stateMutability": "view",
				"type": "function"
			},
			{
				"inputs": [
					{
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					}
				],
				"name": "processWinner",
				"outputs": [],
				"stateMutability": "nonpayable",
				"type": "function"
			},
			{
				"inputs": [
					{
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					},
					{
						"internalType": "bytes",
						"name": "_previousMessage",
						"type": "bytes"
					},
					{
						"internalType": "bytes",
						"name": "_previousSignature",
						"type": "bytes"
					},
					{
						"internalType": "bytes",
						"name": "_currentMessage",
						"type": "bytes"
					},
					{
						"internalType": "bytes",
						"name": "_currentSignature",
						"type": "bytes"
					}
				],
				"name": "setSignedMessage",
				"outputs": [],
				"stateMutability": "nonpayable",
				"type": "function"
			},
			{
				"inputs": [
					{
						"internalType": "uint256",
						"name": "gameId",
						"type": "uint256"
					},
					{
						"internalType": "uint8",
						"name": "_result",
						"type": "uint8"
					}
				],
				"name": "updateWinner",
				"outputs": [],
				"stateMutability": "payable",
				"type": "function"
			},
			{
				"inputs": [
					{
						"internalType": "address",
						"name": "account",
						"type": "address"
					},
					{
						"internalType": "bytes",
						"name": "data",
						"type": "bytes"
					},
					{
						"internalType": "bytes",
						"name": "sig",
						"type": "bytes"
					}
				],
				"name": "verifyMessage",
				"outputs": [
					{
						"internalType": "bool",
						"name": "",
						"type": "bool"
					}
				],
				"stateMutability": "pure",
				"type": "function"
			}
		],
  "networks": {
    "4": {
      "events": {},
      "links": {},
      "address": "0x821fF5B3780e4615B09424D778C07ed00A81B7Ec"
    },
    "80001": {
      "events": {},
      "links": {},
      "address": "0x60CE6BF65cCde54D81958C92836f1879600b7eE8"
    }
  }
};