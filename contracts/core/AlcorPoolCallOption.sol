// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
pragma abicoder v2;

// import "../dependencies/ReentrancyGuard.sol";

import "../libraries/TransferHelper.sol";

import "./AlcorVanillaOption.sol";

import "hardhat/console.sol";

contract AlcorPoolCallOption is AlcorVanillaOption {
    using SafeCast for uint256;
    using SafeCast for int256;
    using Tick for mapping(int24 => Tick.Info);
    using TickBitmap for mapping(int16 => uint256);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    using Oracle for Oracle.Observation[65535];

    uint256 public feeGrowthGlobal1X128;

    constructor() {
        // int24 _tickSpacing;
        (
            factory,
            optionMainInfo.token0,
            optionMainInfo.token1,
            optionMainInfo.expiration,
            optionMainInfo.optionStrikePriceX96,
            optionMainInfo.poolFee,
            tickSpacing
        ) = IAlcorPoolDeployer(msg.sender).parameters();

        // tickSpacing = _tickSpacing;

        optionMainInfo.isCallOption = true;

        // maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(
        //     tickSpacing
        // );
    }

    /// @dev Effect some changes to a position
    /// @param params the position details and the change to the position's liquidity to effect
    /// @return position a storage pointer referencing the position with the given owner and tick range
    /// @return amount0 the amount of token0 owed to the pool, negative if the pool should pay the recipient
    /// @return amount1 the amount of token1 owed to the pool, negative if the pool should pay the recipient
    // function _modifyPosition(
    //     ModifyPositionParams memory params
    // )
    //     private
    //     noDelegateCall
    //     returns (Position.Info storage position, int256 amount0, int256 amount1)
    // {
    //     // checkTicks(params.tickLower, params.tickUpper);

    //     Slot0 memory _slot0 = slot0; // SLOAD for gas optimization

    //     position = _updatePosition(
    //         params.owner,
    //         // params.tickLower,
    //         params.tickUpper,
    //         params.alphasDelta,
    //         _slot0.tick
    //     );

    //     if (params.liquidityDelta != 0) {
    //         if (_slot0.tick < params.tickLower) {
    //             // current tick is below the passed range; liquidity can only become in range by crossing from left to
    //             // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
    //             amount0 = SqrtPriceMath.getAmount0Delta(
    //                 TickMath.getSqrtRatioAtTick(params.tickLower),
    //                 TickMath.getSqrtRatioAtTick(params.tickUpper),
    //                 params.liquidityDelta
    //             );
    //         } else if (_slot0.tick < params.tickUpper) {
    //             // current tick is inside the passed range
    //             uint128 liquidityBefore = liquidity; // SLOAD for gas optimization

    //             // write an oracle entry
    //             (
    //                 slot0.observationIndex,
    //                 slot0.observationCardinality
    //             ) = observations.write(
    //                 _slot0.observationIndex,
    //                 _blockTimestamp(),
    //                 _slot0.tick,
    //                 liquidityBefore,
    //                 _slot0.observationCardinality,
    //                 _slot0.observationCardinalityNext
    //             );

    //             amount0 = SqrtPriceMath.getAmount0Delta(
    //                 _slot0.sqrtPriceX96,
    //                 TickMath.getSqrtRatioAtTick(params.tickUpper),
    //                 params.liquidityDelta
    //             );
    //             amount1 = SqrtPriceMath.getAmount1Delta(
    //                 TickMath.getSqrtRatioAtTick(params.tickLower),
    //                 _slot0.sqrtPriceX96,
    //                 params.liquidityDelta
    //             );

    //             liquidity = params.liquidityDelta < 0
    //                 ? liquidityBefore - uint128(-params.liquidityDelta)
    //                 : liquidityBefore + uint128(params.liquidityDelta);
    //         } else {
    //             // current tick is above the passed range; liquidity can only become in range by crossing from right to
    //             // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
    //             amount1 = SqrtPriceMath.getAmount1Delta(
    //                 TickMath.getSqrtRatioAtTick(params.tickLower),
    //                 TickMath.getSqrtRatioAtTick(params.tickUpper),
    //                 params.liquidityDelta
    //             );
    //         }
    //     }
    // }

    /// @dev Gets and updates a position with the given alphas vector
    /// @param owner the owner of the position
    /// @param tickUpper the upper tick of the position's tick range
    /// @param tick the current tick, passed to avoid sloads
    function _updatePosition(
        address owner,
        // int24 tickLower,
        int24 tickUpper,
        Tick.AlphasVector memory alphasDelta,
        int24 tick
    ) private returns (Position.Info storage position) {
        int24 tickLower;
        if ((2 * tick - tickUpper) > 0) {
            (2 * tick - tickUpper);
        } else {
            0;
        }

        // here we use the current tick as the lower tick
        position = positions.get(owner, tick, tickUpper);

        uint256 _feeGrowthGlobal1X128 = feeGrowthGlobal1X128; // SLOAD for gas optimization

        // if we need to update the ticks, do it
        bool flippedMiddle;
        bool flippedUpper;
        //
        bool flippedLower;
        if (
            alphasDelta.alpha1 != 0 &&
            alphasDelta.alpha2 != 0 &&
            alphasDelta.alpha3 != 0 &&
            alphasDelta.alpha4 != 0
        ) {
            uint32 time = _blockTimestamp();
            (
                int56 tickCumulative,
                uint160 secondsPerLiquidityCumulativeX128
            ) = observations.observeSingle(
                    time,
                    0,
                    slot0.tick,
                    slot0.observationIndex,
                    liquidity,
                    slot0.observationCardinality
                );

            flippedMiddle = ticks.update(
                tick,
                tick,
                alphasDelta,
                0, // _feeGrowthGlobal0X128
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                false
            );
            flippedUpper = ticks.update(
                tickUpper,
                tick,
                Tick.AlphasVector({
                    alpha1: -alphasDelta.alpha1,
                    alpha2: -alphasDelta.alpha2,
                    alpha3: -alphasDelta.alpha3,
                    alpha4: -alphasDelta.alpha4
                }),
                0, // _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                true
            );
            flippedLower = ticks.update(
                tickLower,
                tick,
                Tick.AlphasVector({
                    alpha1: -alphasDelta.alpha1,
                    alpha2: -alphasDelta.alpha2,
                    alpha3: -alphasDelta.alpha3,
                    alpha4: -alphasDelta.alpha4
                }),
                0, // _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                true
            );

            if (flippedLower) {
                tickBitmap.flipTick(tickLower, tickSpacing);
            }
            if (flippedMiddle) {
                tickBitmap.flipTick(tick, tickSpacing);
            }
            if (flippedUpper) {
                tickBitmap.flipTick(tickUpper, tickSpacing);
            }
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = ticks
            .getFeeGrowthInside(
                tick, // tickLower,
                tickUpper,
                tick,
                0, //_feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128
            );

        position.update(
            alphasDelta,
            feeGrowthInside0X128,
            feeGrowthInside1X128
        );

        // clear any tick data that is no longer needed
        if (
            alphasDelta.alpha1 < 0 &&
            alphasDelta.alpha2 < 0 &&
            alphasDelta.alpha3 < 0 &&
            alphasDelta.alpha4 < 0
        ) {
            if (flippedLower) {
                ticks.clear(tickLower);
            }
            if (flippedMiddle) {
                ticks.clear(tick);
            }
            if (flippedUpper) {
                ticks.clear(tickUpper);
            }
        }
    }

    // the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        uint256 contractsAmountRemaining;
        // the amount already swapped out/in of the output/input asset
        uint256 cost_token0;
        // amount of input token paid as protocol fee
        uint256 protocolFee_token0;
    }

    struct StepComputations {
        uint256 contractPrice;
        address signer;
        uint256 contractsDelta;
        uint256 step_cost_token0;
    }
}
