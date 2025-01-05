// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { LPOracle } from "src/LPOracle.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract ExposedLPOracle is LPOracle {
    constructor(address _pool, address _feed0, address _feed1) LPOracle(_pool, _feed0, _feed1) { }

    function exposed_getFeedData() external view returns (int256 price0, int256 price1, uint256 updatedAt) {
        return _getFeedData();
    }

    function exposed_adjustDecimals(
        int256 answer0,
        int256 answer1,
        uint8 decimals0,
        uint8 decimals1
    )
        external
        pure
        returns (int256 adjusted0, int256 adjusted1)
    {
        return _adjustDecimals(answer0, answer1, decimals0, decimals1);
    }

    function exposed_calculateTVL(int256 price0, int256 price1) external view returns (uint256) {
        return _calculateTVL(price0, price1);
    }
}
