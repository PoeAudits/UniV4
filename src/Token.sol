//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {console2 as console} from "lib/forge-std/src/Test.sol";

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20("Token", "T") {}
