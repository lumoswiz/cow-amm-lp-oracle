// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { LPOracle } from "./LPOracle.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title LPOracle Factory
/// @notice Factory contract for deploying LPOracle instances with deterministic addresses
contract LPOracleFactory is Ownable {
    error OracleAlreadyExists();
    error DeployFailed();

    /// @notice BCoWHelper contract address used for all oracle deployments
    address public immutable HELPER;

    /// @notice Creation code hash for LPOracle contract
    bytes public constant ORACLE_CREATION_CODE = type(LPOracle).creationCode;

    /// @notice Mapping of pool address to deployed oracle address
    mapping(address pool => address oracle) public getOracle;

    /// @notice Emitted when a new oracle is deployed
    event OracleDeployed(address indexed pool, address indexed oracle);

    /// @param _helper BCoWHelper contract address
    constructor(address _helper) Ownable(msg.sender) {
        HELPER = _helper;
    }

    /// @notice Computes the deterministic address for an oracle before it is deployed
    /// @param pool BCoWPool address
    /// @param feed0 Chainlink USD price feed for pool token at index 0
    /// @param feed1 Chainlink USD price feed for pool token at index 1
    /// @return The address where the oracle would be deployed
    function computeOracleAddress(address pool, address feed0, address feed1) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(pool, feed0, feed1));
        bytes memory bytecode = abi.encodePacked(ORACLE_CREATION_CODE, abi.encode(pool, HELPER, feed0, feed1));

        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff), // 0xff prefix
                            address(this), // Factory contract address
                            salt, // Salt
                            keccak256(bytecode) // Hash of the final bytecode
                        )
                    )
                )
            )
        );
    }

    /// @notice Deploys a new LPOracle with a deterministic address
    /// @param pool BCoWPool address
    /// @param feed0 Chainlink USD price feed for pool token at index 0
    /// @param feed1 Chainlink USD price feed for pool token at index 1
    /// @return oracle Address of the newly deployed oracle
    function deployOracle(address pool, address feed0, address feed1) external returns (address oracle) {
        if (getOracle[pool] != address(0)) revert OracleAlreadyExists();

        bytes32 salt = keccak256(abi.encodePacked(pool, feed0, feed1));
        oracle = address(new LPOracle{ salt: salt }(pool, HELPER, feed0, feed1));

        if (oracle == address(0)) revert DeployFailed();
        getOracle[pool] = oracle;

        emit OracleDeployed(pool, oracle);
    }
}
