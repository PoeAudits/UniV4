// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {
    struct Vars {
        uint256 counter_number;
    }

    Vars internal _before;
    Vars internal _after;

    modifier updateGhosts() {
        __before();
        _;
        __after();
    }

    modifier updateUser(address user) {
        __before(user);
        _;
        __after(user);
    }

    function __before(address user) internal {
        __before();
    }

    function __after(address user) internal {
        __after();
    }

    function __before() internal {}

    function __after() internal {}
}
