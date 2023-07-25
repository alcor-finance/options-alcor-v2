// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {FullMath} from "../FullMath.sol";
import {SqrtPriceMath} from "../SqrtPriceMath.sol";

import {Polynomials} from "./Polynomials.sol";

import {Tick} from "./AlcorTick.sol";

import {TickLibrary} from "./TickLibrary.sol";

import "hardhat/console.sol";

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    // / @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    // / @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    // / @param sqrtRatioCurrentX96 The current sqrt price of the pool
    // / @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    // / @param amountRemaining How much input or output amount is remaining to be swapped in/out
    // / @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    // / @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    // / @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    // / @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    // / @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        // uint160 sqrtRatioCurrentX96,
        // uint160 sqrtRatioTargetX96,
        int24 tickCurrent,
        int24 tickTarget,
        Polynomials.AlphasVector memory alphasVector,
        uint256 amountRemaining,
        uint24 feePips
    )
        internal
        view
        returns (
            // uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        bool isBuying = tickTarget >= tickCurrent;
        // uint256 amountRemainingLessFee = FullMath.mulDiv(
        //     amountRemaining,
        //     1e6 - feePips,
        //     1e6
        // );
        // // todo: take account if tick is not fully crossed
        // feeAmount = amountRemaining - amountRemainingLessFee;

        int24 nextTick = isBuying ? tickCurrent + 1 : tickCurrent - 1;
        uint256 local_C0 = TickLibrary.getPriceAtTick(tickCurrent);
        uint256 local_CI = TickLibrary.getPriceAtTick(nextTick);

        console.log("local_C0: %s", local_C0);
        console.log("local_CI: %s", local_CI);

        // THIS WORKS ONLY FOR BUYING OPTIONS
        amountOut = uint256(
            Polynomials.calculate_dy_alphas(local_CI, local_C0, alphasVector)
        );

        amountIn = uint256(
            Polynomials.calculate_dx_alphas(local_CI, local_C0, alphasVector)
        );

        if (amountRemaining < amountOut) {
            amountIn = FullMath.mulDiv(amountIn, amountRemaining, amountOut);
            feeAmount = FullMath.mulDiv(amountRemaining, 1e6 - feePips, 1e6);
            amountOut = amountRemaining;
        } else {
            feeAmount = FullMath.mulDiv(amountOut, 1e6 - feePips, 1e6);
        }

        // bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

        // get the input/output amounts
        // if (zeroForOne) {
        //     amountIn = max && exactIn
        //         ? amountIn
        //         : SqrtPriceMath.getAmount0Delta(
        //             sqrtRatioNextX96,
        //             sqrtRatioCurrentX96,
        //             liquidity,
        //             true
        //         );
        //     amountOut = max && !exactIn
        //         ? amountOut
        //         : SqrtPriceMath.getAmount1Delta(
        //             sqrtRatioNextX96,
        //             sqrtRatioCurrentX96,
        //             liquidity,
        //             false
        //         );
        // } else {
        //     amountIn = max && exactIn
        //         ? amountIn
        //         : SqrtPriceMath.getAmount1Delta(
        //             sqrtRatioCurrentX96,
        //             sqrtRatioNextX96,
        //             liquidity,
        //             true
        //         );
        //     amountOut = max && !exactIn
        //         ? amountOut
        //         : SqrtPriceMath.getAmount0Delta(
        //             sqrtRatioCurrentX96,
        //             sqrtRatioNextX96,
        //             liquidity,
        //             false
        //         );
        // }

        // // cap the output amount to not exceed the remaining output amount
        // if (!exactIn && amountOut > uint256(-amountRemaining)) {
        //     amountOut = uint256(-amountRemaining);
        // }

        // if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
        //     // we didn't reach the target, so take the remainder of the maximum input as fee
        //     feeAmount = uint256(amountRemaining) - amountIn;
        // } else {
        //     feeAmount = FullMath.mulDivRoundingUp(
        //         amountIn,
        //         feePips,
        //         1e6 - feePips
        //     );
        // }
    }
}
