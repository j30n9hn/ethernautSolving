# 문제 코드
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    //generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;

    // constructor
    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // collect ether in return for tokens
    receive() external payable {
        balances[msg.sender] = msg.value * 10;
    }

    // allow transfers of tokens
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // clean up after ourselves
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}
```

# 풀이
---
본 풀이는 문제가 요구하는 정석 풀이는 아님을 알아두자. 우선 최초 컨트랙트 생성자가 컨트랙트 주소에 0.001 ether를 전송하고, 0.001 * 10에 해당하는 토큰을 얻은 이후 해당 컨트랙트의 주소를 잊어버림으로써 문제가 시작된다. 문제는 해당 컨트랙트에서 해당량의 이더를 인출하거나 소거하기를 요구한다.

필자는 최초 컨트랙트 생성자가 이더를 컨트랙트 주소에 전송하는 과정이 [etherscan](https://sepolia.etherscan.io/)에 기록되었을 것이라는 판단하에, 문제 인스턴스 주소를 검색해, 최초 컨트랙트의 주소를 찾아냈다.

문제 컨트랙트에는 `selfdestruct()`를 호출할 수 있는 `destroy()` 함수가 존재하며, `selfdestruct()`의 인자에 해당 컨트랙트 파괴 후 잔액을 받을 주소를 입력해야 한다. 따라서 공격 컨트랙트의 `constructor`에 해당 컨트랙트 주소를 입력 후 `callDestroy`에 필자의 주소를 입력하면 컨트랙트는 파괴되고 잔액은 필자의 주소로 전송된다.
