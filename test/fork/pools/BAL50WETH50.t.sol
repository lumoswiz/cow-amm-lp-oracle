// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { LPOracle_Fork_Test } from "test/fork/LPOracle.t.sol";
import { Addresses } from "test/utils/Addresses.sol";

contract BAL50WETH50_Fork_Test is LPOracle_Fork_Test(Addresses.BAL, Addresses.WETH) { }
