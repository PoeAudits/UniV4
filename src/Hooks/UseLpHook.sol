//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "lib/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {BaseHook} from "lib/v4-periphery/src/utils/BaseHook.sol";
import {BalanceDelta, toBalanceDelta} from "lib/v4-core/src/types/BalanceDelta.sol";

contract UseLpHook is BaseHook {
    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        // address(0xf00)
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: true,
                afterRemoveLiquidity: true,
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        return (BaseHook.beforeAddLiquidity.selector);
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        BalanceDelta balanceDelta = toBalanceDelta(0, 0);
        return (BaseHook.beforeRemoveLiquidity.selector, balanceDelta);
    }

    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        return (BaseHook.beforeRemoveLiquidity.selector);
    }

    function _afterRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        BalanceDelta balanceDelta = toBalanceDelta(0, 0);
        return (BaseHook.beforeRemoveLiquidity.selector, balanceDelta);
    }
}
