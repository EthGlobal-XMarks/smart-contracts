// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract XMarksPrizes is ERC721URIStorage {
    uint256 private _nextTokenId;
    address gameContract;

    modifier onlyGameContract {
        require(msg.sender == gameContract);
        _;
    }

    constructor(address gameContract_) ERC721("Xmarks", "XMARKS") {
        gameContract = gameContract_;
    }

    function awardItem(address winner, string memory tokenURI) public onlyGameContract {
        uint256 tokenId = _nextTokenId++;
        _mint(winner, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }
}