// SPDX-License-Identifier: None

import "../libraries/AlcorLibraries/Polynomials.sol";

pragma solidity ^0.8.18;

contract TestPolynomialsLibrary {
    function rho_alpha_denominator(
        uint256 C0,
        uint256 CI
    ) public pure returns (uint256) {
        return Polynomials.rho_alpha_denominator(C0, CI);
    }

    function rho_alpha1(
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) public pure returns (int256) {
        return Polynomials.rho_alpha1(C0, CI, z0);
    }

    function rho_alpha2(
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) public pure returns (int256) {
        return Polynomials.rho_alpha2(C0, CI, z0);
    }

    function rho_alpha3(
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) public pure returns (int256) {
        return Polynomials.rho_alpha3(C0, CI, z0);
    }

    function rho_alpha4(
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) public pure returns (int256) {
        return Polynomials.rho_alpha4(C0, CI, z0);
    }

    function calculate_dy_alphas(
        uint256 C,
        uint256 C0,
        Polynomials.AlphasVector memory alphasVector
    ) public pure returns (int256) {
        return Polynomials.calculate_dy_alphas(C, C0, alphasVector);
    }

    function calculate_dy(
        uint256 C,
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) public pure returns (int256) {
        return Polynomials.calculate_dy(C, C0, CI, z0);
    }
}
