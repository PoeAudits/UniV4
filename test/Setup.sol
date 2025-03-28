//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {StdCheats, Test, console2 as console} from "lib/forge-std/src/Test.sol";

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Commands, UniversalRouter} from "lib/universal-router/contracts/UniversalRouter.sol";
import {IPermit2} from "lib/universal-router/lib/permit2/src/interfaces/IPermit2.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "lib/v4-periphery/src/interfaces/IPositionManager.sol";
import {Currency, CurrencyLibrary} from "lib/v4-core/src/types/Currency.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";

// import {TokenWithPoolDeploy} from "script/TokenWithPoolDeploy.s.sol";
//
// contract Setup is Test, TokenWithPoolDeploy {
import {TokenWithPoolAndLiquidityDeploy} from "script/TokenWithPoolAndLiquidityDeploy.s.sol";

contract Setup is Test, TokenWithPoolAndLiquidityDeploy {
    address internal _hook = address(0x1088);

    address _alice = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address _bob = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    address _carl = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
    address _deployer = address(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);

    mapping(address => string) names;

    function setUp() public virtual {
        vm.createSelectFork("localhost");

        super.run(_deployer);

        vm.prank(_alice);
        address(weth).call{value: 1e18}("");
        vm.prank(_bob);
        address(weth).call{value: 1e18}("");

        setupNamesAndLabels();
    }

    function testSetup() public pure {
        console.log("Success!");
    }

    function setupNamesAndLabels() private {
        // vm.label(address(target), "Target");

        names[_deployer] = "Deployer";
        names[_alice] = "Alice";
        names[_bob] = "Bob";
    }

    // function setupFeeOnSwap() internal override returns (IHooks) {
    //     bytes memory args = abi.encode(poolManager);
    //     StdCheats.deployCodeTo(
    //         "out/FeeOnSwapHook.sol/FeeOnSwapHook.json",
    //         args,
    //         _hook
    //     );
    //     console.log("Setup Hook Complete");
    // }
}
