//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "lib/v4-core/src/libraries/Hooks.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "lib/v4-core/src/types/BeforeSwapDelta.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {BaseHook} from "lib/v4-periphery/src/utils/BaseHook.sol";

contract NormalLiquidityHook is BaseHook {
    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        // address(0xa00)
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: true,
                afterRemoveLiquidity: false,
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
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata
    ) internal override returns (bytes4) {
        int256 tickIndexLower = int256(params.tickLower) /
            int256(key.tickSpacing);
        int256 tickIndexUpper = int256(params.tickUpper) /
            int256(key.tickSpacing);

        uint256 dst = uint256(tickIndexUpper - tickIndexLower);
        bool hasCenter = dst % 2 == 1;

        return BaseHook.beforeAddLiquidity.selector;
    }

    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        revert HookNotImplemented();
    }
}
