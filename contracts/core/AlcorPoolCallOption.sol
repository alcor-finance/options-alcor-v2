// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
pragma abicoder v2;

import "../dependencies/ReentrancyGuard.sol";

import {SafeCast} from "../libraries/SafeCast.sol";
import {Tick} from "../libraries/Tick.sol";
import {TickBitmap} from "../libraries/TickBitmap.sol";
import {Position} from "../libraries/Position.sol";
import {Oracle} from "../libraries/Oracle.sol";

import {FullMath} from "../libraries/FullMath.sol";
import {FixedPoint128} from "../libraries/FixedPoint128.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";
import {TickMath} from "../libraries/TickMath.sol";
import {SqrtPriceMath} from "../libraries/SqrtPriceMath.sol";
import {SwapMath} from "../libraries/SwapMath.sol";

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

    // using UserInfoCallOption for mapping(address => UserInfoCallOption.Info);

    // address public token0;
    // address public token1;
    // uint24 public fee;

    int24 public tickSpacing;

    uint128 public maxLiquidityPerTick;

    uint128 public liquidity;

    mapping(int24 => Tick.Info) public ticks;
    mapping(int16 => uint256) public tickBitmap;
    mapping(bytes32 => Position.Info) public positions;
    Oracle.Observation[65535] public observations;

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

        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(
            tickSpacing
        );
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
