// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25;

struct Mocks {
    address factory;
    address pool;
    address token0;
    address token1;
    address feed0;
    address feed1;
}

struct FeedParams {
    address addr;
    uint8 decimals;
    int256 answer;
    uint256 updatedAt;
}
