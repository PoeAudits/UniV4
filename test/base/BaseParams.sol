// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Currency} from "lib/v4-core/src/types/Currency.sol";

struct MintPositionParams {
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0;
    uint256 amount1;
    uint128 amount0Max;
    uint128 amount1Max;
    address recipient;
    bytes hookData;
}

struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0;
    uint256 amount1;
    uint128 amount0Max;
    uint128 amount1Max;
    bytes hookData;
}

struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0;
    uint256 amount1;
    uint128 amount0Min;
    uint128 amount1Min;
    address recipient;
    bytes hookData;
}
struct CollectFeesParams {
    uint256 tokenId;
    address recipient;
    bytes hookData;
}

struct BurnParams {
    uint256 tokenId;
    uint128 amount0Min;
    uint128 amount1Min;
    bytes hookData;
}
