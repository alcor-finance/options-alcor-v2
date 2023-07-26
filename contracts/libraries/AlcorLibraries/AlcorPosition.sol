// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {FullMath} from "../FullMath.sol";
import {FixedPoint128} from "../FixedPoint128.sol";
import {TickLibrary} from "./TickLibrary.sol";

// import {Tick} from "./AlcorTick.sol";

import {Polynomials} from "./Polynomials.sol";

/// @title Position
/// @notice Positions represent an owner address' liquidity between a lower and upper tick boundary
/// @dev Positions store additional state for tracking fees owed to the position
library Position {
    error NP();

    // info stored for each user's position
    struct Info {
        Polynomials.AlphasVector positionAlphas;
        // the amount of liquidity owned by this position
        uint256 density;
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed
        uint256 feeGrowthInsideLastX128;
        // uint256 feeGrowthInside1LastX128;
        // the fees owed to the position owner in token0/token1
        uint128 tokensOwed;
        // uint128 tokensOwed1;
    }

    /// @notice Returns the Info struct of a position, given an owner and position boundaries
    /// @param self The mapping containing all user positions
    /// @param owner The address of the position owner
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @return position The position info struct of the given owners' position
    function get(
        mapping(bytes32 => Info) storage self,
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (Position.Info storage position) {
        position = self[
            keccak256(abi.encodePacked(owner, tickLower, tickUpper))
        ];
    }

    /// @notice Credits accumulated fees to a user's position
    /// @param self The individual position to update
    // /// @param feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    // /// @param feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function update(
        Info storage self,
        Polynomials.AlphasVector memory alphasDelta,
        int24 tick,
        uint256 feeGrowthInsideX128
    ) internal {
        Info memory _self = self;

        // uint128 liquidityNext;
        if (
            alphasDelta.alpha1 == 0 &&
            alphasDelta.alpha2 == 0 &&
            alphasDelta.alpha3 == 0 &&
            alphasDelta.alpha4 == 0
        ) {
            if (
                _self.positionAlphas.alpha1 <= 0 &&
                _self.positionAlphas.alpha2 <= 0 &&
                _self.positionAlphas.alpha3 <= 0 &&
                _self.positionAlphas.alpha4 <= 0
            ) revert NP(); // disallow pokes for 0 liquidity positions
            // liquidityNext = _self.liquidity;
        } else {
            self.positionAlphas = Polynomials.addAlphasVectors(
                _self.positionAlphas,
                alphasDelta
            );

            uint256 C = TickLibrary.getPriceAtTick(tick);
            // update density
            self.density = Polynomials.calculate_rho(C, _self.positionAlphas);

            // liquidityNext = liquidityDelta < 0
            //     ? _self.liquidity - uint128(-liquidityDelta)
            //     : _self.liquidity + uint128(liquidityDelta);
        }

        // TODO: uncomment this

        // calculate accumulated fees. overflow in the subtraction of fee growth is expected
        uint128 tokensOwed;
        // uint128 tokensOwed1;
        unchecked {
            tokensOwed = uint128(
                FullMath.mulDiv(
                    feeGrowthInsideX128 - _self.feeGrowthInsideLastX128,
                    self.density,
                    FixedPoint128.Q128
                )
            );
            // tokensOwed1 = uint128(
            //     FullMath.mulDiv(
            //         feeGrowthInside1X128 - _self.feeGrowthInside1LastX128,
            //         _self.liquidity,
            //         FixedPoint128.Q128
            //     )
            // );

            // update the position
            // if (liquidityDelta != 0) self.liquidity = liquidityNext;
            self.feeGrowthInsideLastX128 = feeGrowthInsideX128;
            // self.feeGrowthInside1LastX128 = feeGrowthInside1X128;
            if (tokensOwed > 0) {
                // overflow is acceptable, user must withdraw before they hit type(uint128).max fees
                self.tokensOwed += tokensOwed;
                // self.tokensOwed1 += tokensOwed1;
            }
        }
    }
}
