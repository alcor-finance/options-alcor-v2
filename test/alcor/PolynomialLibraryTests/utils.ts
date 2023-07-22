// @ts-nocheck
import { create, all } from 'mathjs';


const config = {};
const math = create(all, config);

export function alpha12_denominator(C0: number, CI: number, z0: number): number {
    const C0_4 = math.pow(C0, 4);
    const C0_3 = math.pow(C0, 3);
    const C0_2 = math.pow(C0, 2);
    const CI_3 = math.pow(CI, 3);
    const CI_4 = math.pow(CI, 4);
    const CI_2 = math.pow(CI, 2);
    // console.log(C0_4, C0_3, C0_2, CI_3, CI_4, CI_2)

    // console.log(13.5 * C0_4)
    console.log(13.5 * C0_4,
        - 54.0 * C0_3 * CI,
        + 81.0 * C0_2 * CI_2,
        - 54.0 * C0 * CI_3,
        + 13.5 * CI_4);

    const numerator = 54.0 * z0;
    const denominator =
        13.5 * C0_4
        - 54.0 * C0_3 * CI
        + 81.0 * C0_2 * CI_2
        - 54.0 * C0 * CI_3
        + 13.5 * CI_4;

    return denominator
    // return math.divide(numerator, denominator);
}
