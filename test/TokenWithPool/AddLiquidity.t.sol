//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "test/HelperFunctions.sol";
import {PositionLibrary, MintPositionParams} from "src/Libraries/PositionLibrary.sol";

contract AddLiquidity is HelperFunctions {
    using PositionLibrary for IPositionManager;

    function testAddLiquidityToPool() public {
        uint128 initialMintAmount = 1e27;
        MintPositionParams memory params = MintPositionParams({
            poolManager: poolManager,
            key: key,
            tickLower: -6000,
            tickUpper: 0,
            amount0: isTokenZero ? initialMintAmount : 0,
            amount1: isTokenZero ? 0 : initialMintAmount,
            amount0Max: isTokenZero ? initialMintAmount : 0,
            amount1Max: isTokenZero ? 0 : initialMintAmount,
            recipient: _deployer,
            deadline: uint48(block.timestamp + 60),
            hookData: ""
        });

        vm.startPrank(_deployer);
        (bool success, ) = _target.call(
            abi.encodeWithSignature("Mint(address,uint256)", _deployer, 1e27)
        );
        require(success, "Failed Mint Call");

        IERC20(_target).approve(address(permit2), type(uint256).max);
        permit2.approve(
            _target,
            address(positionManager),
            initialMintAmount,
            uint48(vm.getBlockTimestamp() + 60)
        );

        positionManager.MintPosition(params);
        vm.stopPrank();
    }
}
