// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

import "../interfaces/IAlcorPoolDeployer.sol";
import "../interfaces/IERC20Minimal.sol";

/// @dev TODO: do not forget to change it back to AlcorPool
/// @dev AND in the line when creating a contract below.

import "./AlcorPoolCallOption.sol";

// import "./test/MockAlcorPoolCallOption.sol";

contract AlcorPoolDeployer is IAlcorPoolDeployer {
    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint256 expiration;
        uint160 optionStrikePriceX96;
        uint32 poolFee;
        int24 tickSpacing;
    }

    /// @inheritdoc IAlcorPoolDeployer
    Parameters public override parameters;

    /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    // /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The spacing between usable ticks
    function deployCallOption(
        address factory,
        address token0,
        address token1,
        uint256 optionExpiration,
        uint32 poolFee,
        uint160 optionStrikePriceX96,
        int24 tickSpacing
    ) internal virtual returns (address pool) {
        parameters = Parameters({
            factory: factory,
            token0: token0,
            token1: token1,
            expiration: optionExpiration,
            poolFee: poolFee,
            optionStrikePriceX96: optionStrikePriceX96,
            tickSpacing: tickSpacing
        });

        pool = address(
            new AlcorPoolCallOption{
                salt: keccak256(
                    abi.encode(
                        token0,
                        token1,
                        optionStrikePriceX96,
                        optionExpiration
                    )
                )
            }()
        );
        delete parameters;
    }
}
