# 문제 코드
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Denial {
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address public constant owner = address(0xA9E);
    uint256 timeLastWithdrawn;
    mapping(address => uint256) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint256 amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value: amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```
> 이 컨트랙트는 시간이 지남에 따라 자금을 조금씩 인출할 수 있는 단순한 지갑입니다. 
> 파트너(Withdrawing partner)가 되면, 천천히 자금을 인출할 수 있습니다.
>
> 만약 컨트랙트에 여전히 자금이 남아 있고, 트랜잭션이 가스 1,000,000 이하일 때 
> withdraw() 함수 호출로 소유자가 자금 인출을 거부할 수 있다면 이 레벨을 완료할 수 있습니다.

# 풀이
---
## Denial of Service(DoS)
---
컨트랙트에서 DoS는 정상적인 함수 실행을 방해하는 것을 의미한다.

### Gas exhaustion
---
Gas exhausion은 실행 중 gas를 모두 소모하게 만들어 트랜잭션을 실패시키는 방식이다.

### Gas griefing
---
Gas griefing은 상대방의 트랜잭션이 실패하거나 비정상적으로 많은 비용을 쓰게 만드는 공격을 의미한다.

## 공격 과정
---
컨트랙트의 핵심 함수 `withdraw()`는 일정량의 자금은 `partner`와 `owner`에게 송금한다. 이 과정에서 `partner`에 대한 송금이 실패해도, `call` 메소드는 송금 결과값만 반환하고, `revert` 시키지는 않는다. 

하지만 `partner`에게 송금하는 과정에서 해당 컨트랙트의 모든 가스를 소모하게 되면 다음 명령인 `owner`에 대한 송금이 불가능해진다. 이를 토대로 입금이 발생하는 경우 `receive()`에서 무한 루프를 실행하는 공격 컨트랙트를 배포하고, 해당 주소를 `setWithdrawPartner()`함수의 인자로 넘기면 문제는 해결된다.
