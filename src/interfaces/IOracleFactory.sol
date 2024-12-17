// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

interface ILPOracleFactory {
    function deployOracle(address pool, address feed0, address feed1) external returns (address oracle);
    function computeOracleAddress(address pool, address feed0, address feed1) external view returns (address);
    function getOracle(address pool) external view returns (address);
}
