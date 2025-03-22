// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "lib/forge-std/src/Script.sol";
import "test/base/BaseImports.sol";
import "test/base/BaseParams.sol";

contract BaseScript is Script, BaseImports {
    modifier BroadcastIfNotTest() {
        (VmSafe.CallerMode caller, , ) = vm.readCallers();
        if (caller != VmSafe.CallerMode.RecurrentPrank) {
            vm.startBroadcast();
        }
        _;

        if (caller != VmSafe.CallerMode.RecurrentPrank) {
            vm.stopBroadcast();
        }
    }
}
