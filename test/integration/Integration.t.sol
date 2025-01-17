// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { BaseTest } from "test/Base.t.sol";
import { Addresses } from "test/utils/Addresses.sol";

import { LPOracle } from "src/LPOracle.sol";
import { LPOracleFactory } from "src/LPOracleFactory.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";
import { AggregatorV3Interface } from "@cow-amm/interfaces/AggregatorV3Interface.sol";

import { IPoolAddressesProvider } from "test/integration/aave-v3-contracts/interfaces/IPoolAddressesProvider.sol";
import { IPool } from "test/integration/aave-v3-contracts/interfaces/IPool.sol";
import { IPoolConfigurator } from "test/integration/aave-v3-contracts/interfaces/IPoolConfigurator.sol";
import { IAaveOracle } from "test/integration/aave-v3-contracts/interfaces/IAaveOracle.sol";

import { ConfiguratorInputTypes } from "test/integration/aave-v3-contracts/types/ConfiguratorInputTypes.sol";

contract IntegrationTest is Addresses, BaseTest {
    // LPOracle
    LPOracle internal lpOracle;
    LPOracleFactory internal factory;
    IERC20 internal POOL_WETH_UNI;
    AggregatorV3Interface internal FEED_WETH;
    AggregatorV3Interface internal FEED_UNI;

    // Aave
    IPoolAddressesProvider internal provider = IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);
    IPool internal pool;
    IPoolConfigurator internal poolConfigurator;
    IAaveOracle internal aaveOracle;

    // Pool admin
    address internal constant admin = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;

    // Reserve initialisation addresses
    address internal constant A_TOKEN_IMPL = 0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d;
    address internal constant VARIABLE_DEBT_TOKEN_IMPL = 0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6;
    address internal constant INTEREST_RATE_STRATEGY = 0x9ec6F08190DeA04A54f8Afc53Db96134e5E3FdFB;
    address internal constant INCENTIVES_CONTROLLER = 0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb;
    address internal constant TREASURY = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    function setUp() public virtual override {
        // Fork
        vm.createSelectFork({ blockNumber: 21_643_099, urlOrAlias: "mainnet" });

        // Addresses
        (address _pool, address _feed0, address _feed1) = getOracleConstructorArgs(WETH, UNI);
        POOL_WETH_UNI = IERC20(_pool);
        FEED_WETH = AggregatorV3Interface(_feed0);
        FEED_UNI = AggregatorV3Interface(_feed1);

        // Deploy contracts to the fork.
        factory = new LPOracleFactory();
        lpOracle = LPOracle(factory.deployOracle(_pool, _feed0, _feed1));

        // Aave contracts
        pool = IPool(provider.getPool());
        poolConfigurator = IPoolConfigurator(provider.getPoolConfigurator());
        aaveOracle = IAaveOracle(provider.getPriceOracle());
    }
}
