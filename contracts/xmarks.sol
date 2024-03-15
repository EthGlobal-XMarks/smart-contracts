// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract XMarks {
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

    constructor() {}
}