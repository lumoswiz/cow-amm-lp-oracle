// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.25 < 0.9.0;

import { Test } from "forge-std/Test.sol";

contract Utils is Test {
    /*----------------------------------------------------------*|
    |*  # MOCK CALLS: BCoWHelper                                *|
    |*----------------------------------------------------------*/
    function mock_call_tokens(address helper, address pool, address token0, address token1) internal {
        // Setup token addresses
        address[] memory tokens = new address[](2);
        tokens[0] = token0;
        tokens[1] = token1;

        // Mock helper.tokens() call
        vm.mockCall(helper, abi.encodeWithSignature("tokens(address)", pool), abi.encode(tokens));
    }
}
