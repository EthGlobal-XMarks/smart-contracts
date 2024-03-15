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

    function submitGuess(uint256 longitude, uint256 latitude) public {

    }
    
    function isWinner(address addr, uint256 id) public view returns (bool) {
        return games[id].winner == addr;
    }

    function addVerifiedWallet(address addr) public onlyOwner {
        verifiedWallets[addr] = true;
    }
}