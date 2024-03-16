import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IPrizes {
    function awardItem(address winner, string memory tokenURI) external;
}

contract XMarks is ConfirmedOwner, VRFConsumerBaseV2 {
    uint256 public gameId = 0;
    uint256 public maximumGuesses = 3;

    address prizesContract;

    struct GameInstance {
        address winner;
        uint256 id;
        uint256 winningLongitude;
        uint256 winningLatitude;
        string image;
        bool active;
        bytes32 longitudeHash;
        bytes32 latitudeHash;
    }

    struct Guess {
        uint256 longitude;
        uint256 latitude;
        address wallet;
    }

    mapping (uint256 => GameInstance) public games;

    mapping (uint256 => Guess[]) public gameGuesses;

    mapping (address => mapping(uint256 => Guess[])) public gameData;

    mapping (address => bool) public verifiedWallets;

    uint64 s_subscriptionId;

    bytes32 keyHash = 0x027f94ff1465b3525f9fc03e9ff7d6d2c0953482246dd6ae07570c45d6631414;

    uint32 callbackGasLimit = 800000;
    
    uint16 requestConfirmations = 3;

    uint32 numWords = 2;

    VRFCoordinatorV2Interface COORDINATOR;
    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    constructor(uint64 randomSubscriptionId) ConfirmedOwner(msg.sender) VRFConsumerBaseV2(0x50d47e4142598E3411aA864e08a44284e471AC6f) {
        s_subscriptionId = randomSubscriptionId;
        COORDINATOR = VRFCoordinatorV2Interface(
            0x50d47e4142598E3411aA864e08a44284e471AC6f
        );
    }

    function setPrizesContract(address _prizesContract) public onlyOwner {
        prizesContract = _prizesContract;
    }

    function getGameData(address wallet, uint256 instance) public view returns (Guess[] memory) {
        return gameData[wallet][instance];
    }

    function getCurrentGameImage() public view returns (string memory) {
        return games[gameId].image;
    }

    function setImage(string memory image) public onlyOwner {
        GameInstance memory instance = GameInstance({
            winner: address(0), 
            id: gameId, 
            winningLongitude: 0,
            winningLatitude: 0,
            image: image,
            active: true,
            longitudeHash: games[gameId].longitudeHash,
            latitudeHash: games[gameId].latitudeHash
        });

        games[gameId] = instance;
    }

    function requestRandomWords() private returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function convertToString(uint256 number) public pure returns (string memory) {
        string memory str = toString(number);
        return str;
    }
 
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
 
        uint256 temp = value;
        uint256 digits;
 
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
 
        bytes memory buffer = new bytes(digits);
 
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
 
        return string(buffer);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        string memory random1 = convertToString(_randomWords[0]);
        string memory random2 = convertToString(_randomWords[1]);

        GameInstance memory instance = GameInstance({
            winner: address(0), 
            id: gameId, 
            winningLongitude: 0,
            winningLatitude: 0,
            image: "",
            active: true,
            longitudeHash: sha256(bytes(random1)),
            latitudeHash: sha256(bytes(random2))
        });

        games[gameId] = instance;
    }

    // returns all guesses from a given game instance
    function getGameGuesses(uint256 id) public view returns (Guess[] memory) {
        return gameGuesses[id]; 
    }


    function submitGuess(uint256 longitude, uint256 latitude) public {
        require(gameData[msg.sender][gameId].length < maximumGuesses, "XMarks: maximum guesses reached for this wallet");
        require(games[gameId].active, "XMarks: the game has ended");
        if (gameData[msg.sender][gameId].length > 0) {
            require(verifiedWallets[msg.sender], "XMarks: wallet is not verified with Worldcoin");
        }
        Guess memory guess = Guess({
            longitude: longitude, 
            latitude: latitude, 
            wallet: msg.sender
        });
        gameData[msg.sender][gameId].push(guess);
        gameGuesses[gameId].push(guess);
    }

    function recordWinner(address winner, uint256 winningLongitude, uint256 winningLatitude) public onlyOwner {
          GameInstance memory instance = GameInstance({
            winner: winner, 
            id: gameId, 
            winningLongitude: winningLongitude,
            winningLatitude: winningLatitude,
            image: games[gameId].image,
            active: false,
            longitudeHash: games[gameId].longitudeHash,
            latitudeHash: games[gameId].latitudeHash
        });

        games[gameId] = instance;

        IPrizes(prizesContract).awardItem(winner, games[gameId].image);
    }

    // starts a new game and increments the game id
    function startNewGame() public onlyOwner {
        gameId = gameId + 1;
        requestRandomWords();
    }
    
    function isWinner(address addr, uint256 id) public view returns (bool) {
        return games[id].winner == addr;
    }

    function addVerifiedWallet(address addr) public onlyOwner {
        verifiedWallets[addr] = true;
    }
}