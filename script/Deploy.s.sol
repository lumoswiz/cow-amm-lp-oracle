// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { LPOracleFactory } from "../src/LPOracleFactory.sol";
import { console } from "forge-std/console.sol";

contract Deploy is BaseScript {
    error UnsupportedChain();

    // Taken from https://github.com/balancer/cow-amm?tab=readme-ov-file#deployments
    function getHelperAddress(uint256 chainId) internal pure returns (address) {
        if (chainId == 1) {
            // Ethereum Mainnet
            return 0x3FF0041A614A9E6Bf392cbB961C97DA214E9CB31;
        } else if (chainId == 11_155_111) {
            // Ethereum Sepolia
            return 0xf5CEd4769ce2c90dfE0084320a0abfB9d99FB91D;
        } else if (chainId == 100) {
            // Gnosis
            return 0x198B6F66dE03540a164ADCA4eC5db2789Fbd4751;
        } else if (chainId == 42_161) {
            // Arbitrum One
            return 0xdB2AeAB529C035469e190310dEf9957ef0398bA8;
        } else if (chainId == 8453) {
            // Base
            return 0x467665D4ae90e7A99c9C9AF785791058426d6eA0;
        }
        revert UnsupportedChain();
    }

    function run() public broadcast {
        address helper = getHelperAddress(block.chainid);
        LPOracleFactory oracleFactory = new LPOracleFactory(helper);
        console.log("Oracle Factory deployed at:", address(oracleFactory));
    }
}
