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
