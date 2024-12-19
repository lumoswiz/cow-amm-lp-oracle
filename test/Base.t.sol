// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { ExposedLPOracle } from "test/harness/ExposedLPOracle.sol";
import { MockBCoWHelper } from "test/mocks/MockBCoWHelper.sol";

import { Assertions } from "test/utils/Assertions.sol";
import { Calculations } from "test/utils/Calculations.sol";
import { Defaults } from "test/utils/Defaults.sol";
import { Mocks, OrderParams, TokenParams, FeedParams } from "test/utils/Types.sol";
import { Utils } from "test/utils/Utils.sol";

contract BaseTest is Assertions, Calculations, Utils {
    Mocks internal mocks;

    Defaults internal defaults;
    ExposedLPOracle internal oracle;
    MockBCoWHelper internal helper;

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

        // Mock BCoWFactory.APP_DATA() call
        mock_factory_APP_DATA(mocks.factory, defaults.APP_DATA());

        // Deploy MockBCoWHelper with default configuration
        helper = new MockBCoWHelper(mocks.factory);
        vm.label(address(helper), "MockBCoWHelper");

        // Setup default decimal configs: feeds -> 8, tokens -> 18
        setAllAddressDecimals(8, 8, 18, 18);

        // Initialize oracle with default configuration
        oracle = new ExposedLPOracle(mocks.pool, address(helper), mocks.feed0, mocks.feed1);
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
        setFeedsAndDecimals(mocks.feed0, mocks.feed1, feedDecimals0, feedDecimals1);
        setHelperTokensAndDecimals(tokenDecimals0, tokenDecimals1);
    }

    /// @dev Helper to mock price feed decimals.
    function setFeedsAndDecimals(address feed0, address feed1, uint8 decimals0, uint8 decimals1) internal {
        mock_address_decimals(feed0, decimals0);
        mock_address_decimals(feed1, decimals1);
    }

    /// @dev Helper to mock BCoWHelper.tokens() call & set token decimals.
    function setHelperTokensAndDecimals(uint8 decimals0, uint8 decimals1) internal {
        // Mock helper.tokens() call
        mock_helper_tokens(address(helper), mocks.pool, mocks.token0, mocks.token1);

        // Mock decimals() calls for both tokens
        mock_address_decimals(mocks.token0, decimals0);
        mock_address_decimals(mocks.token1, decimals1);
    }

    /// @dev Helper to mock the order with specified token balances and weights.
    function setMockOrder(uint256 token0Balance, uint256 token1Balance, uint256 token0Weight) internal {
        OrderParams memory params = defaults.mockOrderParamsCustomValues(token0Balance, token1Balance, token0Weight);
        mock_helper_order(params);
    }

    /// @dev Helper to mock price feed data for both feeds - decimals, latestRoundData
    function setPriceFeedData(FeedParams memory params0, FeedParams memory params1) internal {
        setFeedsAndDecimals(params0.addr, params1.addr, params0.decimals, params1.decimals);
        mock_feed_latestRoundData(params0.addr, params0.answer, params0.updatedAt);
        mock_feed_latestRoundData(params1.addr, params1.answer, params1.updatedAt);
    }

    /// @dev Helper to set all mocks required for calls to the oracle's latestRoundData() function.
    function setLatestRoundDataMocks(
        int256 answer0,
        int256 answer1,
        uint256 token0Balance,
        uint256 token1Balance,
        uint256 token0Weight
    )
        internal
    {
        (FeedParams memory feedParams0, FeedParams memory feedParams1) = defaults.mockFeedParams(answer0, answer1);
        setPriceFeedData(feedParams0, feedParams1);
        setMockOrder(token0Balance, token1Balance, token0Weight);
        mock_pool_totalSupply(mocks.pool, defaults.LP_TOKEN_SUPPLY());
    }

    /// @dev Helper to reinitialize oracle after changing decimals
    function reinitOracle(uint8 decimals0, uint8 decimals1) internal {
        setAllAddressDecimals(8, 8, decimals0, decimals1);
        oracle = new ExposedLPOracle(mocks.pool, address(helper), mocks.feed0, mocks.feed1);
    }

    function reinitOracleAll(
        uint8 feedDecimals0,
        uint8 feedDecimals1,
        uint8 token0Decimals,
        uint8 token1Decimals
    )
        internal
    {
        setAllAddressDecimals(feedDecimals0, feedDecimals1, token0Decimals, token1Decimals);
        oracle = new ExposedLPOracle(mocks.pool, address(helper), mocks.feed0, mocks.feed1);
    }
}
