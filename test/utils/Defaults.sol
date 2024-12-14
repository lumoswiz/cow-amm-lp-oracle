// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

contract Defaults {
    uint256 internal constant BONE = 1e18;
    uint256 internal constant TOKEN0_BALANCE = 1e18;
    uint256 internal constant TOKEN1_BALANCE = 1e18;
    uint256 internal constant NORMALIZED_WEIGHT = 0.5e18;
    uint256 internal constant DENORMALIZED_WEIGHT = 1e18;
    bytes32 internal constant APP_DATA = keccak256("APP_DATA");
    uint256 internal constant DEC_1_2024 = 1_733_011_200;
}
