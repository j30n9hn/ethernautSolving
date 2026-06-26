# 문제 코드
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNum {
    address public solver;

    constructor() {}

    function setSolver(address _solver) public {
        solver = _solver;
    }

    /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
    */
}
```
> `whatIsTheMeaningOfLife()`를 호출했을 때 32바이트 크기의 42를 출력해라. 단 공격 컨트랙트의 바이트코드 크기가 딱 10바이트 이내여야 한다.

# 풀이
---
```bytecode
runtime bytecode
602a     push1 0x2a   // push(42) => 42 is required by problem
6000     push1 0x00   // push(0x00) => 0x00 == offset
52        mstore         // memory[0x00:0x00+32] = 0x2a, 32 is fixed value
6020     push1 0x20   // push(0x20) => 0x20 == memory[0x00:0x00+32] length
6000     push1 0x00   // push(0x00) => 0x00 == offset
f3         return          // return memory[0x00:0x00+0x20]

=> 0x602a60005260206000f3

creation bytecode
600a     push1 0x0a   // push(0x0a) => 0x0a == runtime bytecode size
600c     push1 0x0c   // push(0x0c) => 0x0c == runtime code offset
6000     push1 0x00   // push(0x00) => 0x00 == memory offset
39        codecopy     // memory[0x00:0x00+0x0a] = address(this).code[0x0c:0x0c+0x0a]
600a     push1 0x0a   // push(0x0a) => 0x0a == return size and runtime bytecode size
6000     push1 0x00   // push(0x00) => 0x00 == return offset and memory offset
f3         return          // return memory[0x00:0x00+0x0a]
...runtime bytecode
=> 0x600a600c600039600a6000f3

==> 0x600a600c600039600a6000f3602a60005260206000f3
```
EVM bytecode에 대한 자세한 내용은 [ethervm.io](https://ethervm.io/)를 참고하자. 우선 문제 풀이 설명에 앞서 `creation bytecode`와 `runtime bytecode`에 대해 알아보자.

`creation bytecode`는 컨트랙트 배포 시점에 한 번 실행되는 코드이며, 최종적으로 컨트랙트 주소에 저장될 `runtime bytecode`를 반환한다. `runtime bytecode`는 배포 이후 해당 컨트랙트 주소에 실제로 저장되고, 외부 호출이 들어왔을 때 실행되는 실질적인 컨트랙트 코드이다.

EVM bytecode의 전체 구조는 `[creation bytecode][runtime bytecode]`의 형태를 가진다. 문제 풀이에 사용된 바이트코드를 살펴보자. 앞서 설명한 내용에 따르면 `creation bytecode`를 먼저 작성해야될 것 같지만 `offset` 및 `size` 계산을 고려하여 `runtime bytecode`를 먼저 작성하였다. 바이트코드에 대한 설명은 앞서 링크한 사이트와 풀이 코드의 주석으로 갈음한다.

최종적으로 완성된 바이트코드는 `0x600a600c600039600a6000f3602a60005260206000f3`이다. 이 바이트코드를 콘솔을 통해 배포해야 한다.

```javascript
const bytecode = "0x600a600c600039600a6000f3602a60005260206000f3";

const accounts = await web3.eth.getAccounts();

const tx = await web3.eth.sendTransaction({
    from: account[0],
    data: bytecode,
    gas: 100000
});

await tx.contractAddress;

await contract.setSolver("0x13456cA582ca7C04a80333e65369F84607615EBD");
```

위 코드를 살펴보면 `web3.eth.sendTransction()`에 `to` 주소가 없는 것을 알 수 있다. 이런 경우 EVM은 contract creation transaction으로 처리한다. 따라서 해당 명령어를 통해 공격 바이트코드를 배포하고 `await tx.contractAddress;`를 실행하여 해당 컨트랙트의 주소를 찾아야 한다. 찾은 공격 컨트랙트 주소를 `setSolver()`의 인자로 넘겨주면 해결된다.
