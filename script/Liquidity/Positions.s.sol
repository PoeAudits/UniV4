// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "test/base/BaseScript.sol";

import {LiquidityAmounts} from "lib/v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "lib/v4-core/src/libraries/TickMath.sol";
import {Actions} from "lib/v4-periphery/src/libraries/Actions.sol";
import {IPermit2} from "lib/universal-router/lib/permit2/src/interfaces/IPermit2.sol";
import {Currency, CurrencyLibrary} from "lib/v4-core/src/types/Currency.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {StateLibrary} from "lib/v4-core/src/libraries/StateLibrary.sol";
import {PositionInfo, PositionInfoLibrary} from "lib/v4-periphery/src/libraries/PositionInfoLibrary.sol";

contract Positions is BaseScript {
    using StateLibrary for IPoolManager;
    using PositionInfoLibrary for PositionInfo;

    function run() public {}

    function MintPosition(
        PoolKey memory key,
        MintPositionParams memory mintParams
    ) public {
        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION),
            uint8(Actions.SETTLE_PAIR)
        );
        (uint160 sqrtPriceX96, , , ) = poolManager.getSlot0(key.toId());

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(mintParams.tickLower),
            TickMath.getSqrtPriceAtTick(mintParams.tickUpper),
            mintParams.amount0,
            mintParams.amount1
        );

        uint256 valueToPass = key.currency0.isAddressZero()
            ? mintParams.amount0Max
            : 0;

        bytes[] memory params = new bytes[](2);

        params[0] = abi.encode(
            key,
            mintParams.tickLower,
            mintParams.tickUpper,
            liquidity,
            mintParams.amount0Max,
            mintParams.amount1Max,
            mintParams.recipient,
            mintParams.hookData
        );

        params[1] = abi.encode(key.currency0, key.currency1);

        positionManager.modifyLiquidities{value: valueToPass}(
            abi.encode(actions, params),
            block.timestamp + 60
        );
    }

    function IncreaseLiquidity(
        IncreaseLiquidityParams memory liquidityParams
    ) public {
        require(
            liquidityParams.amount0Max >= liquidityParams.amount0,
            "Max lower than amount0"
        );
        require(
            liquidityParams.amount1Max >= liquidityParams.amount1,
            "Max lower than amount1"
        );

        bytes memory actions = abi.encodePacked(
            uint8(Actions.INCREASE_LIQUIDITY),
            uint8(Actions.CLOSE_CURRENCY),
            uint8(Actions.CLOSE_CURRENCY)
        );
        (PoolKey memory key, PositionInfo positionInfo) = positionManager
            .getPoolAndPositionInfo(liquidityParams.tokenId);

        (uint160 sqrtPriceX96, , , ) = poolManager.getSlot0(key.toId());

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(positionInfo.tickLower()),
            TickMath.getSqrtPriceAtTick(positionInfo.tickUpper()),
            liquidityParams.amount0,
            liquidityParams.amount1
        );

        uint256 valueToPass = key.currency0.isAddressZero()
            ? liquidityParams.amount0Max
            : 0;
        bytes[] memory params = new bytes[](3);

        params[0] = abi.encode(
            liquidityParams.tokenId,
            liquidity,
            liquidityParams.amount0Max,
            liquidityParams.amount1Max,
            liquidityParams.hookData
        );

        params[1] = abi.encode(key.currency0);
        params[2] = abi.encode(key.currency1);

        positionManager.modifyLiquidities{value: valueToPass}(
            abi.encode(actions, params),
            block.timestamp + 60
        );
    }

    function DecreaseLiquidity(
        DecreaseLiquidityParams memory liquidityParams
    ) internal {
        require(
            liquidityParams.amount0Min <= liquidityParams.amount0,
            "Max higher than amount0"
        );
        require(
            liquidityParams.amount1Min <= liquidityParams.amount1,
            "Max higher than amount1"
        );

        bytes memory actions = abi.encodePacked(
            uint8(Actions.DECREASE_LIQUIDITY),
            uint8(Actions.TAKE_PAIR)
        );
        (PoolKey memory key, PositionInfo positionInfo) = positionManager
            .getPoolAndPositionInfo(liquidityParams.tokenId);

        (uint160 sqrtPriceX96, , , ) = poolManager.getSlot0(key.toId());

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(positionInfo.tickLower()),
            TickMath.getSqrtPriceAtTick(positionInfo.tickUpper()),
            liquidityParams.amount0,
            liquidityParams.amount1
        );

        bytes[] memory params = new bytes[](2);

        params[0] = abi.encode(
            liquidityParams.tokenId,
            liquidity,
            liquidityParams.amount0Min,
            liquidityParams.amount1Min,
            liquidityParams.hookData
        );

        params[1] = abi.encode(
            key.currency0,
            key.currency1,
            liquidityParams.recipient
        );

        positionManager.modifyLiquidities(
            abi.encode(actions, params),
            block.timestamp + 60
        );
    }

    function CollectFees(
        CollectFeesParams memory collectParams
    ) internal returns (uint256 collected0, uint256 collected1) {
        (PoolKey memory key, ) = positionManager.getPoolAndPositionInfo(
            collectParams.tokenId
        );
        uint256 balance0Before = key.currency0.balanceOf(
            collectParams.recipient
        );
        uint256 balance1Before = key.currency1.balanceOf(
            collectParams.recipient
        );

        DecreaseLiquidity(
            DecreaseLiquidityParams({
                tokenId: collectParams.tokenId,
                amount0: 0,
                amount1: 0,
                amount0Min: 0,
                amount1Min: 0,
                recipient: collectParams.recipient,
                hookData: collectParams.hookData
            })
        );

        collected0 =
            key.currency0.balanceOf(collectParams.recipient) -
            balance0Before;
        collected1 =
            key.currency1.balanceOf(collectParams.recipient) -
            balance1Before;
    }

    function BurnPosition(BurnParams memory burnParams) internal {
        bytes memory actions = abi.encodePacked(uint8(Actions.BURN_POSITION));
        bytes[] memory params = new bytes[](1);

        params[0] = abi.encode(
            burnParams.tokenId,
            burnParams.amount0Min,
            burnParams.amount1Min,
            burnParams.hookData
        );

        positionManager.modifyLiquidities(
            abi.encode(actions, params),
            block.timestamp + 60
        );
    }
}
