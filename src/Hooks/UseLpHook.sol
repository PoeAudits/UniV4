//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {console2 as console} from "lib/forge-std/src/console2.sol";
import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "lib/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {BaseHook} from "lib/v4-periphery/src/utils/BaseHook.sol";
import {BalanceDelta, toBalanceDelta} from "lib/v4-core/src/types/BalanceDelta.sol";

contract UseLpHook is BaseHook {
    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    uint128 public constant LIQUIDITY_FEE = 543; // 543/10000 = 5.43%
    uint128 public constant SWAP_FEE_BIPS = 123; // 123/10000 = 1.23%
    uint128 public constant TOTAL_BIPS = 10000;

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        // address(0x503)
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: true,
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: true,
                afterRemoveLiquidityReturnDelta: true
            });
    }

    // function _beforeAddLiquidity(
    //     address,
    //     PoolKey calldata,
    //     IPoolManager.ModifyLiquidityParams calldata,
    //     bytes calldata
    // ) internal override returns (bytes4) {
    //     console.log("Before Add Liquidity");
    //     return (BaseHook.beforeAddLiquidity.selector);
    // }

    // function _beforeRemoveLiquidity(
    //     address,
    //     PoolKey calldata,
    //     IPoolManager.ModifyLiquidityParams calldata,
    //     bytes calldata
    // ) internal override returns (bytes4) {
    //     return (BaseHook.beforeRemoveLiquidity.selector);
    // }

    function _afterAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta delta,
        BalanceDelta feeDelta,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        console.log("After Add Liquidity");

        console.log("Amount 0: ", delta.amount0());
        console.log("Amount 1: ", delta.amount1());
        console.log("Fees 0: ", feeDelta.amount0());
        console.log("Fees 1: ", feeDelta.amount1());
        console.log("");
        require(delta.amount0() <= 0 && delta.amount1() <= 0, "Positive Delta");

        uint128 feeAmount0 = (uint128(-delta.amount0()) * LIQUIDITY_FEE) /
            TOTAL_BIPS;
        uint128 feeAmount1 = (uint128(-delta.amount1()) * LIQUIDITY_FEE) /
            TOTAL_BIPS;
        console.log("Fee Amount 0: ", feeAmount0);
        console.log("Fee Amount 1: ", feeAmount1);
        console.log("");

        if (feeAmount0 != 0) {
            // poolManager.mint(address(this), key.currency0.toId(), feeAmount0);
            poolManager.take(key.currency0, address(this), feeAmount0);
        }
        if (feeAmount1 != 0) {
            // poolManager.mint(address(this), key.currency1.toId(), feeAmount1);
            poolManager.take(key.currency1, address(this), feeAmount1);
        }

        return (
            IHooks.afterAddLiquidity.selector,
            toBalanceDelta(int128(feeAmount0), int128(feeAmount1))
        );
    }

    function _afterRemoveLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        console.log("After Remove Liquidity");
        console.log("Amount 0: ", delta.amount0());
        console.log("Amount 1: ", delta.amount1());
        console.log("Fees 0: ", feesAccrued.amount0());
        console.log("Fees 1: ", feesAccrued.amount1());
        console.log("");
        require(delta.amount0() >= 0 && delta.amount1() >= 0, "Positive Delta");

        uint128 feeAmount0 = (uint128(delta.amount0()) * LIQUIDITY_FEE) /
            TOTAL_BIPS;
        uint128 feeAmount1 = (uint128(delta.amount1()) * LIQUIDITY_FEE) /
            TOTAL_BIPS;

        poolManager.take(key.currency0, address(this), feeAmount0);
        poolManager.take(key.currency1, address(this), feeAmount1);

        return (
            IHooks.afterRemoveLiquidity.selector,
            toBalanceDelta(int128(feeAmount0), int128(feeAmount1))
        );
    }
}
