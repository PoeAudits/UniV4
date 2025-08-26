// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/TokenWithPool.sol";
import {console2 as console} from "lib/forge-std/src/Test.sol";

struct Vars {
    uint256 counter_number;
}

contract Harness is TokenWithPool {
    constructor(Init memory init) TokenWithPool(init) {}
}
