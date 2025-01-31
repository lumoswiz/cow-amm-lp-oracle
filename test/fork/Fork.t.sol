// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { BaseTest } from "test/Base.t.sol";
import { Addresses } from "test/utils/Addresses.sol";

import { LPOracle } from "src/LPOracle.sol";
import { LPOracleFactory } from "src/LPOracleFactory.sol";

import { AggregatorV3Interface } from "@chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";

contract ForkTest is Addresses, BaseTest {
    LPOracle internal lpOracle;
    LPOracleFactory internal factory;

    IERC20 internal immutable FORK_POOL;
    IERC20 internal immutable FORK_TOKEN0;
    IERC20 internal immutable FORK_TOKEN1;
    AggregatorV3Interface internal immutable FORK_FEED0;
    AggregatorV3Interface internal immutable FORK_FEED1;

    uint256 internal INITIAL_POOL_TOKEN0_BALANCE;
    uint256 internal INITIAL_POOL_TOKEN1_BALANCE;
    uint256 internal INITIAL_POOL_LP_SUPPLY;
    int256 internal INITIAL_FEED0_ANSWER;
    int256 internal INITIAL_FEED1_ANSWER;
    uint8 internal FEED0_DECIMALS;
    uint8 internal FEED1_DECIMALS;

    constructor(address _token0, address _token1) {
        FORK_TOKEN0 = IERC20(_token0);
        FORK_TOKEN1 = IERC20(_token1);

        (address _pool, address _feed0, address _feed1) = getOracleConstructorArgs(_token0, _token1);

        FORK_POOL = IERC20(_pool);
        FORK_FEED0 = AggregatorV3Interface(_feed0);
        FORK_FEED1 = AggregatorV3Interface(_feed1);
    }

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a specific block number.
        // Be careful with setting block numbers at times when the pool doesn't exist.
        vm.createSelectFork({ blockNumber: 21_422_754, urlOrAlias: "mainnet" });

        // Deploy contracts to the fork.
        factory = new LPOracleFactory();
        lpOracle = LPOracle(factory.deployOracle(address(FORK_POOL), address(FORK_FEED0), address(FORK_FEED1)));

        // Label contracts.
        labelContracts();

        // Cache variables
        INITIAL_POOL_TOKEN0_BALANCE = FORK_TOKEN0.balanceOf(address(FORK_POOL));
        INITIAL_POOL_TOKEN1_BALANCE = FORK_TOKEN1.balanceOf(address(FORK_POOL));
        INITIAL_POOL_LP_SUPPLY = FORK_POOL.totalSupply();

        (, INITIAL_FEED0_ANSWER,,,) = FORK_FEED0.latestRoundData();

        (, INITIAL_FEED1_ANSWER,,,) = FORK_FEED1.latestRoundData();

        FEED0_DECIMALS = FORK_FEED0.decimals();
        FEED1_DECIMALS = FORK_FEED1.decimals();
    }

    function labelContracts() internal {
        vm.label(address(factory), "FACTORY");
        vm.label(address(lpOracle), "ORACLE");
        vm.label(address(FORK_POOL), "POOL");
        vm.label(address(FORK_TOKEN0), "TOKEN0");
        vm.label(address(FORK_TOKEN1), "TOKEN1");
        vm.label(address(FORK_FEED0), "FEED0");
        vm.label(address(FORK_FEED1), "FEED1");
    }
}
