//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {console2 as console} from "lib/forge-std/src/Test.sol";

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IPositionManager} from "lib/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "lib/v4-core/src/types/Currency.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";

import {LiquidityAmounts} from "lib/v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "lib/v4-core/src/libraries/TickMath.sol";
import {Actions} from "lib/v4-periphery/src/libraries/Actions.sol";
import {IPermit2} from "lib/universal-router/lib/permit2/src/interfaces/IPermit2.sol";

import {PositionLibrary, CreatePoolParams, MintPositionParams} from "src/Libraries/PositionLibrary.sol";

contract TokenWithPoolAndLiquidity is ERC20("TokenPoolLiquidity", "TPL") {
    using PositionLibrary for IPositionManager;

    IPositionManager internal immutable positionManager;
    IPoolManager internal immutable poolManager;

    struct PoolInit {
        IPositionManager positionManager;
        IPoolManager poolManager;
        IPermit2 permit2;
        Currency pairedCurrency;
        IHooks hookContract;
        uint256 mintAmount;
        uint24 lpFee;
        int24 tickSpacing;
        uint160 startingPrice;
        bytes hookDataInit;
        bytes hookDataMint;
    }

    constructor(PoolInit memory init) {
        positionManager = init.positionManager;
        poolManager = init.poolManager;

        Currency thisCurrency = Currency.wrap(address(this));
        bool isTokenZero = thisCurrency < init.pairedCurrency ? true : false;

        PoolKey memory key = PoolKey({
            currency0: isTokenZero ? thisCurrency : init.pairedCurrency,
            currency1: isTokenZero ? init.pairedCurrency : thisCurrency,
            fee: init.lpFee,
            tickSpacing: init.tickSpacing,
            hooks: IHooks(init.hookContract)
        });

        _update(address(0), address(this), init.mintAmount);
        _update(address(0), msg.sender, init.mintAmount);

        _approve(address(this), address(init.permit2), init.mintAmount);
        _approve(msg.sender, address(init.permit2), init.mintAmount);

        init.permit2.approve(
            address(this),
            address(init.positionManager),
            type(uint160).max,
            type(uint48).max
        );

        int24 tickLower;
        int24 tickUpper;

        if (isTokenZero) {
            tickLower =
                ((TickMath.getTickAtSqrtPrice(init.startingPrice) /
                    key.tickSpacing) * key.tickSpacing) +
                key.tickSpacing;
            tickUpper = (TickMath.MAX_TICK / key.tickSpacing) * key.tickSpacing;
        } else {
            tickLower = (TickMath.MIN_TICK / key.tickSpacing) * key.tickSpacing;
            tickUpper =
                ((TickMath.getTickAtSqrtPrice(init.startingPrice) /
                    key.tickSpacing) * key.tickSpacing) -
                key.tickSpacing;
        }

        CreatePoolParams memory createParams = CreatePoolParams({
            key: key,
            startingPrice: init.startingPrice,
            hookData: init.hookDataInit
        });

        MintPositionParams memory mintParams = MintPositionParams({
            poolManager: init.poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0: isTokenZero ? init.mintAmount : 0,
            amount1: isTokenZero ? 0 : init.mintAmount,
            amount0Max: isTokenZero ? uint128(init.mintAmount) : 0,
            amount1Max: isTokenZero ? 0 : uint128(init.mintAmount),
            recipient: msg.sender,
            deadline: uint48(block.timestamp + 60),
            hookData: init.hookDataMint
        });

        positionManager.CreatePool(createParams);
        positionManager.MintPosition(mintParams);
    }

    function _mintLiquidity(
        PoolKey memory key,
        PoolInit memory init,
        bool isTokenZero
    ) private view returns (bytes memory, bytes[] memory) {
        int24 tickLower;
        int24 tickUpper;

        if (isTokenZero) {
            tickLower =
                ((TickMath.getTickAtSqrtPrice(init.startingPrice) /
                    key.tickSpacing) * key.tickSpacing) +
                key.tickSpacing;
            tickUpper = (TickMath.MAX_TICK / key.tickSpacing) * key.tickSpacing;
        } else {
            tickLower = (TickMath.MIN_TICK / key.tickSpacing) * key.tickSpacing;
            tickUpper =
                ((TickMath.getTickAtSqrtPrice(init.startingPrice) /
                    key.tickSpacing) * key.tickSpacing) -
                key.tickSpacing;
        }

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            init.startingPrice,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            isTokenZero ? init.mintAmount : 0,
            isTokenZero ? 0 : init.mintAmount
        );

        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION),
            uint8(Actions.SETTLE_PAIR)
        );

        bytes[] memory mintParams = new bytes[](2);
        mintParams[0] = abi.encode(
            key,
            tickLower,
            tickUpper,
            liquidity,
            isTokenZero ? init.mintAmount : 0,
            isTokenZero ? 0 : init.mintAmount,
            msg.sender,
            init.hookDataMint
        );

        mintParams[1] = abi.encode(key.currency0, key.currency1);
        return (actions, mintParams);
    }
}

// constructor(PoolInit memory init) {
//     Currency thisCurrency = Currency.wrap(address(this));
//     bool isTokenZero = thisCurrency < init.pairedCurrency ? true : false;
//
//     PoolKey memory key = PoolKey({
//         currency0: isTokenZero ? thisCurrency : init.pairedCurrency,
//         currency1: isTokenZero ? init.pairedCurrency : thisCurrency,
//         fee: init.lpFee,
//         tickSpacing: init.tickSpacing,
//         hooks: IHooks(init.hookContract)
//     });
//
//     bytes[] memory params = new bytes[](1);
//
//     params[0] = abi.encodeWithSelector(
//         init.positionManager.initializePool.selector,
//         key,
//         init.startingPrice,
//         init.hookDataInit
//     );
//
//     (bytes memory actions, bytes[] memory mintParams) = _mintLiquidity(
//         key,
//         init,
//         isTokenZero
//     );
//
//     // params[1] = abi.encodeWithSelector(
//     //     init.positionManager.modifyLiquidities.selector,
//     //     abi.encode(actions, mintParams),
//     //     block.timestamp + 60
//     // );
//
//     // Mint this contract initial amount
//     // _update(address(0), msg.sender, init.mintAmount);
//     //
//     // _approve(msg.sender, address(init.permit2), init.mintAmount);
//     // _approve(msg.sender, address(init.positionManager), init.mintAmount);
//     // init.permit2.approve(
//     //     address(this),
//     //     address(init.positionManager),
//     //     type(uint160).max,
//     //     type(uint48).max
//     // );
//     _update(address(0), address(this), init.mintAmount);
//
//     _approve(address(this), address(init.permit2), init.mintAmount);
//     init.permit2.approve(
//         address(this),
//         address(init.positionManager),
//         type(uint160).max,
//         type(uint48).max
//     );
//
//     // console.logBytes(params[1]);
//
//     init.positionManager.multicall(params);
//     init.positionManager.modifyLiquidities(
//         abi.encode(actions, mintParams),
//         block.timestamp + 600
//     );
// }
