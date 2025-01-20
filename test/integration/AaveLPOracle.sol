// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { LPOracle } from "src/LPOracle.sol";

/// @dev Aave V3 expects asset sources to be AggregateInterface contracts, so this
/// is a workaround for integration testing.
contract AaveLPOracle {
    LPOracle internal lpOracle;

    constructor(address _lpOracle) {
        lpOracle = LPOracle(_lpOracle);
    }

    function latestAnswer() external view returns (int256) {
        (, int256 answer,,,) = lpOracle.latestRoundData();
        return answer;
    }
}
