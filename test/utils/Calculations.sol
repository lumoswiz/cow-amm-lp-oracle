// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { BMath } from "@balancer/cow-amm/src/contracts/BMath.sol";

/// @dev Helper contract for calculations required in testing.
contract Calculations is BMath {
    /// @dev Returns the maximum tokenAmountOut for a given balanceAmountOut for BMath.calcInGivenOut
    function maxAmountOutGivenBalanceOut(uint256 bO) internal pure returns (uint256) {
        uint256 x = bmul(bO, MAX_BPOW_BASE);
        uint256 y = bsub(x, bO);
        uint256 aO = bdiv(y, MAX_BPOW_BASE) - 1 wei;
        return aO;
    }
}
