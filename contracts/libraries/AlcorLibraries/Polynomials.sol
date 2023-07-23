// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
import "../../dependencies/prb-math/contracts/PRBMathUD60x18.sol";
import "../../dependencies/prb-math/contracts/PRBMathSD59x18.sol";

import "hardhat/console.sol";

library Polynomials {
    using PRBMathUD60x18 for uint256;
    using PRBMathSD59x18 for int256;

    function rho_alpha_denominator(
        uint256 C0,
        uint256 CI
    ) internal pure returns (uint256) {
        return
            uint(15).div(10).mul(C0.powu(4)) +
            uint(15).div(10).mul(CI.powu(4)) +
            uint(9).div(1).mul(C0.powu(2)).mul(CI.powu(2)) -
            uint(6).div(1).mul(CI.powu(3)).mul(C0) -
            uint(6).div(1).mul(C0.powu(3)).mul(CI);
    }

    function rho_alpha1(
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) internal pure returns (int256) {
        return
            int(
                uint(54).div(1).mul(z0).div(
                    uint(9).div(1).mul(rho_alpha_denominator(C0, CI))
                )
            );
    }

    function rho_alpha2(
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) internal pure returns (int256) {
        return
            -int(
                uint(81).div(1).mul(z0).mul(C0 + CI).div(
                    uint(9).div(1).mul(rho_alpha_denominator(C0, CI))
                )
            );
    }

    function rho_alpha3(
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) internal pure returns (int256) {
        return
            int(
                uint(54).div(1).mul(z0).mul(C0).mul(CI).div(
                    uint(3).div(1).mul(rho_alpha_denominator(C0, CI))
                )
            );
    }

    function rho_alpha4(
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) internal pure returns (int256) {
        return
            -int(
                CI.powu(2).mul(z0).mul((uint(9).div(1).mul(C0))).div(
                    rho_alpha_denominator(C0, CI)
                )
            ) +
            int(
                CI.powu(2).mul(z0).mul(uint(3).div(1).mul(CI)).div(
                    rho_alpha_denominator(C0, CI)
                )
            );
    }

    function calculate_dy(
        uint256 C,
        int alpha1,
        int alpha2,
        int alpha3,
        int alpha4
    ) internal pure returns (int256) {
        int C_signed = int(C);
        return
            alpha1.mul(C_signed.powu(4)).div(4) +
            alpha2.mul(C_signed.powu(3)).div(3) +
            alpha3.mul(C_signed.powu(2)).div(2) +
            alpha4.mul(C_signed);
    }
}
