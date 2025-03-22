//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "lib/v4-core/src/libraries/Hooks.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "lib/v4-core/src/types/BeforeSwapDelta.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {BaseHook} from "lib/v4-periphery/src/utils/BaseHook.sol";

contract FeeOnSwapHook is BaseHook {
    uint256 internal constant HOOK_FEE_PERCENTAGE = 200;
    uint256 internal constant FEE_DENOMINATOR = 10000;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        // address(0x88)
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: true,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _beforeSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        uint256 swapAmount = params.amountSpecified < 0
            ? uint256(-params.amountSpecified)
            : uint256(params.amountSpecified);
        uint256 feeAmount = (swapAmount * HOOK_FEE_PERCENTAGE) /
            FEE_DENOMINATOR;

        BeforeSwapDelta returnDelta = toBeforeSwapDelta(
            int128(int256(feeAmount)),
            0
        );

        poolManager.mint(address(this), key.currency1.toId(), feeAmount);
        return (BaseHook.beforeSwap.selector, returnDelta, 0);
    }
}
