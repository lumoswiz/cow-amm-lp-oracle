// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { BaseTest } from "test/Base.t.sol";
import { Addresses } from "test/utils/Addresses.sol";

import { LPOracle } from "src/LPOracle.sol";
import { LPOracleFactory } from "src/LPOracleFactory.sol";

import { IPoolAddressesProvider } from "test/integration/aave-v3-contracts/interfaces/IPoolAddressesProvider.sol";
import { IPool } from "test/integration/aave-v3-contracts/interfaces/IPool.sol";
import { IPoolConfigurator } from "test/integration/aave-v3-contracts/interfaces/IPoolConfigurator.sol";
import { IAaveOracle } from "test/integration/aave-v3-contracts/interfaces/IAaveOracle.sol";

contract IntegrationTest is Addresses, BaseTest {
    // LPOracle
    LPOracle internal lpOracle;
    LPOracleFactory internal factory;
    address internal POOL_WETH_UNI;
    address internal FEED_WETH;
    address internal FEED_UNI;

    // Aave
    IPoolAddressesProvider internal provider = IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);
    IPool internal pool;
    IPoolConfigurator internal poolConfigurator;
    IAaveOracle internal aaveOracle;

    // Pool admin
    address internal constant admin = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;

    function setUp() public virtual override {
        // Addresses
        (POOL_WETH_UNI, FEED_WETH, FEED_UNI) = getOracleConstructorArgs(WETH, UNI);

        // Fork
        vm.createSelectFork({ blockNumber: 21_643_099, urlOrAlias: "mainnet" });

        // Deploy contracts to the fork.
        factory = new LPOracleFactory();
        lpOracle = LPOracle(factory.deployOracle(POOL_WETH_UNI, FEED_WETH, FEED_UNI));

        // Aave contracts
        pool = provider.getPool();
        poolConfigurator = provider.getPoolConfigurator();
        aaveOracle = provider.getPriceOracle();
    }
}
