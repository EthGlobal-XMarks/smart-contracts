import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract XMarks is ConfirmedOwner {
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

    constructor() ConfirmedOwner(msg.sender) {}

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