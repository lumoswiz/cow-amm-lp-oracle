// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { LPOracle } from "src/LPOracle.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract ExposedLPOracle is LPOracle {
    constructor(address _pool, address _feed0, address _feed1) LPOracle(_pool, _feed0, _feed1) { }

    function exposed_getFeedData() external view returns (uint256 price0, uint256 price1, uint256 updatedAt) {
        return _getFeedData();
    }

    function exposed_simulatePoolReserves(uint256 price0, uint256 price1) external view returns (uint256, uint256) {
        return _simulatePoolReserves(price0, price1);
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

    function exposed_calculatePrice(
        uint256 token0Bal,
        uint256 token1Bal,
        uint256 price0,
        uint256 price1
    )
        external
        view
        returns (uint256)
    {
        return _calculatePrice(token0Bal, token1Bal, price0, price1);
    }
}
