// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { Test } from "forge-std/Test.sol";
import { Addresses } from "test/utils/Addresses.sol";
import { Assertions } from "test/utils/Assertions.sol";

import { LPOracle } from "src/LPOracle.sol";
import { LPOracleFactory } from "src/LPOracleFactory.sol";

import { ICOWAMMPoolHelper } from "@cow-amm/interfaces/ICOWAMMPoolHelper.sol";
import { AggregatorV3Interface } from "@cow-amm/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";

contract ForkTest is Addresses, Assertions, Test {
    LPOracle internal oracle;
    LPOracleFactory internal factory;

    ICOWAMMPoolHelper internal immutable FORK_HELPER;
    IERC20 internal immutable FORK_POOL;
    IERC20 internal immutable FORK_TOKEN0;
    IERC20 internal immutable FORK_TOKEN1;
    AggregatorV3Interface internal immutable FORK_FEED0;
    AggregatorV3Interface internal immutable FORK_FEED1;

    constructor(address _token0, address _token1) {
        FORK_TOKEN0 = IERC20(_token0);
        FORK_TOKEN1 = IERC20(_token1);

        (address _pool, address _helper, address _feed0, address _feed1) = getOracleConstructorArgs(_token0, _token1);

        FORK_POOL = IERC20(_pool);
        FORK_HELPER = ICOWAMMPoolHelper(_helper);
        FORK_FEED0 = AggregatorV3Interface(_feed0);
        FORK_FEED1 = AggregatorV3Interface(_feed1);
    }

    function setUp() public virtual {
        // Fork Ethereum Mainnet at a specific block number.
        // Be careful with setting block numbers at times when the pool doesn't exist.
        vm.createSelectFork({ blockNumber: 21_422_754, urlOrAlias: "mainnet" });

        // Deploy contracts to the fork.
        factory = new LPOracleFactory(address(FORK_HELPER));
        oracle = LPOracle(factory.deployOracle(address(FORK_POOL), address(FORK_FEED0), address(FORK_FEED1)));

        // Label contracts.
        labelContracts();
    }

    function labelContracts() internal {
        vm.label(address(factory), "FACTORY");
        vm.label(address(oracle), "ORACLE");
        vm.label(address(FORK_HELPER), "HELPER");
        vm.label(address(FORK_POOL), "POOL");
        vm.label(address(FORK_TOKEN0), "TOKEN0");
        vm.label(address(FORK_TOKEN1), "TOKEN1");
        vm.label(address(FORK_FEED0), "FEED0");
        vm.label(address(FORK_FEED1), "FEED1");
    }
}
