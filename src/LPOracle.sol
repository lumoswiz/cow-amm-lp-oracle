// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { AggregatorV3Interface } from "@cow-amm/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";
import { IBCoWPool } from "@balancer/cow-amm/src/interfaces/IBCoWPool.sol";
import { wadMul, wadDiv, wadPow } from "solmate/utils/SignedWadMath.sol";

contract LPOracle is AggregatorV3Interface {
    /// @notice Thrown when Chainlink price feeds with more than 18 decimals are used.
    error UnsupportedDecimals();

    /// @notice BCoWPool address.
    address public immutable POOL;

    /// @notice Pool token 0.
    /// @dev Token at index 0 from `pool.getFinalTokens` call.
    IERC20 public immutable TOKEN0;

    /// @notice Pool token 1.
    /// @dev Token at index 1 from `pool.getFinalTokens` call.
    IERC20 public immutable TOKEN1;

    /// @notice Pool token 0 decimals
    uint256 public immutable TOKEN0_DECIMALS;

    /// @notice Pool token 1 decimals
    uint256 public immutable TOKEN1_DECIMALS;

    /// @notice Pool token 0 normalized weight
    int256 public immutable WEIGHT0;

    /// @notice Pool token 1 normalized weight
    int256 public immutable WEIGHT1;

    /// @notice Chainlink USD price for pool token 0
    AggregatorV3Interface public immutable FEED0;

    /// @notice Chainlink USD price for pool token 1
    AggregatorV3Interface public immutable FEED1;

    /// @dev Must check Chainlink price feeds match pool token ordering.
    /// @param _pool BCoWPool address.
    /// @param _feed0 Chainlink USD price feed for pool token at index 0.
    /// @param _feed1 Chainlink USD price feed for pool token at index 1.
    constructor(address _pool, address _feed0, address _feed1) {
        /* Set price feeds & revert if feeds have greater than 18 decimals */
        FEED0 = AggregatorV3Interface(_feed0);
        FEED1 = AggregatorV3Interface(_feed1);
        if (FEED0.decimals() > 18 || FEED1.decimals() > 18) revert UnsupportedDecimals();

        /* Set pool contract */
        POOL = _pool;

        /* Gets pool tokens with correct ordering and pool validation checks */
        address[] memory tokens = IBCoWPool(POOL).getFinalTokens();
        TOKEN0 = IERC20(tokens[0]);
        TOKEN1 = IERC20(tokens[1]);

        /* Set token decimals */
        TOKEN0_DECIMALS = TOKEN0.decimals();
        TOKEN1_DECIMALS = TOKEN1.decimals();

        /* Add pool token normalized weights casted to int256 */
        WEIGHT0 = int256(IBCoWPool(POOL).getNormalizedWeight(tokens[0]));
        WEIGHT1 = int256(IBCoWPool(POOL).getNormalizedWeight(tokens[1]));
    }

    /*----------------------------------------------------------*|
    |*  # AGGREGATOR V3 INTERFACE REQUIREMENTS                  *|
    |*----------------------------------------------------------*/

    /// @notice Returns the number of decimals used.
    function decimals() external view returns (uint8) {
        uint8 feed0Decimals = FEED0.decimals();
        return feed0Decimals == FEED1.decimals() ? feed0Decimals : 18;
    }

    /// @notice Returns the description of the LP token pricing oracle.
    function description() external view returns (string memory) {
        return string.concat(IERC20(POOL).name(), " LP Token / USD");
    }

    /// @notice Returns the oracle version.
    /// @dev Chainlink interface requires implementation.
    function version() external pure returns (uint256) {
        return 0;
    }

    /// @dev Chainlink interface requires implementation. No meaningful values for this contract.
    function getRoundData(uint80)
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 0, 0, 0, 0);
    }

    /// @notice Returns the latest price data for the BCoWPool AMM LP Token.
    /// @dev Price is determined based on simulated reserve balances post rebalancing trade from external price feeds.
    /// @return roundId Not implemented.
    /// @return answer LP Token price.
    /// @return startedAt Not implemented.
    /// @return updatedAt The timestamp of the feed with the oldest price udpate.
    /// @return answeredInRound Not implemented.
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        /* Get the price feed data */
        (int256 answer0, int256 answer1, uint256 updatedAt_) = _getFeedData();

        /* Directly calculate TVL from weighted pool math */
        uint256 tvl = _calculateTVL(answer0, answer1);

        /* Determine LP token price from tvl */
        uint256 lpPrice = (tvl * 1e18) / IERC20(POOL).totalSupply();

        return (0, int256(lpPrice), 0, updatedAt_, 0);
    }

    /*----------------------------------------------------------*|
    |*  # INTERNAL HELPERS                                      *|
    |*----------------------------------------------------------*/

    /// @notice Retrieves latest price data from Chainlink feeds and adjusts for decimals.
    /// @return answer0 Price feed answer for token 0.
    /// @return answer1 Price feed answer for token 1.
    /// @return updatedAt The timestamp of the feed with the oldest price udpate.
    function _getFeedData() internal view returns (int256 answer0, int256 answer1, uint256 updatedAt) {
        /* Get latestRoundData from price feeds */
        (, int256 answer0_,, uint256 updatedAt0,) = FEED0.latestRoundData();
        (, int256 answer1_,, uint256 updatedAt1,) = FEED1.latestRoundData();

        /* Set update timestamp of oldest price feed */
        updatedAt = updatedAt0 < updatedAt1 ? updatedAt0 : updatedAt1;

        /* Adjust answers for price feed decimals */
        uint8 feed0Decimals = FEED0.decimals();
        uint8 feed1Decimals = FEED1.decimals();

        if (feed0Decimals == feed1Decimals) {
            return (answer0_, answer1_, updatedAt);
        } else {
            return (
                answer0_ * int256(10 ** (18 - feed0Decimals)), answer1_ * int256(10 ** (18 - feed1Decimals)), updatedAt
            );
        }
    }

    /// @notice Calculates pool TVL post rebalancing trade with external token prices
    /// @dev Input prices must have same decimal basis. Output TVL has same basis units.
    /// @param answer0 price feed answer for token 0.
    /// @param answer1 Price feed answer for token 1.
    function _calculateTVL(int256 answer0, int256 answer1) internal view returns (uint256 tvl) {
        /* Get pool k value */
        int256 balance0 = int256(TOKEN0.balanceOf(POOL));
        int256 balance1 = int256(TOKEN1.balanceOf(POOL));
        int256 k = wadMul(wadPow(wadDiv(balance0, balance1), WEIGHT0), balance1);

        /* Get weight factor */
        int256 weightFactor = wadPow(wadDiv(WEIGHT0, WEIGHT1), WEIGHT1) + wadPow(wadDiv(WEIGHT1, WEIGHT0), WEIGHT0);

        /* Calculate TVL directly from pool math */
        int256 pxComponent = wadPow(answer0, WEIGHT0);
        int256 pyComponent = wadPow(answer1, WEIGHT1);
        return uint256(wadMul(wadMul(wadMul(k, pxComponent), pyComponent), weightFactor));
    }
}
