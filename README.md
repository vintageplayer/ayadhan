# Ayadhan
Stake Crypto and Play Chess

## How to Play
1. Player 1 sets the bet amount and sends a create game transaction to smart contract
2. Smart contract accepts the bet amount and records a new game
3. Creator is given a invite link to share with player2
4. Each player will make the moves
5. In non-signed mode, when a move is made where the game ends, the smart contract function to update winner and transfer pool is automatically triggered
6. In signed mode, the final move needs to be submitted post which money can be withdrawn.


## Signed Messages
### Signed Message Format
Signed Messages are formed of three 4 parts:
1. gameId: The gameId in the contract
2. MoveNo: Number of half moves made in the game to generate the message
3. gameStatus: 6 games representing it's a plain move; claiming draw; person resigned; it's claiming checkmate with the current move; person acknowledging his/her loss or person storing confirmed win message.
4. Fen String: The current state of the board know to represent the complete state of the game.

Using these 4 fields, the current stage can be irrefutably agreed by both the parties.

### How it works
The signed messages are stored in the client software of each player and not actually sent to the chain. Though the players have the option to do so any time. Think of this as an optional save point.
This saves gas fees in storing all messages. Only the latest 2 need (one from each player) need to be stored in the blockchain.
Since both the messages are verifiably signed, the latest game state is irrefutable and thus the result is confirmed.

A person can manipulate only their latest move which the opponent can challenge withthin the timeout period (currently one day).

## Architecture
![Architecture Image ](https://github.com/vintageplayer/ayadhan/blob/master/Ayadhan_architecture.png?raw=true)

The app is hosted on StackOS and heroku.
The NFTs and it's metadata are stored in IPFS.
Moralis is used to retrieve the user owned NFTs.

### Supported Networks
 - 80001 - Polygon (Matic) Mumbai Testnet
 - 4 - Ethereum Rinkey Testnet

In RoadMap:
 - Enable 3D Chess Board
 - Create a Marketplace for people to mint their own chess pieces NFT and sell it on the marketplace.
 - Create special edition NFT to allowing users a a cut from platform fee
 - Make the UI Changes to challenge signed messages
 - Show Historical Games and Allow resuming previous games
 - Add timer and different chess modes
 - Incorporate Elo Rating
 - Allow Chess Tournaments, optionally with NFT based special entry
 - Create a Mobile App
 - Plugin for Fiat Payment


For a chess board UI: https://chessboardjs.com/examples.html#5000

For a platform:
 https://github.com/freechessclub/freechessclub-app/tree/b203bd4388a8befb59460d723a9885c941e9c1c3/src
 https://github.com/freechessclub/freechessclub