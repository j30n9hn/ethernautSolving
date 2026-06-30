# 문제 컨트랙트
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuyer {
  function price() external view returns (uint256);
}

contract Shop {
  uint256 public price = 100;
  bool public isSold;

  function buy() public {
    IBuyer _buyer = IBuyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}
```
> 상점에서 요구된 가격보다 더 저렴하게 아이템을 구입할 수 있을까요?

# 풀이
---
문제를 살펴보면 상품 가격을 최초 100으로 초기화하고, 이후 `buy()` 함수에서는 외부 컨트랙트를 통해 해당 상품의 가격을 가져온다. 공격자는 공격 컨트랙트를 통해 임의 가격을 설정하여 상품 가격을 변조할 수 있다. `_buyer.price()`가 조건문의 조건식과 내용에서 각각 호출되므로 그 사이에 값을 변조하면 100 보다 낮은 가격에서 구매할 수 있다. 그러나 `price()` 함수는 `view` 키워드로 선언되었기 때문에 외부 값을 기준으로 해야 상품 가격을 변동할 수 있다.

솔리디티에서 `public` 키워드로 선언된 상태변수는 자동적으로 `getter`함수가 생성되며, 인터페이스로 호출할 수 있다. `_buyer.price()` 호출 사이에 변경되는 `isSold` 변수를 기준으로 `price()`의 반환값을 다르게 하면, 상품 가격을 100 보다 낮은 가격에서 구매할 수 있게 된다.
