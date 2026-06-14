// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IntVault {
    function unlock(bytes32 _password) external;
}

contract vaultAttack {
    IntVault public vault;

    constructor(address target) {
        vault = IntVault(target);
    }

    function unlock() public {
        vault.unlock();
    }
}
