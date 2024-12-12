// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25;

import { BCoWConst } from "@balancer/cow-amm/src/contracts/BCoWConst.sol";
import { BMath } from "@balancer/cow-amm/src/contracts/BMath.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";
import { GPv2Interaction } from "@cowprotocol/libraries/GPv2Interaction.sol";

import { ICOWAMMPoolHelper } from "@cow-amm/interfaces/ICOWAMMPoolHelper.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";

import { IBCoWFactory } from "@balancer/cow-amm/src/interfaces/IBCoWFactory.sol";
import { IBCoWPool } from "@balancer/cow-amm/src/interfaces/IBCoWPool.sol";

/// @dev Adapted from BCoWHelper modified to expose `order` functionality without _prepareSettlement
contract MockBCoWHelper is ICOWAMMPoolHelper, BMath, BCoWConst {
    /**
     * @dev Collection of pool information on a specific token
     * @param token The token all fields depend on
     * @param balance The pool balance for the token
     * @param denormWeight Denormalized weight of the token
     * @param normWeight Normalized weight of the token
     */
    struct Reserves {
        IERC20 token;
        uint256 balance;
        uint256 denormWeight;
        uint256 normWeight;
    }

    /// @notice The app data used by this helper's factory.
    bytes32 internal immutable _APP_DATA;

    /// @inheritdoc ICOWAMMPoolHelper
    // solhint-disable-next-line style-guide-casing
    address public immutable factory;

    /// @notice The input token to the call is not traded on the pool.
    error InvalidToken();

    constructor(address factory_) {
        factory = factory_;
        _APP_DATA = IBCoWFactory(factory_).APP_DATA();
    }

    function order(
        address pool,
        uint256[] calldata prices
    )
        external
        view
        returns (
            GPv2Order.Data memory order_,
            GPv2Interaction.Data[] memory preInteractions,
            GPv2Interaction.Data[] memory postInteractions,
            bytes memory sig
        )
    {
        address[] memory tokenPair = tokens(pool);
        Reserves memory reservesToken0 = _reserves(IBCoWPool(pool), IERC20(tokenPair[0]));
        Reserves memory reservesToken1 = _reserves(IBCoWPool(pool), IERC20(tokenPair[1]));

        (Reserves memory reservesIn, uint256 amountIn, Reserves memory reservesOut) =
            _amountInFromPrices(reservesToken0, reservesToken1, prices);

        return _orderFromBuyAmount(pool, reservesIn, amountIn, reservesOut);
    }

    function _orderFromBuyAmount(
        address,
        Reserves memory reservesIn,
        uint256 amountIn,
        Reserves memory reservesOut
    )
        internal
        view
        returns (
            GPv2Order.Data memory order_,
            GPv2Interaction.Data[] memory preInteractions,
            GPv2Interaction.Data[] memory postInteractions,
            bytes memory sig
        )
    {
        order_ = _rawOrderFrom(reservesIn, amountIn, reservesOut);
        // explicit return
        return (order_, preInteractions, postInteractions, sig);
        // (preInteractions, postInteractions, sig) = _prepareSettlement(pool, order_);
    }

    /// @notice Returns the order that is suggested to be executed to CoW Protocol
    /// for specific reserves of a pool given the current chain state and the
    /// traded amount. The price of the order is on the AMM curve for the traded
    /// amount.
    /// @dev This function takes an input amount and guarantees that the final
    /// order has that input amount and is a valid order. We use `calcOutGivenIn`
    /// to compute the output amount as this is the function used to check that
    /// the CoW Swap order is valid in the contract. It would not be possible to
    /// just define the same function by specifying an output amount and use
    /// `calcInGiveOut`: because of rounding issues the resulting order could be
    /// invalid.
    /// @param reservesIn Data related to the input token of this trade
    /// @param amountIn Token amount moving into the pool for this order
    /// @param reservesOut Data related to the output token of this trade
    /// @return order_ The CoW Protocol JIT order
    function _rawOrderFrom(
        Reserves memory reservesIn,
        uint256 amountIn,
        Reserves memory reservesOut
    )
        internal
        view
        returns (GPv2Order.Data memory order_)
    {
        uint256 amountOut = calcOutGivenIn({
            tokenBalanceIn: reservesIn.balance,
            tokenWeightIn: reservesIn.denormWeight,
            tokenBalanceOut: reservesOut.balance,
            tokenWeightOut: reservesOut.denormWeight,
            tokenAmountIn: amountIn,
            swapFee: 0
        });
        return GPv2Order.Data({
            sellToken: reservesOut.token,
            buyToken: reservesIn.token,
            receiver: GPv2Order.RECEIVER_SAME_AS_OWNER,
            sellAmount: amountOut,
            buyAmount: amountIn,
            validTo: uint32(block.timestamp) + MAX_ORDER_DURATION,
            appData: bytes32(0),
            feeAmount: 0,
            kind: GPv2Order.KIND_SELL,
            partiallyFillable: true,
            sellTokenBalance: GPv2Order.BALANCE_ERC20,
            buyTokenBalance: GPv2Order.BALANCE_ERC20
        });
    }

    /// @notice Returns which trade is suggested to be executed on CoW Protocol
    /// for specific reserves of a pool given the current chain state and prices
    /// @param reservesToken0 Data related to the first token traded in the pool
    /// @param reservesToken1 Data related to the second token traded in the pool
    /// @param prices supplied for determining the order; the format is specified
    /// in the `order` function
    /// @return reservesIn Data related to the input token in the trade
    /// @return amountIn How much input token should be trated
    /// @return reservesOut Data related to the input token in the trade
    function _amountInFromPrices(
        Reserves memory reservesToken0,
        Reserves memory reservesToken1,
        uint256[] calldata prices
    )
        internal
        pure
        returns (Reserves memory reservesIn, uint256 amountIn, Reserves memory reservesOut)
    {
        reservesOut = reservesToken0;
        reservesIn = reservesToken1;

        // The out amount is computed according to the following formula:
        // aO = amountOut
        // bI = reservesIn.balance                   bO * wI - p * bI * wO
        // bO = reservesOut.balance            aO =  ---------------------
        // wI = reservesIn.denormWeight                     wI + wO
        // wO = reservesOut.denormWeight
        // p  = priceNumerator / priceDenominator
        //
        // Note that in the code we use normalized weights instead of computing the
        // full expression from raw weights. Since BCoW pools support only two
        // tokens, this is equivalent to assuming that wI + wO = 1.

        // The price of this function is expressed as amount of token1 per amount
        // of token0. The `prices` vector is expressed the other way around, as
        // confirmed by dimensional analysis of the expression above.
        uint256 priceNumerator = prices[1]; // x token = sell token = out amount
        uint256 priceDenominator = prices[0];
        uint256 balanceOutTimesWeightIn = bmul(reservesOut.balance, reservesIn.normWeight);
        uint256 balanceInTimesWeightOut = bmul(reservesIn.balance, reservesOut.normWeight);

        // This check compares the (weight-adjusted) pool spot price with the input
        // price. The formula for the pool's spot price can be found in the
        // definition of `calcSpotPrice`, assuming no swap fee. The comparison is
        // derived from the following expression:
        //
        //       priceNumerator    bO / wO      /   bO * wI  \
        //      ---------------- > -------     |  = -------   |
        //      priceDenominator   bI / wI      \   bI * wO  /
        //
        // This inequality also guarantees that the amount out is positive: the
        // amount out is positive if and only if this inequality is false, meaning
        // that if the following condition matches then we want to invert the sell
        // and buy tokens.
        if (bmul(balanceInTimesWeightOut, priceNumerator) > bmul(balanceOutTimesWeightIn, priceDenominator)) {
            (reservesOut, reservesIn) = (reservesIn, reservesOut);
            (balanceOutTimesWeightIn, balanceInTimesWeightOut) = (balanceInTimesWeightOut, balanceOutTimesWeightIn);
            (priceNumerator, priceDenominator) = (priceDenominator, priceNumerator);
        }
        uint256 par = bdiv(bmul(balanceInTimesWeightOut, priceNumerator), priceDenominator);
        uint256 amountOut = balanceOutTimesWeightIn - par;
        amountIn = calcInGivenOut({
            tokenBalanceIn: reservesIn.balance,
            tokenWeightIn: reservesIn.denormWeight,
            tokenBalanceOut: reservesOut.balance,
            tokenWeightOut: reservesOut.denormWeight,
            tokenAmountOut: amountOut,
            swapFee: 0
        });
    }

    /// @inheritdoc ICOWAMMPoolHelper
    function tokens(address pool) public view virtual returns (address[] memory tokens_) {
        // reverts in case pool is not deployed by the helper's factory
        if (!IBCoWFactory(factory).isBPool(pool)) {
            revert PoolDoesNotExist();
        }

        // call reverts with `BPool_PoolNotFinalized()` in case pool is not finalized
        tokens_ = IBCoWPool(pool).getFinalTokens();

        // reverts in case pool is not supported (non-2-token pool)
        if (tokens_.length != 2) {
            revert PoolDoesNotExist();
        }
    }

    /// @notice Returns information on pool reserves for a specific pool and token
    /// @dev This is mostly used for the readability of grouping all parameters
    /// relative to the same token are grouped together in the same variable
    /// @param pool The pool with the funds
    /// @param token The token on which to recover information
    /// @return Parameters relative to the token reserves in the pool
    function _reserves(IBCoWPool pool, IERC20 token) internal view returns (Reserves memory) {
        uint256 balance = token.balanceOf(address(pool));
        uint256 normalizedWeight = pool.getNormalizedWeight(address(token));
        uint256 denormalizedWeight = pool.getDenormalizedWeight(address(token));
        return
            Reserves({ token: token, balance: balance, denormWeight: denormalizedWeight, normWeight: normalizedWeight });
    }
}
