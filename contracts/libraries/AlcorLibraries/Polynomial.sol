// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
import "../../dependencies/prb-math/contracts/PRBMathUD60x18.sol";
import "../../dependencies/prb-math/contracts/PRBMathSD59x18.sol";

import "hardhat/console.sol";

library Polynomial {
    using PRBMathUD60x18 for uint256;
    using PRBMathSD59x18 for int256;

    function alpha12_denominator(
        uint256 C0,
        uint256 CI
    ) public view returns (uint256 result) {
        // console.log(C0.powu(4));
        // console.log(uint(135).div(10).mul(C0.powu(4)));

        console.log("---");

        uint result1 = uint(135).div(10).mul(C0.powu(4));
        uint result2 = uint(54).div(1).mul(C0.powu(3)).mul(CI);
        uint result3 = uint(81).div(1).mul(C0.powu(2)).mul(CI.powu(2));
        uint result4 = uint(81).div(1).mul(C0.powu(2)).mul(CI.powu(2));
        uint result5 = uint(135).div(10).mul(CI.powu(4));

        // Вывод результатов
        console.log(result1);
        console.log(result2);
        console.log(result3);
        console.log(result4);
        console.log(result5);

        return
            uint(135).div(10).mul(C0.powu(4)) +
            uint(135).div(10).mul(CI.powu(4)) +
            uint(81).div(1).mul(C0.powu(2)).mul(CI.powu(2)) -
            uint(54).div(1).mul(CI.powu(3)).mul(C0) -
            uint(54).div(1).mul(C0.powu(3)).mul(CI);
    }
}

// const denominator =
//     13.5 * C0_4
//     - 54.0 * C0_3 * CI
//     + 81.0 * C0_2 * CI_2
//     - 54.0 * C0 * CI_3
//     + 13.5 * CI_4;
