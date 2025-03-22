// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "test/base/BaseScript.sol";
import "test/base/BaseImports.sol";

import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {TickMath} from "lib/v4-core/src/libraries/TickMath.sol";
import {Currency, CurrencyLibrary} from "lib/v4-core/src/types/Currency.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";

import {LiquidityAmounts} from "lib/v4-core/test/utils/LiquidityAmounts.sol";
import {PositionManager} from "lib/v4-periphery/src/PositionManager.sol";
import {Actions} from "lib/v4-periphery/src/libraries/Actions.sol";

import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";

import {StateLibrary} from "lib/v4-core/src/libraries/StateLibrary.sol";
import {Currency} from "lib/v4-core/src/types/Currency.sol";
import {PoolIdLibrary} from "lib/v4-core/src/types/PoolId.sol";

contract AddLiquidityToPool is BaseScript {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    function run(
        PoolKey memory poolKey,
        uint160 initialAmount,
        address recipient,
        bytes memory hookData
    ) public {
        tokenApprovals(poolKey, initialAmount);
        (uint160 currentPrice, , , ) = poolManager.getSlot0(poolKey.toId());

        int24 tickLower = (TickMath.MIN_TICK / poolKey.tickSpacing) *
            poolKey.tickSpacing;
        int24 tickUpper = ((TickMath.getTickAtSqrtPrice(currentPrice) /
            poolKey.tickSpacing) * poolKey.tickSpacing);

        // int24 tickLower = ((TickMath.getTickAtSqrtPrice(currentPrice) /
        //     poolKey.tickSpacing) * poolKey.tickSpacing) + poolKey.tickSpacing;
        // int24 tickUpper = (TickMath.MAX_TICK / poolKey.tickSpacing) *
        //     poolKey.tickSpacing;
        // Converts token amounts to liquidity units

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            currentPrice,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            0,
            initialAmount
        );

        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION),
            uint8(Actions.SETTLE_PAIR)
        );
        bytes[] memory mintParams = new bytes[](2);
        mintParams[0] = abi.encode(
            poolKey,
            tickLower,
            tickUpper,
            liquidity,
            0,
            initialAmount,
            recipient,
            hookData
        );
        mintParams[1] = abi.encode(poolKey.currency0, poolKey.currency1);

        bytes[] memory params = new bytes[](1);
        params[0] = abi.encodeWithSelector(
            positionManager.modifyLiquidities.selector,
            abi.encode(actions, mintParams),
            block.timestamp + 60
        );
        console.logBytes(params[0]);

        positionManagerMulticall(params);
    }

    function tokenApprovals(
        PoolKey memory poolKey,
        uint160 initialAmount
    ) internal BroadcastIfNotTest {
        IERC20(address(Currency.unwrap(poolKey.currency1))).approve(
            address(permit2),
            initialAmount
        );
        permit2.approve(
            address(Currency.unwrap(poolKey.currency1)),
            address(positionManager),
            initialAmount,
            type(uint48).max
        );
    }

    function positionManagerMulticall(
        bytes[] memory params
    ) internal BroadcastIfNotTest {
        positionManager.multicall(params);
    }
}
