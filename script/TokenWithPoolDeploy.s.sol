// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "test/base/BaseScript.sol";
import {TokenWithPool, PoolInit} from "src/TokenWithPool.sol";
import {Currency} from "lib/v4-core/src/types/Currency.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";

contract TokenWithPoolDeploy is BaseScript {
    TokenWithPool internal target;
    address internal _target;
    PoolKey internal key;
    bool internal isTokenZero;

    function run(address deployer) public {
        IHooks hook = setupHook();

        PoolInit memory init = PoolInit({
            positionManager: positionManager,
            pairedCurrency: Currency.wrap(address(weth)),
            hookContract: hook,
            lpFee: 3000,
            tickSpacing: 60,
            startingPrice: 79228162514264337593543950336,
            hookData: ""
        });

        vm.prank(deployer);
        target = new TokenWithPool(init);

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

    function setupHook() internal virtual returns (IHooks hook) {
        return IHooks(address(0x0));
    }
}
