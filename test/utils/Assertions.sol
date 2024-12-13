// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { StdAssertions } from "forge-std/Test.sol";
import { ICOWAMMPoolHelper } from "@cow-amm/interfaces/ICOWAMMPoolHelper.sol";
import { AggregatorV3Interface } from "@cow-amm/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";

contract Assertions is StdAssertions {
    function assertEq(IERC20 a, IERC20 b) internal pure {
        assertEq(address(a), address(b));
    }

    function assertEq(IERC20 a, IERC20 b, string memory err) internal pure {
        assertEq(address(a), address(b), err);
    }

    function assertEq(ICOWAMMPoolHelper a, ICOWAMMPoolHelper b) internal pure {
        assertEq(address(a), address(b));
    }

    function assertEq(ICOWAMMPoolHelper a, ICOWAMMPoolHelper b, string memory err) internal pure {
        assertEq(address(a), address(b), err);
    }

    function assertEq(AggregatorV3Interface a, AggregatorV3Interface b) internal pure {
        assertEq(address(a), address(b));
    }

    function assertEq(AggregatorV3Interface a, AggregatorV3Interface b, string memory err) internal pure {
        assertEq(address(a), address(b), err);
    }
}
