//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {console2 as console} from "lib/forge-std/src/Test.sol";

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IPositionManager} from "lib/v4-periphery/src/interfaces/IPositionManager.sol";
import {Currency, CurrencyLibrary} from "lib/v4-core/src/types/Currency.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";

contract TokenWithPoolAndLiquidity is ERC20("TokenPoolLiquidity", "TPL") {
    struct PoolInit {
        IPositionManager positionManager;
        Currency pairedCurrency;
        IHooks hookContract;
        uint256 mintAmount;
        uint24 lpFee;
        int24 tickSpacing;
        uint160 startingPrice;
        bytes hookData;
    }

    constructor(PoolInit memory init) {
        Currency thisCurrency = Currency.wrap(address(this));
        bool isTokenZero = thisCurrency < init.pairedCurrency ? true : false;

        PoolKey memory key = PoolKey({
            currency0: isTokenZero ? thisCurrency : init.pairedCurrency,
            currency1: isTokenZero ? init.pairedCurrency : thisCurrency,
            fee: init.lpFee,
            tickSpacing: init.tickSpacing,
            hooks: IHooks(init.hookContract)
        });

        bytes[] memory params = new bytes[](1);

        params[0] = abi.encodeWithSelector(
            init.positionManager.initializePool.selector,
            key,
            init.startingPrice,
            init.hookData
        );

        // Using multicall to keep consistent with more complex instances
        init.positionManager.multicall(params);
    }
}
