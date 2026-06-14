// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract force {

    constructor(address payable target) payable {
        selfdestruct(target);
    }
}
