// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { LPOracleFactory } from "../src/LPOracleFactory.sol";
import { console } from "forge-std/console.sol";

contract Deploy is BaseScript {
    function run() public broadcast {
        LPOracleFactory oracleFactory = new LPOracleFactory();
        console.log("Oracle Factory deployed at:", address(oracleFactory));
    }
}
