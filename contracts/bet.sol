// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import './Verifier.sol';
import './utils.sol';
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract Bet is VRFConsumerBase, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    uint256 public volume;
    address private oracle;
    bytes32 private jobId;
    uint256 private chainLinkGetRequestFee;
    string apiBaseUrl = "https://ayadhan.herokuapp.com/validate";

    address issuer;
    bytes32 internal keyHash;
    uint256 internal chainLinkVrfFee;
    
    uint256 public randomResult;
    
    enum GameStatus {CREATED, LOCKED, FINISHED, CANCELLED}
    enum MessageGameStatus {MOVEV, DRAW, WIN_MOVE, LOST, WON, RESIGN}
    
    struct Game {
        address player1;
        address player2;
        uint amount;
        uint acceptDeadline;
        uint8 result;
        GameStatus status;
        bool isSigned;
        uint latestSignedMove;
        bool creatorStartsAsBlack;
    }

    struct MoveSigns {
        bytes previousMessage;
        bytes previousSignature;
        MessageParts previousMessageParts;
        bytes currentMessage;
        bytes currentSignature;
        MessageParts currentMessageParts;
        uint nextMessageDeadline;
        address enteredBy;
    }

    struct MessageParts {
        uint gameId;
        uint moveNo;
        uint8 gameStatus;
        bytes fen_string;
    }

    uint game_count;
    mapping(uint=>Game) games;
    mapping(address=>uint[]) userGames;
    mapping(uint=>MoveSigns) latestGameSigns;
    mapping(bytes32 => uint) requestingVRFGameId;
    mapping(bytes32 => uint) requestingAPIGameId;

    event GameCreated(uint gameId, address creator, uint amount);
    event GameAccepted(uint gameId, address acceptor, uint amount);
    event GameFinished(uint gameId, address winner, uint amount);
    event GameDraw(uint gameId, address player1, address player2, uint amount);
    event GameCancelled(uint gameId, address creator, uint amount);

    // ToDo - Remove hardcoded values to parameterized
    constructor() VRFConsumerBase(0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, 0x326C977E6efc84E512bB9C30f76E30c160eD06FB) {
        issuer = msg.sender;
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        chainLinkVrfFee = 0.0001 * 10 ** 18; // 0.1 LINK (Varies by network)

        // Setting Values for Get Request        
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        oracle = 0x0bDDCD124709aCBf9BB3F824EbC61C87019888bb;
        jobId = "52d54fc095ad4327a092354b31ee1d3e";
        chainLinkGetRequestFee = 0.01 * 10 ** 18; // (Varies by network and job)
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= chainLinkVrfFee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, chainLinkVrfFee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint gameId = requestingVRFGameId[requestId];
        if (randomness%2==0) {
            games[gameId].creatorStartsAsBlack = true;
        } else {
            games[gameId].creatorStartsAsBlack = false;
        }
        delete requestingVRFGameId[requestId];
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function makeApiCall(string memory url) internal returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);        
        request.add("get", url);
        request.add("path", "comparisonCode");
        return sendChainlinkRequestTo(oracle, request, chainLinkGetRequestFee);
    }
    
    /**
     * Receive the response in the form of uint256
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
    function fulfill(bytes32 _requestId, uint256 comparisonCode) public recordChainlinkFulfillment(_requestId)
    {
        uint gameId = requestingAPIGameId[_requestId];
        address player1 = games[gameId].player1;
        uint8 _result = 3;
        if (comparisonCode == 1) {
            _result = 2;
            if (latestGameSigns[gameId].enteredBy == player1) {
                _result = 1;
            }
        } else if (comparisonCode == 2 || comparisonCode == 3) {
            _result = 1;
            if (latestGameSigns[gameId].enteredBy == player1) {
                _result = 2;
            }
        } else if (comparisonCode == 5 || comparisonCode == 9) {
            _result = 0;
        } else if (comparisonCode == 6 || comparisonCode == 10) {
            _result = 1;
            if (games[gameId].creatorStartsAsBlack == true) {
                _result = 2;
            }
        } else if (comparisonCode == 6 || comparisonCode == 10) {
            _result = 2;
            if (games[gameId].creatorStartsAsBlack == true) {
                _result = 1;
            }
        }

        if (_result < 3) {
            games[gameId].status = GameStatus.FINISHED;
            games[gameId].result = _result;
            if (_result == 1) {
                payable(games[gameId].player1).transfer(2*games[gameId].amount);
                emit GameFinished(gameId, games[gameId].player1, 2*games[gameId].amount);
            } else if (_result == 2) {
                payable(games[gameId].player2).transfer(2*games[gameId].amount);
                emit GameFinished(gameId, games[gameId].player2, 2*games[gameId].amount);
            } else if (_result == 0){
                payable(games[gameId].player1).transfer(games[gameId].amount);
                payable(games[gameId].player2).transfer(games[gameId].amount);
                emit GameDraw(gameId, games[gameId].player1, games[gameId].player2, games[gameId].amount);
            }
        }
    }

    function createGame(uint _acceptDeadline, bool _isSigned)
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
        games[game_count].isSigned = _isSigned;
        userGames[msg.sender].push(game_count);
        bytes32 requestId = getRandomNumber();
        requestingVRFGameId[requestId] = game_count;
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
        games[gameId].latestSignedMove = 0;
        userGames[msg.sender].push(gameId);
        emit GameAccepted(gameId, msg.sender, msg.value);
    }

    function setSignedMessage(uint gameId, bytes calldata _previousMessage, bytes memory _previousSignature, bytes calldata _currentMessage, bytes memory _currentSignature)
    public
    validGame(gameId)
    validateGameStatus(gameId, GameStatus.LOCKED)
    {
        require((games[gameId].player1 == msg.sender) || (games[gameId].player2 == msg.sender),
        "Unauthorized: Not a player!!"
        );
        require(games[gameId].isSigned == true, "Not a Signed Game!!");

        require(verifyMessage(msg.sender, _currentMessage, _currentSignature) == true, "Invalid Player Message");
        MessageParts memory cMsgParts = getMessageParts(_currentMessage);
        require(cMsgParts.gameId == gameId, "Invalid Current Game Id");

        if (cMsgParts.moveNo != 1) {
            if (msg.sender == games[gameId].player1) {
                require(verifyMessage(games[gameId].player2 ,_previousMessage, _previousSignature) == true, "Invalid Previous Message");
            } else {
                require(verifyMessage(games[gameId].player1 ,_previousMessage, _previousSignature) == true, "Invalid Previous Message");
            }            
            MessageParts memory pMsgParts = getMessageParts(_previousMessage);
            require(pMsgParts.gameId == gameId, "Invalid Previous Game Id");
            require(cMsgParts.moveNo == (pMsgParts.moveNo+1), "MoveNo Not Sequential in the two messages");
            require(pMsgParts.moveNo >= games[gameId].latestSignedMove , "Previous MoveNo Older Than last recorded entry");
            latestGameSigns[gameId].previousMessageParts = pMsgParts;
        } else {
            require(games[gameId].latestSignedMove == 0, "Latest Move not newer than last recorded move");
        }
        
        games[gameId].latestSignedMove = cMsgParts.moveNo;
        latestGameSigns[gameId].previousMessage = _previousMessage;
        latestGameSigns[gameId].previousSignature = _previousSignature;
        latestGameSigns[gameId].currentMessage = _currentMessage;
        latestGameSigns[gameId].currentSignature = _currentSignature;
        latestGameSigns[gameId].currentMessageParts = cMsgParts;
        latestGameSigns[gameId].nextMessageDeadline = block.timestamp + 86400000;
        latestGameSigns[gameId].enteredBy = msg.sender;
    }

    function challengeMoveEntry(uint gameId)
    public
    validGame(gameId)
    validateGameStatus(gameId, GameStatus.LOCKED)
    isPlayer(gameId)
    {
        require(games[gameId].isSigned == true, "Not a Signed Game!!");
        require(games[gameId].latestSignedMove > 0, "No Move Made Yet in the game");

        bytes memory prevFenHex = latestGameSigns[gameId].previousMessageParts.fen_string;
        bytes memory curFenHex = latestGameSigns[gameId].currentMessageParts.fen_string;
        string memory url = string(abi.encodePacked(apiBaseUrl, string(prevFenHex), string(curFenHex)));
        bytes32 requestId = makeApiCall(url);
        requestingAPIGameId[requestId] = gameId;
    }


    function processWinner(uint gameId) public
    validGame(gameId)
    validateGameStatus(gameId, GameStatus.LOCKED)
    isPlayer(gameId)
    {
        require(games[gameId].isSigned == true ,"Applicable only for signed games!");
        require(games[gameId].latestSignedMove > 0, "No Move Made Yet in the game");
        MessageParts memory cMsgParts = latestGameSigns[gameId].currentMessageParts;
        uint8 _result = 2;

        if (latestGameSigns[gameId].nextMessageDeadline < block.timestamp) {
            require(games[gameId].latestSignedMove > 1, "Need to wait for deadline with only 1 move!");

            MessageParts memory pMsgParts = latestGameSigns[gameId].previousMessageParts;

            if (cMsgParts.gameStatus == uint8(MessageGameStatus.WON)) {
                require(pMsgParts.gameStatus == uint8(MessageGameStatus.LOST) || pMsgParts.gameStatus == uint8(MessageGameStatus.RESIGN), "Won Message without Opponents Acceptance. Need to wait for deadline");
                require(msg.sender == latestGameSigns[gameId].enteredBy, "Can be invoked only by the winner");
            } else if (cMsgParts.gameStatus == uint8(MessageGameStatus.LOST) || cMsgParts.gameStatus == uint8(MessageGameStatus.RESIGN)) {
                require(msg.sender != latestGameSigns[gameId].enteredBy, "Can be invoked only by the winner");
            } else if (cMsgParts.gameStatus == uint8(MessageGameStatus.DRAW) && pMsgParts.gameStatus == uint8(MessageGameStatus.DRAW)) {
                _result = 0;
            } else {
                require(false, "Not a valid state for closing before deadline");
            }
        } else {
            if (cMsgParts.gameStatus == uint8(MessageGameStatus.DRAW) ) {
                _result = 0;
            } else if (cMsgParts.gameStatus == uint8(MessageGameStatus.RESIGN) || cMsgParts.gameStatus == uint8(MessageGameStatus.LOST)) {
                require(msg.sender != latestGameSigns[gameId].enteredBy, "Can be invoked only by the winner");
            } else {
                require(msg.sender == latestGameSigns[gameId].enteredBy, "Can be invoked only by the winner");
            }
        }

        if (_result == 2) {
                if (msg.sender == games[gameId].player1) {
                    _result = 1;
                } else {
                    _result = 2;
                }   
        }

        games[gameId].status = GameStatus.FINISHED;
        games[gameId].result = _result;
        if (_result == 1) {
            payable(games[gameId].player1).transfer(2*games[gameId].amount);
            emit GameFinished(gameId, games[gameId].player1, 2*games[gameId].amount);
        } else if (_result == 2) {
            payable(games[gameId].player2).transfer(2*games[gameId].amount);
            emit GameFinished(gameId, games[gameId].player2, 2*games[gameId].amount);
        } else if (_result == 0){
            payable(games[gameId].player1).transfer(games[gameId].amount);
            payable(games[gameId].player2).transfer(games[gameId].amount);
            emit GameDraw(gameId, games[gameId].player1, games[gameId].player2, games[gameId].amount);
        }
    }

    function updateWinner(uint gameId, uint8 _result)
    payable
    public
    validGame(gameId)
    validateGameStatus(gameId, GameStatus.LOCKED)
    isPlayer(gameId)
    validResult(_result)
    {
        require(games[gameId].isSigned == false ,"Not applicable for signed games");
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

    function getMessageParts(bytes calldata rawMessage) public pure returns (MessageParts memory) {
        uint gameId = uint(bytes32(rawMessage[0:32]));
        uint moveNo = uint(bytes32(rawMessage[32:64]));
        uint8 gameStatus = uint8(bytes1(rawMessage[64:65]));
        return MessageParts({gameId: gameId, moveNo: moveNo, gameStatus: gameStatus, fen_string: rawMessage[65:]});
    }

    function verifyMessage(address account, bytes calldata data, bytes memory sig) public pure returns (bool) {
       return Verifier.verifySig(account, keccak256(data), sig);
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

    modifier isSignedGame(uint gameId) {
        require(games[gameId].isSigned == true, "Not a Signed Game!!");
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

    modifier validMessageSignature(uint gameId, bytes calldata message, bytes memory signature) {
        verifyMessage(games[gameId].player1, message, signature);
        _;
    }
}