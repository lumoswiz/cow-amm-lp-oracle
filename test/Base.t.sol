// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { ExposedLPOracle } from "test/harness/ExposedLPOracle.sol";
import { MockBCoWHelper } from "test/mocks/MockBCoWHelper.sol";

import { Assertions } from "test/utils/Assertions.sol";
import { Defaults } from "test/utils/Defaults.sol";
import { OrderParams, TokenParams } from "test/utils/Types.sol";
import { Utils } from "test/utils/Utils.sol";

contract BaseTest is Assertions, Defaults, Utils {
    address internal MOCK_POOL = makeAddr("MOCK_POOL");
    address internal MOCK_FACTORY = makeAddr("MOCK_FACTORY");
    address internal TOKEN0 = makeAddr("TOKEN0");
    address internal TOKEN1 = makeAddr("TOKEN1");
    address internal FEED0 = makeAddr("FEED0");
    address internal FEED1 = makeAddr("FEED1");

    ExposedLPOracle internal oracle;
    MockBCoWHelper internal helper;

    function setUp() public virtual {
        // Mock BCoWFactory.APP_DATA() call
        mock_factory_APP_DATA(MOCK_FACTORY, APP_DATA);

        // Deploy MockBCoWHelper with default configuration
        helper = new MockBCoWHelper(MOCK_FACTORY);
        vm.label(address(helper), "MockBCoWHelper");

        // Setup default decimal configs: feeds -> 8, tokens -> 18
        setAllAddressDecimals(8, 8, 18, 18);

        // Initialize oracle with default configuration
        oracle = new ExposedLPOracle(MOCK_POOL, address(helper), FEED0, FEED1);
        vm.label(address(oracle), "ExposedLPOracle");
    }

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
        mock_address_decimals(FEED0, decimals0);
        mock_address_decimals(FEED1, decimals1);
    }

    /// @dev Helper to mock BCoWHelper.tokens() call & set token decimals
    function setTokenDecimals(uint8 decimals0, uint8 decimals1) internal {
        // Mock helper.tokens() call
        mock_helper_tokens(address(helper), MOCK_POOL, TOKEN0, TOKEN1);

        // Mock decimals() calls for both tokens
        mock_address_decimals(TOKEN0, decimals0);
        mock_address_decimals(TOKEN1, decimals1);
    }

    /// @dev Helper to reinitialize oracle after changing decimals
    function reinitOracle(uint8 decimals0, uint8 decimals1) internal {
        setAllAddressDecimals(8, 8, decimals0, decimals1);
        oracle = new ExposedLPOracle(MOCK_POOL, address(helper), FEED0, FEED1);
    }

    // Todo: implement input args for pool. tokens, balances, etc.
    function setMockOrder() internal {
        OrderParams memory params = OrderParams({
            pool: MOCK_POOL,
            factory: MOCK_FACTORY,
            token0: TokenParams({
                addr: TOKEN0,
                balance: TOKEN0_BALANCE,
                normWeight: NORMALIZED_WEIGHT,
                denormWeight: DENORMALIZED_WEIGHT
            }),
            token1: TokenParams({
                addr: TOKEN1,
                balance: TOKEN1_BALANCE,
                normWeight: NORMALIZED_WEIGHT,
                denormWeight: DENORMALIZED_WEIGHT
            })
        });

        mock_helper_order(params);
    }
}
