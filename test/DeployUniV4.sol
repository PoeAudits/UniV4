//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {StdCheats, Test, console2 as console} from "lib/forge-std/src/Test.sol";
import {Deployers} from "lib/v4-core/test/utils/Deployers.sol";

import {Permit2} from "lib/v4-periphery/lib/permit2/src/Permit2.sol";
import {PositionManager} from "lib/v4-periphery/src/PositionManager.sol";
import {PositionDescriptor} from "lib/v4-periphery/src/PositionDescriptor.sol";
import {IPositionDescriptor} from "lib/v4-periphery/src/interfaces/IPositionDescriptor.sol";
import {WETH} from "lib/v4-core/lib/solmate/src/tokens/WETH.sol";
import {IWETH9} from "lib/v4-periphery/src/interfaces/external/IWETH9.sol";

contract DeployUniV4 is Test, Deployers {
    Permit2 permit2;
    PositionManager positionManager;
    PositionDescriptor positionDescriptor;
    WETH weth;

    // function setUp() public virtual {
    //     deployUniswapV4();
    // }

    function deployUniswapV4() internal {
        deployFreshManagerAndRouters();
        permit2 = new Permit2();
        weth = new WETH();

        positionDescriptor = new PositionDescriptor(
            manager,
            address(weth),
            bytes32(
                0x4554480000000000000000000000000000000000000000000000000000000000
            )
        );

        positionManager = new PositionManager(
            manager,
            permit2,
            150000,
            IPositionDescriptor(positionDescriptor),
            IWETH9(address(weth))
        );
    }

    function testDeploy() public {
        deployUniswapV4();
        console.log("Done!");
    }
}
