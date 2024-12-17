// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { Description_Fork_Test } from "test/fork/Description.t.sol";
import { Addresses } from "test/utils/Addresses.sol";

contract WETH50UNI50_Description_Fork_Test is Description_Fork_Test(Addresses.WETH, Addresses.UNI) { }
