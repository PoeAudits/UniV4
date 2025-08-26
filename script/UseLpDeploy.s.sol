// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "test/base/BaseScript.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {TokenWithPool, Init} from "src/TokenWithPool.sol";
import {UseLpHook} from "src/Hooks/UseLpHook.sol";
import {Currency} from "lib/v4-core/src/types/Currency.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";

contract UseLpDeploy is BaseScript, StdCheats {
    TokenWithPool internal target;
    address internal _target;
    IHooks internal _hook = IHooks(address(0x503));

    PoolKey internal key;
    bool internal isTokenZero;

    function run(address _deployer) public {
        IHooks hook = setupUseLpHook();
        Init memory init = Init({
            positionManager: positionManager,
            pairedCurrency: Currency.wrap(address(weth)),
            hookContract: hook,
            lpFee: 3000,
            tickSpacing: 60,
            startingPrice: 79228162514264337593543950336, // 1 to 1
            hookData: ""
        });
        // Init memory init = Init({
        //     positionManager: positionManager,
        //     poolManager: poolManager,
        //     permit2: permit2,
        //     pairedCurrency: Currency.wrap(address(weth)),
        //     hookContract: hook,
        //     mintAmount: 1e27,
        //     lpFee: 3000,
        //     tickSpacing: 60,
        //     startingPrice: 79228162514264337593543950336, // 1 to 1
        //     hookDataInit: "",
        //     hookDataMint: ""
        // });

        vm.prank(_deployer);
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

    function setupUseLpHook() internal virtual returns (IHooks hook) {
        bytes memory args = abi.encode(poolManager);
        StdCheats.deployCodeTo(
            "out/UseLpHook.sol/UseLpHook.json",
            args,
            address(_hook)
        );
        console.log("Setup Hook Complete");
        return IHooks(_hook);
    }
}
