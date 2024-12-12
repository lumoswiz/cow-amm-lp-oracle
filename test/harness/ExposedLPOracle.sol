// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import { LPOracle } from "src/LPOracle.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract ExposedLPOracle is LPOracle {
    constructor(address _pool, address _helper) LPOracle(_pool, _helper) { }

    function exposed_simulateOrder(uint256 price0, uint256 price1) external view returns (GPv2Order.Data memory) {
        return _simulateOrder(price0, price1);
    }

    function exposed_normalizePrices(uint256 price0, uint256 price1) external view returns (uint256[] memory) {
        return _normalizePrices(price0, price1);
    }

    function exposed_adjustDecimals(
        uint256 value0,
        uint256 value1,
        uint8 decimals0,
        uint8 decimals1
    )
        external
        pure
        returns (uint256 adjusted0, uint256 adjusted1)
    {
        return _adjustDecimals(value0, value1, decimals0, decimals1);
    }
}
