// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.25 < 0.9.0;

import { Utils } from "test/utils/Utils.sol";
import { ExposedLPOracle } from "test/harness/ExposedLPOracle.sol";

contract BaseTest is Utils {
    address internal constant MOCK_HELPER = address(1);
    address internal constant MOCK_POOL = address(2);
    address internal constant TOKEN0 = address(0x1111111111111111111111111111111111111111);
    address internal constant TOKEN1 = address(0x2222222222222222222222222222222222222222);

    ExposedLPOracle internal oracle;

    function setUp() public virtual {
        // Setup default token configuration with 18 decimals
        setTokenDecimals(18, 18);
        // Initialize oracle with default configuration
        oracle = new ExposedLPOracle(MOCK_POOL, MOCK_HELPER);
        // Label for stack traces
        vm.label(address(oracle), "ExposedLPOracle");
    }

    function setTokenDecimals(uint8 decimals0, uint8 decimals1) internal {
        // Mock helper.tokens() call
        mock_call_tokens(MOCK_HELPER, MOCK_POOL, TOKEN0, TOKEN1);

        // Mock decimals() calls for both tokens
        vm.mockCall(TOKEN0, abi.encodeWithSignature("decimals()"), abi.encode(decimals0));
        vm.mockCall(TOKEN1, abi.encodeWithSignature("decimals()"), abi.encode(decimals1));
    }

    // Helper to reinitialize oracle after changing decimals
    function reinitOracle(uint8 decimals0, uint8 decimals1) internal {
        setTokenDecimals(decimals0, decimals1);
        oracle = new ExposedLPOracle(MOCK_POOL, MOCK_HELPER);
    }
}
