// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { ExposedLPOracle } from "test/harness/ExposedLPOracle.sol";
import { MockBCoWHelper } from "test/mocks/MockBCoWHelper.sol";

import { Utils } from "test/utils/Utils.sol";
import { Defaults } from "test/utils/Defaults.sol";
import { OrderParams, TokenParams } from "test/utils/Types.sol";

contract BaseTest is Defaults, Utils {
    address internal MOCK_POOL = makeAddr("MOCK_POOL");
    address internal MOCK_FACTORY = makeAddr("MOCK_FACTORY");
    address internal TOKEN0 = makeAddr("TOKEN0");
    address internal TOKEN1 = makeAddr("TOKEN1");

    ExposedLPOracle internal oracle;
    MockBCoWHelper internal helper;

    function setUp() public virtual {
        // Mock BCoWFactory.APP_DATA() call
        mock_factory_APP_DATA(MOCK_FACTORY, APP_DATA);

        // Deploy MockBCoWHelper with default configuration
        helper = new MockBCoWHelper(MOCK_FACTORY);
        vm.label(address(helper), "MockBCoWHelper");

        // Setup default token configuration with 18 decimals
        setTokenDecimals(18, 18);

        // Initialize oracle with default configuration
        oracle = new ExposedLPOracle(MOCK_POOL, address(helper));
        vm.label(address(oracle), "ExposedLPOracle");
    }

    function setTokenDecimals(uint8 decimals0, uint8 decimals1) internal {
        // Mock helper.tokens() call
        mock_helper_tokens(address(helper), MOCK_POOL, TOKEN0, TOKEN1);

        // Mock decimals() calls for both tokens
        mock_address_decimals(TOKEN0, decimals0);
        mock_address_decimals(TOKEN1, decimals1);
    }

    // Helper to reinitialize oracle after changing decimals
    function reinitOracle(uint8 decimals0, uint8 decimals1) internal {
        setTokenDecimals(decimals0, decimals1);
        oracle = new ExposedLPOracle(MOCK_POOL, address(helper));
    }

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
