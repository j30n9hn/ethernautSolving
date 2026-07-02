# 문제 컨트랙트
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract Dex is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableToken(token1).approve(msg.sender, spender, amount);
        SwappableToken(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableToken is ERC20 {
    address private _dex;

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super._approve(owner, spender, amount);
    }
}
```
 >이 레벨의 목표는 아래 있는 기본 DEX(탈중앙화 거래소) 컨트랙트를 해킹하여, 가격 조작을 통해 자금을 탈취하는 것입니다.
> 게임을 시작하면 당신은 token1과 token2를 각각 10개씩 보유하게 됩니다. DEX 컨트랙트는 각 토큰을 100개씩 가지고 있습니다.
>
> 두 토큰 중 하나라도 전부 소진시키고, 컨트랙트가 “잘못된 가격(bad price)”를 반환하게 만들면 이 레벨을 통과할 수 있습니다.

# 풀이
---
풀이를 설명하기 앞서 AMM과 가격 계산 방식에 대해 살펴보자. 일반적인 DEX 또는 AMM은 토큰 교환 시 단순히 현재 보유량의 비율만 사용하는 것이 아니라, 유동성 풀의 불변식, 슬리피지, 수수료, 외부 가격 정보 등을 고려해 교환 비율을 조정한다. 대표적으로 `x * y = k`와 같은 구조에서는 한쪽 토큰을 많이 사려고 할수록 가격이 불리해진다. 하지만 이 문제의 `Dex` 컨트랙트는 가격을 다음과 같이 계산한다.

```solidity
function getSwapPrice(address from, address to, uint amount) public view returns (uint) {
    return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
}
```

즉, 교환 결과는 다음 공식으로 결정된다.

```text
받는 토큰 수량 = 입력 토큰 수량 * Dex가 가진 to 토큰 잔고 / Dex가 가진 from 토큰 잔고
```

문제는 이 가격 계산식이 Dex 컨트랙트 내부의 현재 잔고만을 기준으로 한다는 것이다. 따라서 사용자가 양쪽 방향으로 반복해서 스왑하면 Dex 내부의 `token1`과 `token2` 잔고 비율이 계속 흔들리게 된다. 이때 가격 계산식은 왜곡된 내부 잔고 비율을 그대로 사용하므로, 반복 스왑을 통해 공격자에게 점점 유리한 교환 비율을 만들 수 있다.

먼저 Ethernaut 콘솔에서 `token1`, `token2` 주소를 확인한다.

```javascript
const token1Addr = await contract.token1()
const token2Addr = await contract.token2()
```

이후 Dex 컨트랙트가 사용자의 토큰을 가져갈 수 있도록 approve를 수행해야 한다.

```javascript
await contract.approve(contract.address, 1000)
```

여기서 `approve`가 필요한 이유는 `swap()` 내부에서 다음 코드가 실행되기 때문이다.

```solidity
IERC20(from).transferFrom(msg.sender, address(this), amount);
```

`transferFrom()`은 `msg.sender`의 토큰을 Dex 컨트랙트가 대신 가져가는 방식이다. 따라서 사용자가 Dex 컨트랙트에게 자신의 `token1`, `token2`를 사용할 수 있는 권한을 미리 허용해야 한다. 이 과정을 하지 않으면 `transferFrom()` 단계에서 allowance가 부족하여 스왑이 실패한다.

초기 상태는 다음과 같다.

```text
공격자 token1 = 10
공격자 token2 = 10

Dex token1 = 100
Dex token2 = 100
```

이 상태에서 `token1 -> token2`, `token2 -> token1` 방향으로 번갈아 스왑하면 Dex 내부 잔고 비율이 계속 변한다. 가격 계산식은 매번 현재 Dex의 잔고를 기준으로 계산되므로, 스왑을 반복할수록 비율이 점점 왜곡된다.

예를 들어 `token2` 9개를 `token1`으로 스왑하면 계산식은 다음과 같다.

```text
9 token2 * 100 token1 / 109 token2 = 8.256...
```

Solidity에서는 정수 나눗셈이 사용되므로 소수점 이하는 버려진다. 따라서 실제로는 8개의 `token1`을 받게 된다.

스왑 이후 잔고는 다음과 같이 변한다.

```text
공격자 token1 = 18
공격자 token2 = 1

