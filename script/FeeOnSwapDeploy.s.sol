// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "test/base/BaseScript.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {TokenWithPoolAndLiquidity, TokenWithPoolAndLiquidityDeployer, PoolInit} from "src/TokenWithPoolAndLiquidity.sol";
import {FeeOnSwapHook} from "src/Hooks/FeeOnSwapHook.sol";
import {Currency} from "lib/v4-core/src/types/Currency.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";

contract FeeOnSwapDeploy is BaseScript, StdCheats {
    TokenWithPoolAndLiquidityDeployer internal deploy;
    TokenWithPoolAndLiquidity internal target;
    address internal _target;
    IHooks internal _hook;

    PoolKey internal key;
    bool internal isTokenZero;

    function run() public {
        IHooks hook = setupFeeOnSwap();
        PoolInit memory init = PoolInit({
            positionManager: positionManager,
            poolManager: poolManager,
            permit2: permit2,
            pairedCurrency: Currency.wrap(address(weth)),
            hookContract: hook,
            mintAmount: 1e27,
            lpFee: 3000,
            tickSpacing: 60,
            startingPrice: 79228162514264337593543950336, // 1 to 1
            hookDataInit: "",
            hookDataMint: ""
        });

        deploy = new TokenWithPoolAndLiquidityDeployer(init);

        target = deploy.getDeployment();
        _target = address(target);

        isTokenZero = Currency.wrap(_target) < init.pairedCurrency
            ? true
            : false;

        key = PoolKey({
            currency0: isTokenZero
                ? Currency.wrap(_target)
                : init.pairedCurrency,
            currency1: isTokenZero
                ? init.pairedCurrency
                : Currency.wrap(_target),
            fee: init.lpFee,
            tickSpacing: init.tickSpacing,
            hooks: IHooks(init.hookContract)
        });
    }

    function setupFeeOnSwap() internal virtual returns (IHooks hook) {
        // bytes memory args = abi.encode(poolManager);
        // StdCheats.deployCodeTo(
        //     "out/FeeOnSwapHook.sol/FeeOnSwapHook.json",
        //     args,
        //     _hook
        // );
        // console.log("Setup Hook Complete");
    }
}
