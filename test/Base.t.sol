// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { ExposedLPOracle } from "test/harness/ExposedLPOracle.sol";

import { Assertions } from "test/utils/Assertions.sol";
import { Calculations } from "test/utils/Calculations.sol";
import { Defaults } from "test/utils/Defaults.sol";
import { Mocks, OrderParams, TokenParams, FeedParams } from "test/utils/Types.sol";
import { Utils } from "test/utils/Utils.sol";

contract BaseTest is Assertions, Calculations, Utils {
    Mocks internal mocks;

    Defaults internal defaults;
    ExposedLPOracle internal oracle;

    function setUp() public virtual {
        // Deploy the defaults contract.
        defaults = new Defaults();

        // Create & label mock addresses for testing.
        vm.label(mocks.factory = makeAddr("FACTORY"), "FACTORY");
        vm.label(mocks.pool = makeAddr("POOL"), "POOL");
        vm.label(mocks.token0 = makeAddr("TOKEN0"), "TOKEN0");
        vm.label(mocks.token1 = makeAddr("TOKEN1"), "TOKEN1");
        vm.label(mocks.feed0 = makeAddr("FEED0"), "FEED0");
        vm.label(mocks.feed1 = makeAddr("FEED1"), "FEED1");
        defaults.setMocks(mocks);

        // Set defaults for LPOracle constructor args
        setOracleConstructorMockCalls(8, 8, 18, 18, defaults.WEIGHT_50());

        // Initialize oracle with default configuration
        oracle = new ExposedLPOracle(mocks.pool, mocks.feed0, mocks.feed1);
        vm.label(address(oracle), "ExposedLPOracle");
    }

    /*----------------------------------------------------------*|
    |*  # HELPERS: MOCKS                                        *|
    |*----------------------------------------------------------*/

    /// @dev Helper to mock all decimals for addresses in LPOracle.
    /// @dev Inputs in order they appear in the constructor.
    function setAllAddressDecimals(
        uint8 feedDecimals0,
        uint8 feedDecimals1,
        uint8 tokenDecimals0,
        uint8 tokenDecimals1
    )
        internal
    {
        setFeedDecimals(feedDecimals0, feedDecimals1);
        setTokenDecimals(tokenDecimals0, tokenDecimals1);
    }

    /// @dev Helper to mock price feed decimals
    function setFeedDecimals(uint8 decimals0, uint8 decimals1) internal {
        mock_address_decimals(mocks.feed0, decimals0);
        mock_address_decimals(mocks.feed1, decimals1);
    }

    /// @dev Helper to mock token decimals
    function setTokenDecimals(uint8 decimals0, uint8 decimals1) internal {
        mock_address_decimals(mocks.token0, decimals0);
        mock_address_decimals(mocks.token1, decimals1);
    }

    /// @dev Helper to mock price feed data for both feeds - decimals, latestRoundData
    function setPriceFeedData(FeedParams memory params0, FeedParams memory params1) internal {
        setFeedDecimals(params0.decimals, params1.decimals);
        mock_feed_latestRoundData(params0.addr, params0.answer, params0.updatedAt);
        mock_feed_latestRoundData(params1.addr, params1.answer, params1.updatedAt);
    }

    /// @dev Helper to mock the pool token normalized weights
    function setTokenWeights(uint256 token0Weight) internal {
        mock_pool_getNormalizedWeight(mocks.pool, mocks.token0, token0Weight);
        mock_pool_getNormalizedWeight(mocks.pool, mocks.token1, 1e18 - token0Weight);
    }

    /// @dev Helper to mock the pool token balances
    function setTokenBalances(uint256 token0Balance, uint256 token1Balance) internal {
        mock_token_balanceOf(mocks.token0, mocks.pool, token0Balance);
        mock_token_balanceOf(mocks.token1, mocks.pool, token1Balance);
    }

    function setLatestRoundDataMocks(
        int256 answer0,
        int256 answer1,
        uint256 token0Balance,
        uint256 token1Balance
    )
        internal
    {
        (FeedParams memory feedParams0, FeedParams memory feedParams1) = defaults.mockFeedParams(answer0, answer1);
        setPriceFeedData(feedParams0, feedParams1);
        mock_token_balanceOf(mocks.token0, mocks.pool, token0Balance);
        mock_token_balanceOf(mocks.token1, mocks.pool, token1Balance);
        mock_pool_totalSupply(mocks.pool, defaults.LP_TOKEN_SUPPLY());
    }

    function setOracleConstructorMockCalls(
        uint8 feedDecimals0,
        uint8 feedDecimals1,
        uint8 tokenDecimals0,
        uint8 tokenDecimals1,
        uint256 token0Weight
    )
        internal
    {
        setAllAddressDecimals(feedDecimals0, feedDecimals1, tokenDecimals0, tokenDecimals1);
        mock_pool_getFinalTokens(mocks.pool, mocks.token0, mocks.token1);
        mock_pool_getNormalizedWeight(mocks.pool, mocks.token0, token0Weight);
        mock_pool_getNormalizedWeight(mocks.pool, mocks.token1, 1e18 - token0Weight);
    }

    /// @dev Helper to reinitialize oracle after changing decimals
    function reinitOracle(uint8 decimals0, uint8 decimals1) internal {
        setAllAddressDecimals(8, 8, decimals0, decimals1);
        oracle = new ExposedLPOracle(mocks.pool, mocks.feed0, mocks.feed1);
    }
}
