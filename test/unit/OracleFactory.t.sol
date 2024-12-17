// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { console } from "forge-std/console.sol";
import { LPOracleFactory } from "src/LPOracleFactory.sol";
import { ILPOracleFactory } from "src/interfaces/IOracleFactory.sol";
import { LPOracle } from "src/LPOracle.sol";

contract OracleFactoryBenchmark is BaseTest {
    ILPOracleFactory public factory;

    function setUp() public override {
        // Call the setUp() function from BaseTest
        super.setUp();

        // Additional setup logic specific to OracleFactoryBenchmark
        factory = new LPOracleFactory(address(helper));
    }

    // Add this struct at the contract level
    struct BenchmarkResult {
        uint256 gasUsedDeploy;
        uint256 gasUsedCompute;
        uint256 reads;
        uint256 writes;
    }

    function _benchmarkFactory(ILPOracleFactory _factory) private returns (BenchmarkResult memory) {
        vm.record();
        uint256 gasStart = gasleft();
        _factory.deployOracle(MOCK_POOL, FEED0, FEED1);
        uint256 gasUsed = gasStart - gasleft();

        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(factory));

        uint256 gasStart2 = gasleft();
        _factory.computeOracleAddress(MOCK_POOL, FEED0, FEED1);
        uint256 gasUsed2 = gasStart2 - gasleft();
        return BenchmarkResult({
            gasUsedDeploy: gasUsed,
            gasUsedCompute: gasUsed2,
            reads: reads.length,
            writes: writes.length
        });
    }

    function _logBenchmarkResult(string memory name, BenchmarkResult memory result) private view {
        console.log("===", name, "===");
        console.log("- Gas Used Deploy:", result.gasUsedDeploy);
        console.log("- Gas Used Compute:", result.gasUsedCompute);
        console.log("- Storage Reads:", result.reads);
        console.log("- Storage Writes:", result.writes);
        console.log("");
    }

    function test_BenchmarkDeployment() public {
        BenchmarkResult memory result = _benchmarkFactory(factory);
        _logBenchmarkResult("Factory", result);
    }

    function test_Benchmark_VerifyAddressConsistency() public {
        // Deploy oracles
        address oracle = factory.deployOracle(MOCK_POOL, FEED0, FEED1);

        // Verify computed addresses match deployed addresses
        assertEq(factory.computeOracleAddress(MOCK_POOL, FEED0, FEED1), oracle, "Factory");
    }

    function test_DeployedOracleIsValid() public {
        // Deploy oracle
        address oracleAddr = factory.deployOracle(MOCK_POOL, FEED0, FEED1);

        // Verify oracle was deployed successfully
        assertTrue(oracleAddr != address(0), "Oracle not deployed");

        // Cast to LPOracle to verify interface
        LPOracle oracle = LPOracle(oracleAddr);

        // Verify oracle initialization parameters
        assertEq(oracle.POOL(), MOCK_POOL, "Wrong pool address");
        assertEq(address(oracle.HELPER()), address(helper), "Wrong helper address");
        assertEq(address(oracle.FEED0()), FEED0, "Wrong feed0 address");
        assertEq(address(oracle.FEED1()), FEED1, "Wrong feed1 address");

        // TODO(bh2smith): We would need to add some additional mocking to test this functionality.
        // // Verify oracle can be called (this will revert if oracle is not properly initialized)
        // try oracle.latestRoundData() returns (uint80, int256, uint256, uint256, uint80) {
        //     // Price retrieval successful
        // } catch Error(string memory reason) {
        //     assertFalse(true, string.concat("Oracle latestRoundData() failed: ", reason));
        // } catch {
        //     assertFalse(true, "Oracle latestRoundData() failed with unknown error");
        // }

        // Verify oracle is registered in factory
        assertEq(factory.getOracle(MOCK_POOL), oracleAddr, "Oracle not registered in factory");
        console.log("Oracle address:", oracleAddr);
    }

    function test_CannotDeployDuplicateOracle() public {
        // Deploy first oracle
        factory.deployOracle(MOCK_POOL, FEED0, FEED1);

        // Attempt to deploy second oracle for same pool
        vm.expectRevert(abi.encodeWithSignature("OracleAlreadyExists()"));
        factory.deployOracle(MOCK_POOL, FEED0, FEED1);
    }
}
