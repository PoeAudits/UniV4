// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";
import "test/base/BaseImports.sol";
import "test/base/BaseParams.sol";

import {Currency, CurrencyLibrary} from "lib/v4-core/src/types/Currency.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {StateLibrary} from "lib/v4-core/src/libraries/StateLibrary.sol";

import {IV4Router} from "lib/v4-periphery/src/interfaces/IV4Router.sol";
import {Commands} from "lib/universal-router/contracts/libraries/Commands.sol";
import {Actions} from "lib/v4-periphery/src/libraries/Actions.sol";

contract Swap is Script, BaseImports {
    using StateLibrary for IPoolManager;

    function run() public {}

    function swapExactInputSingle(
        PoolKey memory key,
        bool zeroForOne,
        uint128 amountIn,
        uint128 minAmountOut
    ) external returns (uint256 amountOut) {
        // Encode the Universal Router command
        bytes memory commands = abi.encodePacked(uint8(Commands.V4_SWAP));
        bytes[] memory inputs = new bytes[](1);

        // Encode V4Router actions
        bytes memory actions = abi.encodePacked(
            uint8(Actions.SWAP_EXACT_IN_SINGLE),
            uint8(Actions.SETTLE_ALL),
            uint8(Actions.TAKE_ALL)
        );

        // Prepare parameters for each action
        bytes[] memory params = new bytes[](3);
        params[0] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: key,
                zeroForOne: zeroForOne,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                hookData: bytes("")
            })
        );
        params[1] = abi.encode(
            zeroForOne ? key.currency0 : key.currency1,
            amountIn
        );
        params[2] = abi.encode(
            zeroForOne ? key.currency1 : key.currency0,
            minAmountOut
        );

        // Combine actions and params into inputs
        inputs[0] = abi.encode(actions, params);

        // Execute the swap
        router.execute(commands, inputs, block.timestamp + 60);

        // Verify and return the output amount
        amountOut = IERC20(
            zeroForOne
                ? Currency.unwrap(key.currency1)
                : Currency.unwrap(key.currency0)
        ).balanceOf(address(this));
        require(amountOut >= minAmountOut, "Insufficient output amount");
        return amountOut;
    }
}
