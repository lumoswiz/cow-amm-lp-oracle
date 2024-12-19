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

struct TokenParams {
    address addr;
    uint256 balance;
    uint256 normWeight;
    uint256 denormWeight;
}

struct OrderParams {
    address pool;
    address factory;
    TokenParams token0;
    TokenParams token1;
}

struct FeedParams {
    address addr;
    uint8 decimals;
    int256 answer;
    uint256 updatedAt;
}
