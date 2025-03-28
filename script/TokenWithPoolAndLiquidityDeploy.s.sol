// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "test/base/BaseScript.sol";
import {TokenWithPoolAndLiquidity} from "src/TokenWithPoolAndLiquidity.sol";
import {Currency} from "lib/v4-core/src/types/Currency.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";

contract TokenWithPoolAndLiquidityDeploy is BaseScript {
    TokenWithPoolAndLiquidity internal target;
    address internal _target;

    PoolKey internal key;
    bool internal isTokenZero;

    function run(address deployer) public {
        IHooks hook = setupHook();
        TokenWithPoolAndLiquidity.PoolInit memory init = TokenWithPoolAndLiquidity
            .PoolInit({
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

        address deployment = vm.computeCreateAddress(
            deployer,
            vm.getNonce(deployer)
        );
        console.log("Expected Deployment: ", deployment);

        vm.startPrank(deployer);
        init.permit2.approve(
            deployment,
            address(init.positionManager),
            uint160(init.mintAmount),
            uint48(vm.getBlockTimestamp() + 60)
        );

        init.permit2.approve(
            deployment,
            address(router),
            uint160(init.mintAmount),
            uint48(vm.getBlockTimestamp() + 60)
        );
        init.permit2.approve(
            deployment,
            0x000000000004444c5dc75cB358380D2e3dE08A90,
            uint160(init.mintAmount),
            uint48(vm.getBlockTimestamp() + 60)
        );
        vm.stopPrank();

        vm.prank(deployer);
        target = new TokenWithPoolAndLiquidity(init);
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