Dex token1 = 92
Dex token2 = 109
```

이후 반대 방향으로 다시 스왑하면 이번에는 변경된 Dex 내부 잔고 비율이 가격 계산에 사용된다.

```text
9 token1 * 109 token2 / 92 token1 = 10.66...
```

정수 나눗셈에 의해 실제 수령량은 10개가 된다. 이러한 방식으로 양방향 스왑을 반복하면, Dex의 한쪽 토큰 잔고는 점점 줄어들고 다른 쪽 토큰 잔고는 증가한다. 중요한 점은 단순히 총 잔고가 줄어든다는 것보다, Dex 내부의 두 토큰 비율이 공격자에게 유리하게 왜곡된다는 점이다.

반복 스왑 과정은 다음과 같이 정리할 수 있다.

| 단계 | 실행한 스왑                 | 계산식             | 실제 수령량 | 공격자 token1 | 공격자 token2 | Dex token1 | Dex token2 |
| -: | ---------------------- | --------------- | -----: | ---------: | ---------: | ---------: | ---------: |
| 초기 | -                      | -               |      - |         10 |         10 |        100 |        100 |
|  1 | `token2 -> token1`, 9개 | `9 * 100 / 109` |      8 |         18 |          1 |         92 |        109 |
|  2 | `token1 -> token2`, 9개 | `9 * 109 / 101` |      9 |          9 |         10 |        101 |        100 |
|  3 | `token2 -> token1`, 9개 | `9 * 101 / 109` |      8 |         17 |          1 |         93 |        109 |
|  4 | `token1 -> token2`, 9개 | `9 * 109 / 102` |      9 |          8 |         10 |        102 |        100 |

위 표처럼 `9`개씩만 반복하면 변화가 크지 않아 보일 수 있다. 하지만 핵심은 매번 Dex 내부 잔고 비율이 가격 계산에 그대로 반영된다는 점이다. 따라서 보유량이 늘어난 시점에는 스왑 수량을 늘려 더 크게 비율을 왜곡할 수 있다.

실제 풀이 과정에서는 중간에 스왑 수량을 늘려가며 반복했고, 최종적으로 다음과 같은 상태를 만들 수 있었다.

```text
Dex token1 = 20
Dex token2 = 109
```

이 상태에서 `token1`을 `token2`로 스왑한다고 가정하면, Dex는 다음 계산식으로 사용자가 받을 `token2` 수량을 계산한다.

```text
받을 token2 수량 = amount * Dex의 token2 잔고 / Dex의 token1 잔고
```

따라서 `amount`를 20으로 설정하면 다음과 같다.

```text
20 * 109 / 20 = 109
```

즉, Dex가 보유한 `token1` 잔고가 20개인 상태에서 공격자가 `token1` 20개를 입력하면, 계산 결과는 Dex가 보유한 `token2` 전체 수량인 109개가 된다. 따라서 다음 스왑을 실행하면 Dex의 `token2` 잔고를 0으로 만들 수 있다.

```javascript
await contract.swap(token1Addr, token2Addr, 20)
```

스왑 이후 Dex의 `token2` 잔고를 확인하면 다음과 같이 0이 된다.

```javascript
await contract.balanceOf(token2Addr, contract.address)
```

```text
0
```

중간에 더 큰 수량을 스왑하려고 하면 실패할 수 있다. 예를 들어 Dex의 잔고가 다음과 같은 상태라고 하자.

```text
Dex token1 = 20
Dex token2 = 109
```

이때 `token1` 89개를 `token2`로 스왑하려고 하면 계산식은 다음과 같다.

```text
89 * 109 / 20 = 485
```

그러나 Dex는 `token2`를 109개밖에 가지고 있지 않다. 따라서 Dex가 사용자에게 485개의 `token2`를 전송하려고 시도하는 과정에서 `ERC20: transfer amount exceeds balance` 오류가 발생하고 트랜잭션은 revert된다.

결국 마지막 스왑에서는 무조건 큰 값을 넣는 것이 아니라, Dex가 보유한 `from` 토큰 잔고를 기준으로 입력값을 정해야 한다. Dex의 `from` 토큰 잔고가 `X`, `to` 토큰 잔고가 `Y`라면 다음과 같이 계산된다.

```text
X * Y / X = Y
```

즉, 공격자가 Dex가 보유한 `from` 토큰 잔고와 같은 수량을 스왑하면, Dex가 보유한 `to` 토큰 전체가 출력값으로 계산된다.

최종적으로 문제 풀이 흐름은 다음과 같이 정리할 수 있다.

```javascript
const token1Addr = await contract.token1()
const token2Addr = await contract.token2()

await contract.approve(contract.address, 1000)

// 이후 token1 -> token2, token2 -> token1 방향으로 반복 스왑
// Dex 내부 잔고 비율을 공격자에게 유리하게 왜곡

await contract.swap(token1Addr, token2Addr, 20)
```

이 문제의 핵심 취약점은 Dex가 가격을 계산할 때 외부 가격 정보나 안정적인 AMM 불변식을 사용하지 않고, 오직 자기 자신의 현재 토큰 잔고 비율만을 신뢰한다는 점이다. 그 결과 공격자는 반복적인 양방향 스왑을 통해 내부 잔고 비율을 왜곡할 수 있고, 마지막에는 한쪽 토큰 잔고 전체를 빼낼 수 있다.

