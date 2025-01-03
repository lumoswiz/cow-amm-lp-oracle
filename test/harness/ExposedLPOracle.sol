// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { LPOracle } from "src/LPOracle.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract ExposedLPOracle is LPOracle {
    constructor(address _pool, address _feed0, address _feed1) LPOracle(_pool, _feed0, _feed1) { }

    function exposed_getFeedData() external view returns (uint256 price0, uint256 price1, uint256 updatedAt) {
        return _getFeedData();
    }

    function exposed_calculateTVL(uint256 price0, uint256 price1) external view returns (uint256) {
        return _calculateTVL(price0, price1);
    }
}
