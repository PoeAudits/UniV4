// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";
import "test/BaseImports.sol";
import {TokenWithPoolAndLiquidity} from "src/TokenWithPoolAndLiquidity.sol";
import {Currency} from "lib/v4-core/src/types/Currency.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";

contract TokenWithPoolAndLiquidityDeploy is Script, BaseImports {
    TokenWithPoolAndLiquidity internal target;
    address internal _target;

    function run() public {
        IHooks hook = setupHook();
        TokenWithPoolAndLiquidity.PoolInit
            memory init = TokenWithPoolAndLiquidity.PoolInit({
                positionManager: positionManager,
                pairedCurrency: Currency.wrap(address(weth)),
                hookContract: hook,
                mintAmount: 1e27,
                lpFee: 3000,
                tickSpacing: 60,
                startingPrice: 79228162514264337593543950336,
                hookData: ""
            });

        target = new TokenWithPoolAndLiquidity(init);
    }

    function setupHook() internal virtual returns (IHooks hook) {
        return IHooks(address(0x0));
    }
}
