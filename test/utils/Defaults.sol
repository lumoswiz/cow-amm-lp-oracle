// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { Constants } from "test/utils/Constants.sol";
import { Mocks, OrderParams, TokenParams, FeedParams } from "test/utils/Types.sol";

contract Defaults is Constants {
    uint256 public constant TOKEN0_BALANCE = 1e18;
    uint256 public constant TOKEN1_BALANCE = 1e18;
    uint256 public constant NORMALIZED_WEIGHT = 0.5e18;
    uint256 public constant DENORMALIZED_WEIGHT = 1e18;
    bytes32 public constant APP_DATA = keccak256("APP_DATA");
    uint256 public constant LP_TOKEN_SUPPLY = 1000e18;
    uint256 public constant WEIGHT_20 = 0.2e18;
    uint256 public constant WEIGHT_50 = 0.5e18;
    uint256 public constant WEIGHT_80 = 0.8e18;

    uint8 public constant FEED_DECIMALS = 8;

    int256 public constant ANSWER0 = 4000e8;
    int256 public constant ANSWER1 = 1e8;

    Mocks private mocks;

    /*----------------------------------------------------------*|
    |*  # HELPERS                                               *|
    |*----------------------------------------------------------*/

    function setMocks(Mocks memory mocks_) public {
        mocks = mocks_;
    }

    /*----------------------------------------------------------*|
    |*  # STRUCTS                                               *|
    |*----------------------------------------------------------*/

    function mockOrderParamsCustomValues(
        uint256 token0Balance,
        uint256 token1Balance,
        uint256 token0Weight
    )
        public
        view
        returns (OrderParams memory)
    {
        return OrderParams({
            pool: mocks.pool,
            factory: mocks.factory,
            token0: TokenParams({
                addr: mocks.token0,
                balance: token0Balance,
                normWeight: token0Weight,
                denormWeight: DENORMALIZED_WEIGHT
            }),
            token1: TokenParams({
                addr: mocks.token1,
                balance: token1Balance,
                normWeight: BONE - token0Weight,
                denormWeight: DENORMALIZED_WEIGHT
            })
        });
    }

    function mockFeedParams(
        int256 answer0,
        int256 answer1
    )
        public
        view
        returns (FeedParams memory, FeedParams memory)
    {
        return (
            FeedParams({ addr: mocks.feed0, decimals: FEED_DECIMALS, answer: answer0, updatedAt: block.timestamp }),
            FeedParams({ addr: mocks.feed1, decimals: FEED_DECIMALS, answer: answer1, updatedAt: block.timestamp })
        );
    }
}
