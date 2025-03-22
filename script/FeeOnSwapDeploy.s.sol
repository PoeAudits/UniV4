// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "test/base/BaseScript.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {TokenWithPoolAndLiquidity} from "src/TokenWithPoolAndLiquidity.sol";
import {FeeOnSwapHook} from "src/Hooks/FeeOnSwapHook.sol";
import {Currency} from "lib/v4-core/src/types/Currency.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";

contract FeeOnSwapDeploy is BaseScript, StdCheats {
    TokenWithPoolAndLiquidity internal target;
    address internal _target;
    IHooks internal _hook;

    function run() public {
        IHooks hook = setupFeeOnSwap();
        TokenWithPoolAndLiquidity.PoolInit memory init = TokenWithPoolAndLiquidity
            .PoolInit({
                positionManager: positionManager,
                permit2: permit2,
                pairedCurrency: Currency.wrap(address(weth)),
                hookContract: hook,
                mintAmount: 1e27,
                lpFee: 3000,
                tickSpacing: 60,
                startingPrice: 79228162514264337593543950336, // 1 to 1
                hookDataInit: "",
                hookDataModify: ""
            });

        target = new TokenWithPoolAndLiquidity(init);
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
