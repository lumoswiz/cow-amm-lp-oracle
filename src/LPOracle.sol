// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract LPOracle {
    /// @notice Adjusts input values according to decimals.
    /// @dev Used to adjust pool reserve balances and price feed answers.
    /// @param value0 Value associated with pool token 0.
    /// @param value1 Value associated with pool token 1.
    /// @param decimals0 Decimals for value0.
    /// @param decimals1 Decimals for value1.
    /// @return Ensures the return values have the same decimal base.
    function _adjustDecimals(
        uint256 value0,
        uint256 value1,
        uint256 decimals0,
        uint256 decimals1
    )
        internal
        pure
        returns (uint256, uint256)
    {
        if (decimals0 == decimals1) {
            return (value0, value1);
        } else {
            return (value0 * (10 ** (18 - decimals0)), value1 * (10 ** (18 - decimals1)));
        }
    }
}
