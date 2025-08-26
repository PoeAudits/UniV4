// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {Harness, Init} from "test/recon/Harness.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";

// Helpers
import {Utils} from "@recon/Utils.sol";

// Deps

import {DeployUniV4} from "test/DeployUniV4.sol";
import {PoolManager} from "lib/v4-core/src/PoolManager.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";

abstract contract Setup is
    BaseSetup,
    ActorManager,
    AssetManager,
    Utils,
    DeployUniV4
{
    Harness target;
    // Permit2 permit2;
    // PositionManager positionManager;

    IHooks hook = IHooks(address(0));

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        DeployUniV4.deployUniswapV4();
        // deployFreshManagerAndRouters();

        // New Actor, beside address(this)
        _addActor(address(0x411c3));
        address pairedToken = _newAsset(18); // New 18 decimals token

        // Init memory init = Init({
        //     positionManager: positionManager,
        //     pairedCurrency: Currency.wrap(pairedToken),
        //     hookContract: hook,
        //     lpFee: 3000,
        //     tickSpacing: 60,
        //     startingPrice: 79228162514264337593543950336,
        //     hookData: ""
        // });
        // target = new Harness(init);

        // Mints to all actors and approves allowances to the counter
        address[] memory approvalArray = new address[](10);
        approvalArray[0] = address(target);
        approvalArray[1] = address(manager);
        approvalArray[2] = address(swapRouter);
        approvalArray[4] = address(modifyLiquidityRouter);
        approvalArray[5] = address(donateRouter);
        approvalArray[6] = address(takeRouter);
        approvalArray[7] = address(claimsRouter);
        approvalArray[8] = address(nestedActionRouter);
        approvalArray[9] = address(actionsRouter);
        _finalizeAssetDeployment(_getActors(), approvalArray, type(uint88).max);
    }

    /// === MODIFIERS === ///
    /// Prank admin and actor

    modifier asAdmin() {
        vm.prank(address(this));
        _;
    }

    modifier asActor() {
        vm.prank(address(_getActor()));
        _;
    }
}
