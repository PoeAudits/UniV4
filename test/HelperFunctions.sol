//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Setup.sol";

contract HelperFunctions is Setup {
    function Warp(uint256 timestamp) internal {
        vm.warp(vm.getBlockTimestamp() + timestamp);
        vm.roll(vm.getBlockNumber() + (timestamp / 12));
        console.log("Warped 24 Hours");
        console.log("");
    }
}
