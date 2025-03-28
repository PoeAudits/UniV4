//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IPositionManager} from "lib/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "lib/v4-core/src/types/Currency.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";

import {TickMath} from "lib/v4-core/src/libraries/TickMath.sol";
import {IPermit2} from "lib/universal-router/lib/permit2/src/interfaces/IPermit2.sol";

import {PositionLibrary, CreatePoolParams, MintPositionParams} from "src/Libraries/PositionLibrary.sol";

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

// Adding liquidity to a pool on token deployment fails at sync step
// Requires an intermediary deployer contract to mint the initial liquidity position
contract TokenWithPoolAndLiquidityDeployer {
    using PositionLibrary for IPositionManager;
    TokenWithPoolAndLiquidity internal deployment;

    constructor(PoolInit memory init) {
        deployment = new TokenWithPoolAndLiquidity(init);

        deployment.approve(address(init.permit2), init.mintAmount);
        init.permit2.approve(
            address(deployment),
            address(init.positionManager),
            type(uint160).max,
            type(uint48).max
        );

        Currency thisCurrency = Currency.wrap(address(deployment));
        bool isTokenZero = thisCurrency < init.pairedCurrency ? true : false;

        PoolKey memory key = PoolKey({
            currency0: isTokenZero ? thisCurrency : init.pairedCurrency,
            currency1: isTokenZero ? init.pairedCurrency : thisCurrency,
            fee: init.lpFee,
            tickSpacing: init.tickSpacing,
            hooks: IHooks(init.hookContract)
        });
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

        init.positionManager.MintPosition(mintParams);
    }

    function getDeployment() external view returns (TokenWithPoolAndLiquidity) {
        return deployment;
    }
}

contract TokenWithPoolAndLiquidity is ERC20("TokenPoolLiquidity", "TPL") {
    using PositionLibrary for IPositionManager;

    IPositionManager internal immutable positionManager;
    IPoolManager internal immutable poolManager;

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

        // Mint initial amount to deployer contract
        _update(address(0), msg.sender, init.mintAmount);

        CreatePoolParams memory createParams = CreatePoolParams({
            key: key,
            startingPrice: init.startingPrice,
            hookData: init.hookDataInit
        });

        positionManager.CreatePool(createParams);
    }
}
