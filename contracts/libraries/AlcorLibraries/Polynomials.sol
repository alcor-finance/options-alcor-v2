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

    function calculate_alphas(
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) internal pure returns (int256, int256, int256, int256) {
        int256 alpha1 = rho_alpha1(C0, CI, z0);
        int256 alpha2 = rho_alpha2(C0, CI, z0);
        int256 alpha3 = rho_alpha3(C0, CI, z0);
        int256 alpha4 = rho_alpha4(C0, CI, z0);
        return (alpha1, alpha2, alpha3, alpha4);
    }

    function calculate_dy_alphas(
        uint256 C,
        uint256 C0,
        int alpha1,
        int alpha2,
        int alpha3,
        int alpha4
    ) internal pure returns (int256) {
        return
            alpha1.mul(int(C.powu(4) - C0.powu(4))).div(4 ether) +
            alpha2.mul(int(C.powu(3) - C0.powu(3))).div(3 ether) +
            alpha3.mul(int(C.powu(2) - C0.powu(2))).div(2 ether) +
            alpha4.mul(int(C - C0));
    }

    function calculate_dy(
        uint256 C,
        uint256 C0,
        uint256 CI,
        uint256 z0
    ) internal pure returns (int256) {
        return
            rho_alpha1(C0, CI, z0).mul(int(C.powu(4) - C0.powu(4))).div(
                4 ether
            ) +
            rho_alpha2(C0, CI, z0).mul(int(C.powu(3) - C0.powu(3))).div(
                3 ether
            ) +
            rho_alpha3(C0, CI, z0).mul(int(C.powu(2) - C0.powu(2))).div(
                2 ether
            ) +
            rho_alpha4(C0, CI, z0).mul(int(C - C0));
    }

    function calculate_dx(
        uint256 C,
        uint256 C0,
        int alpha1,
        int alpha2,
        int alpha3,
        int alpha4
    ) internal pure returns (int256) {
        return
            alpha1.mul(int(C).powu(5) - int(C0).powu(5)).div(5 ether) +
            alpha2.mul(int(C).powu(4) - int(C0).powu(4)).div(4 ether) +
            alpha3.mul(int(C).powu(3) - int(C0).powu(3)).div(3 ether) +
            alpha4.mul(int(C).powu(2) - int(C0).powu(2)).div(2);
    }
}
