# 문제 코드
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;
    // Sets the function signature for delegatecall
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }

    // set the time for timezone 1
    function setFirstTime(uint256 _timeStamp) public {
        timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }

    // set the time for timezone 2
    function setSecondTime(uint256 _timeStamp) public {
        timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}
```

# 풀이
---
풀이를 설명하기 앞서 솔리디티의 EVM storage가 어떻게 관리되는지 살펴보자. EVM storage는 각 상태변수에 접근할 때 각 변수의 이름이 아닌 슬롯 번호를 사용한다. 슬롯 번호는 변수가 선언되는 순서에 따라 매겨지며, 각 슬롯의 최대 크기는 32 bytes다. 만약 하나의 슬롯이 모두 채워지지 않는 경우에는 두 개 이상의 변수가 하나의 슬롯에 포함될 수 있다.

이제 문제를 살펴보자. `Preservation` 컨트랙트는 `LibraryContract`를 라이브러리로 사용하며, `delegatecall`을 사용하여 `setTime()`을 호출한다. 이때 `delegatecall`을 사용하여 다른 컨트랙트의 함수를 호출하는 경우 **Context**는 호출자의 정보로 계속 유지된다. 즉, 다른 라이브러리의 함수를 호출하더라도 호출자의 슬롯 정보를 유지한다는 것이다.

따라서 `LibraryContract`의 `setTime()` 함수가 변경하는 `storedTime`의 경우 `slot 0`을 가리키므로 호출자 컨트랙트인 `Preservation`의 `slot 0`인 `timeZone1Library`의 값이 `_time`으로 덮히게 된다.

위 메커니즘에 따라 첫 `setFirstTime` 호출에서 `_timeStamp`의 값을 공격 컨트랙트의 주소로 설정하고, 두 번째 `setFirstTime` 호출에서 `setTime()` 함수를 호출해 `ower`의 값을 공격자의 주소로 설정하면, 소유권을 탈취하게 된다. 이때 `Preservation`의 슬롯 순서를 고려해, 공격 컨트랙트에 더미 변수 두 개를 `owner` 변수 앞에 선언해야한다.
