// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "test/base/BaseScript.sol";
import {TokenWithPool} from "src/TokenWithPool.sol";
import {Currency} from "lib/v4-core/src/types/Currency.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";

contract TokenWithPoolDeploy is BaseScript {
    TokenWithPool internal target;
    address internal _target;

    function run() public {
        IHooks hook = setupHook();
        TokenWithPool.PoolInit memory init = TokenWithPool.PoolInit({
            positionManager: positionManager,
            pairedCurrency: Currency.wrap(address(weth)),
            hookContract: hook,
            lpFee: 3000,
            tickSpacing: 60,
            startingPrice: 79228162514264337593543950336,
            hookData: ""
        });

        target = new TokenWithPool(init);
    }

    function setupHook() internal virtual returns (IHooks hook) {
        return IHooks(address(0x0));
    }
}
