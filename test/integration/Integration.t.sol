// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { BaseTest } from "test/Base.t.sol";
import { Addresses } from "test/utils/Addresses.sol";

import { LPOracle } from "src/LPOracle.sol";
import { LPOracleFactory } from "src/LPOracleFactory.sol";

contract IntegrationTest is Addresses, BaseTest {
    // LPOracle
    LPOracle internal lpOracle;
    LPOracleFactory internal factory;
    address internal POOL_WETH_UNI;
    address internal FEED_WETH;
    address internal FEED_UNI;

    function setUp() public virtual override {
        // Addresses
        (POOL_WETH_UNI, FEED_WETH, FEED_UNI) = getOracleConstructorArgs(WETH, UNI);

        // Fork
        vm.createSelectFork({ blockNumber: 21_643_099, urlOrAlias: "mainnet" });

        // Deploy contracts to the fork.
        factory = new LPOracleFactory();
        lpOracle = LPOracle(factory.deployOracle(address(FORK_POOL), address(FORK_FEED0), address(FORK_FEED1)));
    }
}
