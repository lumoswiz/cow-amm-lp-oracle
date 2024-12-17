// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

/// @dev Helper contract to obtain price feeds and pools for eth mainnet contracts
contract Addresses {
    /// @dev Deployed BCoWHelper contract address.
    address internal constant HELPER = 0x3FF0041A614A9E6Bf392cbB961C97DA214E9CB31;

    /// @dev Token ids for retrieving deployed price feed and pool addresses.
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address public constant EIGEN = 0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83;

    /// @dev Mapping token id to deployed price feed address.
    mapping(address token => address feed) internal feeds;

    /// @dev Mapping pool id to deployed pool address.
    mapping(bytes32 id => address pool) internal pools;

    constructor() {
        /* Setup feeds  */
        feeds[WETH] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        feeds[UNI] = 0x553303d460EE0afB37EdFf9bE42922D8FF63220e;
        feeds[USDC] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
        feeds[BAL] = 0xdF2917806E30300537aEB49A7663062F4d1F2b5F;
        feeds[AAVE] = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;
        feeds[MKR] = 0xec1D1B3b0443256cc3860e24a46F108e699484Aa;
        feeds[EIGEN] = 0xf2917e602C2dCa458937fad715bb1E465305A4A1;

        /* Setup pools  */
        pools[_getPoolId(WETH, UNI)] = 0xA81b22966f1841E383E69393175E2cc65F0a8854;
        pools[_getPoolId(USDC, WETH)] = 0xf08D4dEa369C456d26a3168ff0024B904F2d8b91;
        pools[_getPoolId(BAL, WETH)] = 0xf8F5B88328DFF3d19E5f4F11A9700293Ac8f638F;
        pools[_getPoolId(AAVE, WETH)] = 0xf706c50513446d709f08d3e5126cd74fb6bFDA19;
        pools[_getPoolId(MKR, WETH)] = 0x9fb7106c879FA48347796171982125a268ff0630;
        pools[_getPoolId(WETH, EIGEN)] = 0xA62E2c047B65aeE3c3Ba7fC7C2BD95C82A514DE2;
    }

    /// @dev Use this function to obtain addresses for constructor args for deploying LPOracle on fork tests.
    function getOracleConstructorArgs(
        address token0,
        address token1
    )
        internal
        view
        returns (address, address, address, address)
    {
        address pool = pools[_getPoolId(token0, token1)];
        address feed0 = feeds[token0];
        address feed1 = feeds[token1];
        require(pool != address(0) && feed0 != address(0) && feed1 != address(0));
        return (pool, HELPER, feed0, feed1);
    }

    function _getPoolId(address token0, address token1) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(token0, token1));
    }
}
