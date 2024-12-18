// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { BMath } from "@balancer/cow-amm/src/contracts/BMath.sol";

/// @dev Helper contract for calculations required in testing.
contract Calculations is BMath {
    /// @dev Returns the maximum tokenAmountOut for a given balanceAmountOut for BMath.calcInGivenOut
    /// Returns 99.96% of the max amount to avoid OutOfGas reverts.
    function maxAmountOutGivenBalanceOut(uint256 tokenBalanceOut) internal pure returns (uint256) {
        uint256 x = bmul(tokenBalanceOut, MAX_BPOW_BASE);
        uint256 y = bsub(x, tokenBalanceOut);
        uint256 maxTokenAmountOut = bdiv(y, MAX_BPOW_BASE) - 1 wei;
        return (maxTokenAmountOut * 9996) / 1e4;
    }
}
