// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
import "../../dependencies/prb-math/UD60x18.sol" as UD60x18;

import "hardhat/console.sol";

library Polynomial {
    // type uint256 is UD60x18;

    // uint public constant f = 1.toUD60x18();

    function alpha12_denominator(
        uint256 C0,
        uint256 CI
    ) public pure returns (UD60x18.UD60x18 result) {
        UD60x18.UD60x18 c0_UD = UD60x18.toUD60x18(C0);
        UD60x18.UD60x18 ci_UD = UD60x18.toUD60x18(CI);


        return
            UD60x18
                .toUD60x18(135)
                .div(UD60x18.toUD60x18(10))
                .mul(c0_UD.powu(4))
                .sub(UD60x18.toUD60x18(54).mul(c0_UD.powu(3)).mul(ci_UD))
                .add(
                    UD60x18.toUD60x18(81).mul(c0_UD.powu(2)).mul(ci_UD.powu(2))
                )
                .sub(UD60x18.toUD60x18(54).mul(c0_UD).mul(ci_UD.powu(3)))
                .add(
                    UD60x18.toUD60x18(135).div(UD60x18.toUD60x18(10)).mul(
                        ci_UD.powu(4)
                    )
                );
    }
}
