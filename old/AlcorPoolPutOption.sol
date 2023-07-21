// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
pragma abicoder v2;

// import "../dependencies/ReentrancyGuard.sol";

import "../libraries/TransferHelper.sol";

import "./AlcorVanillaOption.sol";

import "hardhat/console.sol";

// not yet implemented
contract AlcorPoolPutOption is AlcorVanillaOption {
    using FullMath for uint256;
    // using LowGasSafeMath for uint256;
    // using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    using TickLibrary for int24;

    using Cryptography for Cryptography.SellingLimitOrder;
    using Cryptography for Cryptography.BuyingLimitOrder;
    using Cryptography for bytes32;

    using UserInfoCallOption for mapping(address => UserInfoCallOption.Info);

    constructor() AlcorVanillaOption() {
        // (
        //     factory,
        //     optionMainInfo.token0,
        //     optionMainInfo.token1,
        //     optionMainInfo.token0Decimals,
        //     optionMainInfo.token1Decimals,
        //     optionMainInfo.expiration,
        //     optionMainInfo.strikePrice,
        //     optionMainInfo.tickSpacing
        // ) = IAlcorPoolDeployer(msg.sender).parameters();
        // optionMainInfo.isCallOption = true;
        // protocolFee = 500; // 0.05%
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
