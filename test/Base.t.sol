// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.25 < 0.9.0;

import { Utils } from "test/utils/Utils.sol";
import { ExposedLPOracle } from "test/harness/ExposedLPOracle.sol";
import { MockBCoWHelper } from "test/mocks/MockBCoWHelper.sol";

contract BaseTest is Utils {
    address internal MOCK_POOL = makeAddr("MOCK_POOL");
    address internal MOCK_FACTORY = makeAddr("MOCK_FACTORY");
    address internal constant TOKEN0 = address(0x1111111111111111111111111111111111111111);
    address internal constant TOKEN1 = address(0x2222222222222222222222222222222222222222);

    uint256 internal constant TOKEN0_BALANCE = 1e18;
    uint256 internal constant TOKEN1_BALANCE = 1e18;
    uint256 internal constant NORMALIZED_WEIGHT = 0.5e18;
    uint256 internal constant DENORMALIZED_WEIGHT = 1e18;
    bytes32 internal constant APP_DATA = keccak256("APP_DATA");

    ExposedLPOracle internal oracle;
    MockBCoWHelper internal helper;
    // MockBCoWPool internal pool;

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
        vm.mockCall(TOKEN0, abi.encodeWithSignature("decimals()"), abi.encode(decimals0));
        vm.mockCall(TOKEN1, abi.encodeWithSignature("decimals()"), abi.encode(decimals1));
    }

    // Helper to reinitialize oracle after changing decimals
    function reinitOracle(uint8 decimals0, uint8 decimals1) internal {
        setTokenDecimals(decimals0, decimals1);
        oracle = new ExposedLPOracle(MOCK_POOL, address(helper));
    }
}
