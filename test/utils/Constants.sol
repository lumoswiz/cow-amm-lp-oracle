// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { BConst } from "@balancer/cow-amm/src/contracts/BConst.sol";

contract Constants is BConst {
    uint256 public constant DEC_1_2024 = 1_733_011_200;

    uint8 public constant MAX_UINT8 = type(uint8).max;
    uint256 public constant MAX_UINT256 = type(uint256).max;
}
