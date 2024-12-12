// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25;

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
    bytes32 domainSeparator;
}
