//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {console2 as console} from "lib/forge-std/src/Test.sol";

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IPositionManager} from "lib/v4-periphery/src/interfaces/IPositionManager.sol";
import {Currency, CurrencyLibrary} from "lib/v4-core/src/types/Currency.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";

import {PositionLibrary, CreatePoolParams} from "src/Libraries/PositionLibrary.sol";

contract TokenWithPool is ERC20("TokenPool", "TP") {
    using PositionLibrary for IPositionManager;

    struct PoolInit {
        IPositionManager positionManager;
        Currency pairedCurrency;
        IHooks hookContract;
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

        CreatePoolParams memory createParams = CreatePoolParams({
            key: key,
            startingPrice: init.startingPrice,
            hookData: init.hookData
        });
        init.positionManager.CreatePool(createParams);
    }

    function Mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
