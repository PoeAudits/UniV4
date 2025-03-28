// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "lib/v4-periphery/src/interfaces/IPositionManager.sol";
import {LiquidityAmounts} from "lib/v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "lib/v4-core/src/libraries/TickMath.sol";
import {Actions} from "lib/v4-periphery/src/libraries/Actions.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {StateLibrary} from "lib/v4-core/src/libraries/StateLibrary.sol";
import {PositionInfo, PositionInfoLibrary} from "lib/v4-periphery/src/libraries/PositionInfoLibrary.sol";

struct CreatePoolParams {
    PoolKey key;
    uint160 startingPrice;
    bytes hookData;
}

struct MintPositionParams {
    IPoolManager poolManager;
    PoolKey key;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0;
    uint256 amount1;
    uint128 amount0Max;
    uint128 amount1Max;
    address recipient;
    uint48 deadline;
    bytes hookData;
}

struct IncreaseLiquidityParams {
    IPoolManager poolManager;
    uint256 tokenId;
    uint256 amount0;
    uint256 amount1;
    uint128 amount0Max;
    uint128 amount1Max;
    uint48 deadline;
    bytes hookData;
}

struct DecreaseLiquidityParams {
    IPoolManager poolManager;
    uint256 tokenId;
    uint256 amount0;
    uint256 amount1;
    uint128 amount0Min;
    uint128 amount1Min;
    address recipient;
    uint48 deadline;
    bytes hookData;
}
struct CollectFeesParams {
    IPoolManager poolManager;
    uint256 tokenId;
    address recipient;
    uint48 deadline;
    bytes hookData;
}

struct BurnParams {
    uint256 tokenId;
    uint128 amount0Min;
    uint128 amount1Min;
    uint48 deadline;
    bytes hookData;
}

library PositionLibrary {
    using StateLibrary for IPoolManager;
    using PositionInfoLibrary for PositionInfo;

    function CreatePool(
        IPositionManager positionManager,
        CreatePoolParams memory params
    ) internal {
        bytes[] memory createParams = new bytes[](1);

        createParams[0] = abi.encodeWithSelector(
            positionManager.initializePool.selector,
            params.key,
            params.startingPrice,
            params.hookData
        );

        positionManager.multicall(createParams);
    }

    function MintPosition(
        IPositionManager positionManager,
        MintPositionParams memory params
    ) internal {
        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION),
            uint8(Actions.SETTLE_PAIR)
        );
        (uint160 sqrtPriceX96, , , ) = params.poolManager.getSlot0(
            params.key.toId()
        );

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(params.tickLower),
            TickMath.getSqrtPriceAtTick(params.tickUpper),
            params.amount0,
            params.amount1
        );

        uint256 valueToPass = params.key.currency0.isAddressZero()
            ? params.amount0Max
            : 0;

        bytes[] memory mintParams = new bytes[](2);

        mintParams[0] = abi.encode(
            params.key,
            params.tickLower,
            params.tickUpper,
            liquidity,
            params.amount0Max,
            params.amount1Max,
            params.recipient,
            params.hookData
        );

        mintParams[1] = abi.encode(params.key.currency0, params.key.currency1);

        positionManager.modifyLiquidities{value: valueToPass}(
            abi.encode(actions, mintParams),
            params.deadline
        );
    }

    function IncreaseLiquidity(
        IPositionManager positionManager,
        IncreaseLiquidityParams memory params
    ) internal {
        require(params.amount0Max >= params.amount0, "Max lower than amount0");
        require(params.amount1Max >= params.amount1, "Max lower than amount1");

        bytes memory actions = abi.encodePacked(
            uint8(Actions.INCREASE_LIQUIDITY),
            uint8(Actions.CLOSE_CURRENCY),
            uint8(Actions.CLOSE_CURRENCY)
        );
        (PoolKey memory key, PositionInfo positionInfo) = positionManager
            .getPoolAndPositionInfo(params.tokenId);

        (uint160 sqrtPriceX96, , , ) = params.poolManager.getSlot0(key.toId());

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(positionInfo.tickLower()),
            TickMath.getSqrtPriceAtTick(positionInfo.tickUpper()),
            params.amount0,
            params.amount1
        );

        uint256 valueToPass = key.currency0.isAddressZero()
            ? params.amount0Max
            : 0;
        bytes[] memory modifyParams = new bytes[](3);

        modifyParams[0] = abi.encode(
            params.tokenId,
            liquidity,
            params.amount0Max,
            params.amount1Max,
            params.hookData
        );

        modifyParams[1] = abi.encode(key.currency0);
        modifyParams[2] = abi.encode(key.currency1);

        positionManager.modifyLiquidities{value: valueToPass}(
            abi.encode(actions, modifyParams),
            params.deadline
        );
    }

    function DecreaseLiquidity(
        IPositionManager positionManager,
        DecreaseLiquidityParams memory params
    ) internal {
        require(params.amount0Min <= params.amount0, "Max higher than amount0");
        require(params.amount1Min <= params.amount1, "Max higher than amount1");

        bytes memory actions = abi.encodePacked(
            uint8(Actions.DECREASE_LIQUIDITY),
            uint8(Actions.TAKE_PAIR)
        );
        (PoolKey memory key, PositionInfo positionInfo) = positionManager
            .getPoolAndPositionInfo(params.tokenId);

        (uint160 sqrtPriceX96, , , ) = params.poolManager.getSlot0(key.toId());

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(positionInfo.tickLower()),
            TickMath.getSqrtPriceAtTick(positionInfo.tickUpper()),
            params.amount0,
            params.amount1
        );

        bytes[] memory modifyParams = new bytes[](2);

        modifyParams[0] = abi.encode(
            params.tokenId,
            liquidity,
            params.amount0Min,
            params.amount1Min,
            params.hookData
        );

        modifyParams[1] = abi.encode(
            key.currency0,
            key.currency1,
            params.recipient
        );

        positionManager.modifyLiquidities(
            abi.encode(actions, modifyParams),
            params.deadline
        );
    }

    function CollectFees(
        IPositionManager positionManager,
        CollectFeesParams memory params
    ) internal returns (uint256 collected0, uint256 collected1) {
        (PoolKey memory key, ) = positionManager.getPoolAndPositionInfo(
            params.tokenId
        );
        uint256 balance0Before = key.currency0.balanceOf(params.recipient);
        uint256 balance1Before = key.currency1.balanceOf(params.recipient);

        DecreaseLiquidity(
            positionManager,
            DecreaseLiquidityParams({
                poolManager: params.poolManager,
                tokenId: params.tokenId,
                amount0: 0,
                amount1: 0,
                amount0Min: 0,
                amount1Min: 0,
                recipient: params.recipient,
                deadline: params.deadline,
                hookData: params.hookData
            })
        );

        collected0 = key.currency0.balanceOf(params.recipient) - balance0Before;
        collected1 = key.currency1.balanceOf(params.recipient) - balance1Before;
    }

    function BurnPosition(
        IPositionManager positionManager,
        BurnParams memory params
    ) internal {
        bytes memory actions = abi.encodePacked(uint8(Actions.BURN_POSITION));
        bytes[] memory burnParams = new bytes[](1);

        burnParams[0] = abi.encode(
            params.tokenId,
            params.amount0Min,
            params.amount1Min,
            params.hookData
        );

        positionManager.modifyLiquidities(
            abi.encode(actions, burnParams),
            params.deadline
        );
    }
}
