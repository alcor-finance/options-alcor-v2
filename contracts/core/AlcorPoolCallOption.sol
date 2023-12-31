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

    error M0();
    error M1();
    error AS();

    event Mint(
        address indexed sender,
        // address indexed recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint256 amount
    );

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

    /// @dev Gets and updates a position with the given alphas vector
    /// @param owner the owner of the position
    /// @param tickUpper the upper tick of the position's tick range
    /// @param tick the current tick, passed to avoid sloads
    function _updatePosition(
        address owner,
        // int24 tickLower,
        int24 tickUpper,
        Polynomials.AlphasVector memory alphasDelta,
        int24 tick
    ) private returns (Position.Info storage position) {
        int24 tickLower;
        if ((2 * tick - tickUpper) > 0) {
            (2 * tick - tickUpper);
        }

        // here we use the current tick as the lower tick
        position = positions.get(owner, tick, tickUpper);

        Tick.FeeGrowthX128 memory _feeGrowthGlobalX128 = feeGrowthGlobalX128; // SLOAD for gas optimization

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
            int56 tickCumulative = 0;
            uint160 secondsPerLiquidityCumulativeX128 = 0;
            // (
            //     int56 tickCumulative,
            //     uint160 secondsPerLiquidityCumulativeX128
            // ) = observations.observeSingle(
            //         time,
            //         0,
            //         slot0.tick,
            //         slot0.observationIndex,
            //         liquidity,
            //         slot0.observationCardinality
            //     );

            flippedMiddle = ticks.update(
                tick,
                tick,
                alphasDelta,
                _feeGrowthGlobalX128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                false
            );
            flippedUpper = ticks.update(
                tickUpper,
                tick,
                Polynomials.AlphasVector({
                    alpha1: -alphasDelta.alpha1,
                    alpha2: -alphasDelta.alpha2,
                    alpha3: -alphasDelta.alpha3,
                    alpha4: -alphasDelta.alpha4
                }),
                _feeGrowthGlobalX128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                true
            );
            flippedLower = ticks.update(
                tickLower,
                tick,
                Polynomials.AlphasVector({
                    alpha1: -alphasDelta.alpha1,
                    alpha2: -alphasDelta.alpha2,
                    alpha3: -alphasDelta.alpha3,
                    alpha4: -alphasDelta.alpha4
                }),
                _feeGrowthGlobalX128,
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

        uint256 feeGrowthInsideX128 = ticks.getFeeGrowthInside(
            tick, // tickLower,
            tickUpper,
            tick,
            alphasDelta,
            _feeGrowthGlobalX128
        );

        position.update(alphasDelta, tick, feeGrowthInsideX128);

        console.log("position alpha 1:");
        console.logInt(position.positionAlphas.alpha1);
        console.log("position alpha 2:");
        console.logInt(position.positionAlphas.alpha2);
        console.log("position alpha 3:");
        console.logInt(position.positionAlphas.alpha3);
        console.log("position alpha 4:");
        console.logInt(position.positionAlphas.alpha4);
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

    function depositForSelling(
        // address recipient,
        // int24 tickLower,
        int24 tickUpper,
        uint256 z0
    )
        external
        lock
        noDelegateCall
        returns (Polynomials.AlphasVector memory alphasVector)
    {
        require(z0 > 0, "z0 is zero");
        int24 tickLower = slot0.tick;
        require(tickLower < tickUpper, "tickLower must be >= tickUpper");

        uint256 C0 = TickLibrary.getPriceAtTick(tickLower);
        uint256 CI = TickLibrary.getPriceAtTick(tickUpper);
        console.log("C0: ", C0);
        console.log("CI: ", CI);

        // (
        //     int256 alpha1,
        //     int256 alpha2,
        //     int256 alpha3,
        //     int256 alpha4
        // ) = Polynomials.calculate_alphas(C0, CI, z0);

        alphasVector = Polynomials.calculate_alphas(C0, CI, z0);

        _updatePosition(msg.sender, tickUpper, alphasVector, slot0.tick);

        emit Mint(msg.sender, tickLower, tickUpper, z0);
    }

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external lock returns (uint256 amount0, uint256 amount1) {
        // unchecked {
        //     (Position.Info storage position, int256 amount0Int, int256 amount1Int) = _modifyPosition(
        //         ModifyPositionParams({
        //             owner: msg.sender,
        //             tickLower: tickLower,
        //             tickUpper: tickUpper,
        //             liquidityDelta: -int256(uint256(amount)).toInt128()
        //         })
        //     );
        //     amount0 = uint256(-amount0Int);
        //     amount1 = uint256(-amount1Int);
        //     if (amount0 > 0 || amount1 > 0) {
        //         (position.tokensOwed0, position.tokensOwed1) = (
        //             position.tokensOwed0 + uint128(amount0),
        //             position.tokensOwed1 + uint128(amount1)
        //         );
        //     }
        //     emit Burn(msg.sender, tickLower, tickUpper, amount, amount0, amount1);
        // }
    }

    struct SwapCache {
        // the protocol fee for the input token
        uint8 feeProtocol;
        // liquidity at the beginning of the swap
        Polynomials.AlphasVector alphasStart;
        uint256 densityStart;
        // uint128 liquidityStart;
        // the timestamp of the current block
        uint32 blockTimestamp;
        // the current value of the tick accumulator, computed only if we cross an initialized tick
        int56 tickCumulative;
        // the current value of seconds per liquidity accumulator, computed only if we cross an initialized tick
        uint160 secondsPerLiquidityCumulativeX128;
        // whether we've computed and cached the above two accumulators
        bool computedLatestObservation;
    }

    // the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        uint256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        uint256 amountCalculated;
        // current sqrt(price)
        // uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the global fee growth of the input token
        uint256 feeGrowthGlobalX128;
        // amount of input token paid as protocol fee
        uint128 protocolFee;
        // the current density in range
        Polynomials.AlphasVector alphasState;
        uint256 density;
    }

    struct StepComputations {
        // the price at the beginning of the step
        // uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        // uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }

    function buyOption(
        uint256 amountSpecified,
        uint256 maxCost,
        int24 tickLimit
    ) external lock returns (uint256 cost) {
        if (amountSpecified == 0) revert AS();
        Slot0 memory slot0Start = slot0;

        if (!slot0Start.unlocked) revert LOK();

        bool zeroForOne = false; // false if buying option

        // require(
        //     sqrtPriceLimitX96 < slot0Start.sqrtPriceX96 &&
        //         sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO,
        //     "SPL"
        // );
        slot0.unlocked = false;

        uint256 C0 = TickLibrary.getPriceAtTick(slot0.tick);

        SwapCache memory cache = SwapCache({
            // liquidityStart: liquidity,
            alphasStart: currentAlphas,
            densityStart: Polynomials.calculate_rho(C0, currentAlphas),
            blockTimestamp: _blockTimestamp(),
            feeProtocol: (optionMainInfo.feeProtocol % 16),
            secondsPerLiquidityCumulativeX128: 0,
            tickCumulative: 0,
            computedLatestObservation: false
        });

        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            // sqrtPriceX96: slot0Start.sqrtPriceX96,
            tick: slot0Start.tick,
            feeGrowthGlobalX128: feeGrowthGlobal1X128,
            protocolFee: 0,
            alphasState: cache.alphasStart,
            density: cache.densityStart
        });

        while (
            state.amountSpecifiedRemaining != 0 && state.tick != tickLimit
            // state.sqrtPriceX96 != sqrtPriceLimitX96
        ) {
            StepComputations memory step;

            // step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = tickBitmap
                .nextInitializedTickWithinOneWord(
                    state.tick,
                    tickSpacing,
                    zeroForOne // zeroForOne. false if buying option
                );
            console.log("state.tick: %s");
            console.logInt(state.tick);
            console.log("step.tickNext: %s");
            console.logInt(step.tickNext);

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            // step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            (
                // tick which says if we end up in the same tick or not
                // TODO: implement this logic in the library!!!
                state.tick, 
                step.amountIn,
                step.amountOut,
                step.feeAmount
            ) = SwapMath.computeSwapStep(
                state.tick,
                tickLimit,
                currentAlphas,
                state.amountSpecifiedRemaining,
                fee
            );

            // // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            // (
            //     state.sqrtPriceX96,
            //     step.amountIn,
            //     step.amountOut,
            //     step.feeAmount
            // ) = SwapMath.computeSwapStep(
            //     state.sqrtPriceX96,
            //     (
            //         zeroForOne
            //             ? step.sqrtPriceNextX96 < sqrtPriceLimitX96
            //             : step.sqrtPriceNextX96 > sqrtPriceLimitX96
            //     )
            //         ? sqrtPriceLimitX96
            //         : step.sqrtPriceNextX96,
            //     state.liquidity,
            //     state.amountSpecifiedRemaining,
            //     fee
            // );

            state.amountSpecifiedRemaining -= step.amountOut;
            state.amountCalculated += (step.amountIn + step.feeAmount);

            // if (exactInput) {
            //     // safe because we test that amountSpecified > amountIn + feeAmount in SwapMath
            //     unchecked {
            //         state.amountSpecifiedRemaining -= (step.amountIn +
            //             step.feeAmount).toInt256();
            //     }
            //     state.amountCalculated -= step.amountOut.toInt256();
            // } else {
            //     unchecked {
            //         state.amountSpecifiedRemaining += step.amountOut.toInt256();
            //     }
            //     state.amountCalculated += (step.amountIn + step.feeAmount)
            //         .toInt256();
            // }

            // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
            if (cache.feeProtocol > 0) {
                unchecked {
                    uint256 delta = step.feeAmount / cache.feeProtocol;
                    step.feeAmount -= delta;
                    state.protocolFee += uint128(delta);
                }
            }

            // update global fee tracker
            if (state.density > 0) {
                unchecked {
                    state.feeGrowthGlobalX128 += FullMath.mulDiv(
                        step.feeAmount,
                        FixedPoint128.Q128,
                        state.density
                    );
                }
            }

            // // shift tick if we reached the next price
            // if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
            //     // if the tick is initialized, run the tick transition
            //     if (step.initialized) {
            //         // check for the placeholder value, which we replace with the actual value the first time the swap
            //         // crosses an initialized tick
            //         if (!cache.computedLatestObservation) {
            //             (
            //                 cache.tickCumulative,
            //                 cache.secondsPerLiquidityCumulativeX128
            //             ) = observations.observeSingle(
            //                 cache.blockTimestamp,
            //                 0,
            //                 slot0Start.tick,
            //                 slot0Start.observationIndex,
            //                 cache.liquidityStart,
            //                 slot0Start.observationCardinality
            //             );
            //             cache.computedLatestObservation = true;
            //         }
            //         int128 liquidityNet = ticks.cross(
            //             step.tickNext,
            //             (state.feeGrowthGlobalX128),
            //             (
            //                 zeroForOne
            //                     ? feeGrowthGlobal1X128
            //                     : state.feeGrowthGlobalX128
            //             ),
            //             cache.secondsPerLiquidityCumulativeX128,
            //             cache.tickCumulative,
            //             cache.blockTimestamp
            //         );
            //         // if we're moving leftward, we interpret liquidityNet as the opposite sign
            //         // safe because liquidityNet cannot be type(int128).min
            //         unchecked {
            //             if (zeroForOne) liquidityNet = -liquidityNet;
            //         }

            //         state.liquidity = liquidityNet < 0
            //             ? state.liquidity - uint128(-liquidityNet)
            //             : state.liquidity + uint128(liquidityNet);
            //     }

            //     unchecked {
            //         state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
            //     }
            // } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
            //     // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
            //     state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            // }
        }
    }
}
