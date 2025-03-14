// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "lib/v4-periphery/src/interfaces/IPositionManager.sol";
import {UniversalRouter} from "lib/universal-router/contracts/UniversalRouter.sol";

import {IPermit2} from "lib/universal-router/lib/permit2/src/interfaces/IPermit2.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract BaseImports {
    IPoolManager internal immutable poolManager =
        IPoolManager(0x000000000004444c5dc75cB358380D2e3dE08A90);
    IPositionManager internal immutable positionManager =
        IPositionManager(0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e);
    UniversalRouter internal immutable router =
        UniversalRouter(payable(0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af));
    IPermit2 internal immutable permit2 =
        IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IERC20 internal immutable weth =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
}
