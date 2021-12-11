// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract Bet {
    address issuer;
    enum GameStatus {CREATED, LOCKED, FINISHED, CANCELLED}
    struct Game {
        address player1;
        address player2;
        uint amount;
        uint acceptDeadline;
        uint8 result;
        GameStatus status;  
    }
    uint game_count;
    mapping(uint=>Game) games;
    mapping(address=>uint[]) userGames;

    event GameCreated(uint gameId, address creator, uint amount);
    event GameAccepted(uint gameId, address acceptor, uint amount);
    event GameFinished(uint gameId, address winner, uint amount);
    event GameDraw(uint gameId, address player1, address player2, uint amount);
    event GameCancelled(uint gameId, address creator, uint amount);

    constructor() {
        issuer = msg.sender;
    }

    function createGame(uint _acceptDeadline)
    public
    payable
    hasValue()
    validAcceptDeadline(_acceptDeadline)
    returns(uint) {
        game_count +=1;
        games[game_count].player1 = msg.sender;
        games[game_count].acceptDeadline = _acceptDeadline;
        games[game_count].amount = msg.value;
        games[game_count].status = GameStatus.CREATED;
        userGames[msg.sender].push(game_count);
        emit GameCreated(game_count, msg.sender, msg.value);
        return game_count;
    }

    function acceptGame(uint gameId)
    public
    payable
    validGame(gameId)
    validateGameStatus(gameId, GameStatus.CREATED)
    beforeDeadline(gameId)
    validValue(gameId)
    isNotCreator(gameId)
    {
        games[gameId].status = GameStatus.LOCKED;
        games[gameId].player2 = msg.sender;
        userGames[msg.sender].push(gameId);
        emit GameAccepted(gameId, msg.sender, msg.value);
    }

    function updateWinner(uint gameId, uint8 _result)
    payable
    public
    validGame(gameId)
    validateGameStatus(gameId, GameStatus.LOCKED)
    isPlayer(gameId)
    validResult(_result)
    {
        games[gameId].status = GameStatus.FINISHED;
        games[gameId].result = _result;
        if (_result == 1) {
            payable(games[gameId].player1).transfer(2*games[gameId].amount);
            emit GameFinished(gameId, games[gameId].player1, 2*games[gameId].amount);
        } else if (_result == 2) {
            payable(games[gameId].player2).transfer(2*games[gameId].amount);
            emit GameFinished(gameId, games[gameId].player2, 2*games[gameId].amount);
        } else {
            payable(games[gameId].player1).transfer(games[gameId].amount);
            payable(games[gameId].player2).transfer(games[gameId].amount);
            emit GameDraw(gameId, games[gameId].player1, games[gameId].player2, games[gameId].amount);
        }
    }

    function getUserGames()
    public
    view
    returns(uint[] memory)
    {
        return userGames[msg.sender];
    }

    function getGameDetails(uint gameId)
    public
    view
    validGame(gameId)
    returns(Game memory) {
        return games[gameId];
    }

    function cancelGame(uint gameId)
    public
    payable
    validGame(gameId)
    validateGameStatus(gameId, GameStatus.CREATED)
    deadlineOver(gameId)
    isCreator(gameId)
    {
        games[gameId].status = GameStatus.CANCELLED;
        payable(games[gameId].player1).transfer(games[gameId].amount);
        emit GameCancelled(gameId, msg.sender, games[gameId].amount);
    }

    modifier hasValue() {
        require(msg.value > 0, "Invalid Bet Amount!!");
        _;
    }

    modifier validAcceptDeadline(uint acceptDeadline) {
        require(acceptDeadline > block.timestamp, "Deadline needs to be in future!!");
        _;
    }

    modifier validGame(uint gameId) {
        require(gameId <= game_count, "Invalid Game ID");
        _;
    }

    modifier beforeDeadline(uint gameId) {
        require(games[gameId].acceptDeadline > block.timestamp, "Deadline breached!!");
        _;
    }

    modifier deadlineOver(uint gameId) {
        require(games[gameId].acceptDeadline <= block.timestamp, "Deadline Not Yet Over");
        _;
    }

    modifier validateGameStatus(uint gameId, GameStatus desiredStatus) {
        require(games[gameId].status == desiredStatus, "Game Not in ${desiredStatus} state");
        _;
    }

    modifier validValue(uint gameId) {
        require(msg.value == games[gameId].amount, "Invalid Bet Amount!!");
        _;
    }

    modifier validResult(uint8 result) {
        require(result < 3, "Invalid result code. Supported: (1,3)");
        _;
    }

    modifier isCreator(uint gameId) {
        require(games[gameId].player1 == msg.sender, "Unauthorized: Not the game creator!!");
        _;
    }

    modifier isNotCreator(uint gameId) {
        require(games[gameId].player1 != msg.sender, "Unauthorized: Not the game creator!!");
        _;
    }


    modifier isPlayer(uint gameId) {
        require((games[gameId].player1 == msg.sender) || (games[gameId].player2 == msg.sender),
        "Unauthorized: Not a player!!"
        );
        _;
    }

    modifier isIssuer() {
        require(msg.sender == issuer, "Unauthorized: Not the contract owner!!");
        _;
    }
}// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract Bet {
    address issuer;
    enum GameStatus {CREATED, LOCKED, FINISHED, CANCELLED}
    struct Game {
        address player1;
        address player2;
        uint amount;
        uint acceptDeadline;
        uint8 result;
        GameStatus status;  
    }
    uint game_count;
    mapping(uint=>Game) games;
    mapping(address=>uint[]) userGames;

    event GameCreated(uint gameId, address creator, uint amount);
    event GameAccepted(uint gameId, address acceptor, uint amount);
    event GameFinished(uint gameId, address winner, uint amount);
    event GameDraw(uint gameId, address player1, address player2, uint amount);
    event GameCancelled(uint gameId, address creator, uint amount);

    constructor() {
        issuer = msg.sender;
    }

    function createGame(uint _acceptDeadline)
    public
    payable
    hasValue()
    validAcceptDeadline(_acceptDeadline)
    returns(uint) {
        game_count +=1;
        games[game_count].player1 = msg.sender;
        games[game_count].acceptDeadline = _acceptDeadline;
        games[game_count].amount = msg.value;
        games[game_count].status = GameStatus.CREATED;
        userGames[msg.sender].push(game_count);
        emit GameCreated(game_count, msg.sender, msg.value);
        return game_count;
    }

    function acceptGame(uint gameId)
    public
    payable
    validGame(gameId)
    validateGameStatus(gameId, GameStatus.CREATED)
    beforeDeadline(gameId)
    validValue(gameId)
    isNotCreator(gameId)
    {
        games[gameId].status = GameStatus.LOCKED;
        games[gameId].player2 = msg.sender;
        userGames[msg.sender].push(gameId);
        emit GameAccepted(gameId, msg.sender, msg.value);
    }

    function updateWinner(uint gameId, uint8 _result)
    payable
    public
    validGame(gameId)
    validateGameStatus(gameId, GameStatus.LOCKED)
    isPlayer(gameId)
    validResult(_result)
    {
        games[gameId].status = GameStatus.FINISHED;
        games[gameId].result = _result;
        if (_result == 1) {
            payable(games[gameId].player1).transfer(2*games[gameId].amount);
            emit GameFinished(gameId, games[gameId].player1, 2*games[gameId].amount);
        } else if (_result == 2) {
            payable(games[gameId].player2).transfer(2*games[gameId].amount);
            emit GameFinished(gameId, games[gameId].player2, 2*games[gameId].amount);
        } else {
            payable(games[gameId].player1).transfer(games[gameId].amount);
            payable(games[gameId].player2).transfer(games[gameId].amount);
            emit GameDraw(gameId, games[gameId].player1, games[gameId].player2, games[gameId].amount);
        }
    }

    function getUserGames()
    public
    view
    returns(uint[] memory)
    {
        return userGames[msg.sender];
    }

    function getGameDetails(uint gameId)
    public
    view
    validGame(gameId)
    returns(Game memory) {
        return games[gameId];
    }

    function cancelGame(uint gameId)
    public
    payable
    validGame(gameId)
    validateGameStatus(gameId, GameStatus.CREATED)
    deadlineOver(gameId)
    isCreator(gameId)
    {
        games[gameId].status = GameStatus.CANCELLED;
        payable(games[gameId].player1).transfer(games[gameId].amount);
        emit GameCancelled(gameId, msg.sender, games[gameId].amount);
    }

    modifier hasValue() {
        require(msg.value > 0, "Invalid Bet Amount!!");
        _;
    }

    modifier validAcceptDeadline(uint acceptDeadline) {
        require(acceptDeadline > block.timestamp, "Deadline needs to be in future!!");
        _;
    }

    modifier validGame(uint gameId) {
        require(gameId <= game_count, "Invalid Game ID");
        _;
    }

    modifier beforeDeadline(uint gameId) {
        require(games[gameId].acceptDeadline > block.timestamp, "Deadline breached!!");
        _;
    }

    modifier deadlineOver(uint gameId) {
        require(games[gameId].acceptDeadline <= block.timestamp, "Deadline Not Yet Over");
        _;
    }

    modifier validateGameStatus(uint gameId, GameStatus desiredStatus) {
        require(games[gameId].status == desiredStatus, "Game Not in ${desiredStatus} state");
        _;
    }

    modifier validValue(uint gameId) {
        require(msg.value == games[gameId].amount, "Invalid Bet Amount!!");
        _;
    }

    modifier validResult(uint8 result) {
        require(result < 3, "Invalid result code. Supported: (1,3)");
        _;
    }

    modifier isCreator(uint gameId) {
        require(games[gameId].player1 == msg.sender, "Unauthorized: Not the game creator!!");
        _;
    }

    modifier isNotCreator(uint gameId) {
        require(games[gameId].player1 != msg.sender, "Unauthorized: Not the game creator!!");
        _;
    }


    modifier isPlayer(uint gameId) {
        require((games[gameId].player1 == msg.sender) || (games[gameId].player2 == msg.sender),
        "Unauthorized: Not a player!!"
        );
        _;
    }

    modifier isIssuer() {
        require(msg.sender == issuer, "Unauthorized: Not the contract owner!!");
        _;
    }
}