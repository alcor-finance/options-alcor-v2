// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {SafeCast} from "../SafeCast.sol";
// import {FullMath} from "../FullMath.sol";

import {PRBMathSD59x18} from "../../dependencies/prb-math/contracts/PRBMathSD59x18.sol";

import {TickMath} from "../TickMath.sol";

import {Polynomials} from "./Polynomials.sol";

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations
library Tick {
    error LO();

    using SafeCast for int256;
    // using FullMath for uint256;

    using PRBMathSD59x18 for int256;

    struct FeeGrowthX128 {
        int256 C3;
        int256 C2;
        int256 C1;
        int256 C0;
    }

    // info stored for each initialized individual tick
    struct Info {
        // the vector of alphas that should be added when crossing the tick in the positive direction
        // if the tick is crossed from right to left, subtract the vector instead
        Polynomials.AlphasVector alphasDelta;
        // the total position liquidity that references this tick
        // uint128 liquidityGross;
        // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        // int128 liquidityNet;
        // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        // uint256 feeGrowthOutside0X128;
        // uint256 feeGrowthOutside1X128;
        FeeGrowthX128 feeGrowthOutsideX128;
        // the cumulative tick value on the other side of the tick
        int56 tickCumulativeOutside;
        // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint160 secondsPerLiquidityOutsideX128;
        // the seconds spent on the other side of the tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint32 secondsOutside;
        // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
        // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
        bool initialized;
    }

    // /// @notice Derives max liquidity per tick from given tick spacing
    // /// @dev Executed within the pool constructor
    // /// @param tickSpacing The amount of required tick separation, realized in multiples of `tickSpacing`
    // ///     e.g., a tickSpacing of 3 requires ticks to be initialized every 3rd tick i.e., ..., -6, -3, 0, 3, 6, ...
    // /// @return The max liquidity per tick
    // function tickSpacingToMaxLiquidityPerTick(
    //     int24 tickSpacing
    // ) internal pure returns (uint128) {
    //     unchecked {
    //         int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
    //         int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
    //         uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
    //         return type(uint128).max / numTicks;
    //     }
    // }

    /// @notice Retrieves fee growth data
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @param tickCurrent The current tick
    // /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    // /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    // /// @return feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    // /// @return feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function getFeeGrowthInside(
        mapping(int24 => Tick.Info) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        Polynomials.AlphasVector memory alphasDelta,
        FeeGrowthX128 memory feeGrowthGlobalX128
    )
        internal
        view
        returns (uint256 feeGrowthInsideX128)
    // uint256 feeGrowthInside1X128
    {
        unchecked {
            Info storage lower = self[tickLower];
            Info storage upper = self[tickUpper];

            // calculate fee growth below
            FeeGrowthX128 memory feeGrowthBelowX128;
            // uint256 feeGrowthBelow1X128;
            if (tickCurrent >= tickLower) {
                feeGrowthBelowX128 = lower.feeGrowthOutsideX128;
                // feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
            } else {
                feeGrowthBelowX128 = FeeGrowthX128({
                    C3: feeGrowthGlobalX128.C3 - lower.feeGrowthOutsideX128.C3,
                    C2: feeGrowthGlobalX128.C2 - lower.feeGrowthOutsideX128.C2,
                    C1: feeGrowthGlobalX128.C1 - lower.feeGrowthOutsideX128.C1,
                    C0: feeGrowthGlobalX128.C0 - lower.feeGrowthOutsideX128.C0
                });
                // feeGrowthBelow0X128 =
                //     feeGrowthGlobal0X128 -
                //     lower.feeGrowthOutside0X128;
                // feeGrowthBelow1X128 =
                //     feeGrowthGlobal1X128 -
                //     lower.feeGrowthOutside1X128;
            }

            // calculate fee growth above
            // uint256 feeGrowthAbove0X128;
            // uint256 feeGrowthAbove1X128;
            FeeGrowthX128 memory feeGrowthAboveX128;

            if (tickCurrent < tickUpper) {
                feeGrowthAboveX128 = upper.feeGrowthOutsideX128;
                // feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
            } else {
                feeGrowthAboveX128 = FeeGrowthX128({
                    C3: feeGrowthGlobalX128.C3 - upper.feeGrowthOutsideX128.C3,
                    C2: feeGrowthGlobalX128.C2 - upper.feeGrowthOutsideX128.C2,
                    C1: feeGrowthGlobalX128.C1 - upper.feeGrowthOutsideX128.C1,
                    C0: feeGrowthGlobalX128.C0 - upper.feeGrowthOutsideX128.C0
                });
                // feeGrowthAbove0X128 =
                //     feeGrowthGlobal0X128 -
                //     upper.feeGrowthOutside0X128;
                // feeGrowthAbove1X128 =
                //     feeGrowthGlobal1X128 -
                //     upper.feeGrowthOutside1X128;
            }

            // we cast to uint256, because the correct fees are positive
            feeGrowthInsideX128 = uint256(
                (feeGrowthGlobalX128.C3 -
                    feeGrowthBelowX128.C3 -
                    feeGrowthAboveX128.C3).mul(alphasDelta.alpha1) +
                    (feeGrowthGlobalX128.C2 -
                        feeGrowthBelowX128.C2 -
                        feeGrowthAboveX128.C2).mul(alphasDelta.alpha2) +
                    (feeGrowthGlobalX128.C1 -
                        feeGrowthBelowX128.C1 -
                        feeGrowthAboveX128.C1).mul(alphasDelta.alpha3) +
                    (feeGrowthGlobalX128.C0 -
                        feeGrowthBelowX128.C0 -
                        feeGrowthAboveX128.C0).mul(alphasDelta.alpha4)
            );

            // feeGrowthInside0X128 =
            //     feeGrowthGlobal0X128 -
            //     feeGrowthBelow0X128 -
            //     feeGrowthAbove0X128;
            // feeGrowthInside1X128 =
            //     feeGrowthGlobal1X128 -
            //     feeGrowthBelow1X128 -
            //     feeGrowthAbove1X128;
        }
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be updated
    /// @param tickCurrent The current tick
    // /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    // /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulativeX128 The all-time seconds per max(1, liquidity) of the pool
    /// @param tickCumulative The tick * time elapsed since the pool was first initialized
    /// @param time The current block timestamp cast to a uint32
    /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        Polynomials.AlphasVector memory alphasDelta,
        FeeGrowthX128 memory feeGrowthGlobalX128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time,
        bool upper
    )
        internal
        returns (
            // uint128 maxLiquidity
            bool flipped
        )
    {
        Tick.Info storage info = self[tick];

        Polynomials.AlphasVector memory alphasDeltaBefore = info.alphasDelta;
        Polynomials.AlphasVector memory alphasDeltaAfter = Polynomials
            .addAlphasVectors(alphasDeltaBefore, alphasDelta);

        // if (liquidityGrossAfter > maxLiquidity) revert LO();

        flipped =
            (alphasDeltaAfter.alpha1 == 0 &&
                alphasDeltaAfter.alpha2 == 0 &&
                alphasDeltaAfter.alpha3 == 0 &&
                alphasDeltaAfter.alpha4 == 0) !=
            (alphasDeltaBefore.alpha1 == 0 &&
                alphasDeltaBefore.alpha2 == 0 &&
                alphasDeltaBefore.alpha3 == 0 &&
                alphasDeltaBefore.alpha4 == 0);
        // flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (
            alphasDeltaBefore.alpha1 == 0 &&
            alphasDeltaBefore.alpha2 == 0 &&
            alphasDeltaBefore.alpha3 == 0 &&
            alphasDeltaBefore.alpha4 == 0
        ) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (tick <= tickCurrent) {
                info.feeGrowthOutsideX128 = feeGrowthGlobalX128;
                // info.feeGrowthOutside1X128 = feeGrowthGlobal1X128;
                info
                    .secondsPerLiquidityOutsideX128 = secondsPerLiquidityCumulativeX128;
                info.tickCumulativeOutside = tickCumulative;
                info.secondsOutside = time;
            }
            info.initialized = true;
        }

        info.alphasDelta = alphasDeltaAfter;

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        // info.liquidityNet = upper
        //     ? info.liquidityNet - liquidityDelta
        //     : info.liquidityNet + liquidityDelta;
    }

    /// @notice Clears tick data
    /// @param self The mapping containing all initialized tick information for initialized ticks
    /// @param tick The tick that will be cleared
    function clear(
        mapping(int24 => Tick.Info) storage self,
        int24 tick
    ) internal {
        delete self[tick];
    }

    /// @notice Transitions to next tick as needed by price movement
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The destination tick of the transition
    // /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    // /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulativeX128 The current seconds per liquidity
    /// @param tickCumulative The tick * time elapsed since the pool was first initialized
    /// @param time The current block.timestamp
    // /// @return liquidityNet The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    function cross(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        // uint256 feeGrowthGlobal0X128,
        // uint256 feeGrowthGlobal1X128,
        FeeGrowthX128 memory feeGrowthGlobalX128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time
    ) internal returns (Polynomials.AlphasVector memory alphasDelta) {
        unchecked {
            Tick.Info storage info = self[tick];

            info.feeGrowthOutsideX128 = FeeGrowthX128({
                C3: info.feeGrowthOutsideX128.C3 - feeGrowthGlobalX128.C3,
                C2: info.feeGrowthOutsideX128.C2 - feeGrowthGlobalX128.C2,
                C1: info.feeGrowthOutsideX128.C1 - feeGrowthGlobalX128.C1,
                C0: info.feeGrowthOutsideX128.C0 - feeGrowthGlobalX128.C0
            });
            // info.feeGrowthOutside0X128 =
            //     feeGrowthGlobal0X128 -
            //     info.feeGrowthOutside0X128;
            // info.feeGrowthOutside1X128 =
            //     feeGrowthGlobal1X128 -
            //     info.feeGrowthOutside1X128;
            info.secondsPerLiquidityOutsideX128 =
                secondsPerLiquidityCumulativeX128 -
                info.secondsPerLiquidityOutsideX128;
            info.tickCumulativeOutside =
                tickCumulative -
                info.tickCumulativeOutside;
            info.secondsOutside = time - info.secondsOutside;

            alphasDelta = info.alphasDelta;
            // liquidityNet = info.liquidityNet;
        }
    }
}
