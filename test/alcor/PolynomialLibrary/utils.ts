// @ts-nocheck
import { create, all } from 'mathjs';

const config = {};
const math = create(all, config);

export function calculate_rho_alpha1(C0: number, CI: number, z0: number): number {
    const numerator = 54.0 * z0;
    const denominator =
        13.5 * math.pow(C0, 4)
        - 54.0 * math.pow(C0, 3) * CI
        + 81.0 * math.pow(C0, 2) * math.pow(CI, 2)
        - 54.0 * C0 * math.pow(CI, 3)
        + 13.5 * math.pow(CI, 4);

    return math.divide(numerator, denominator);
}

export function calculate_rho_alpha2(C0: number, CI: number, z0: number): number {
    const numerator = -81.0 * z0 * (C0 + CI);
    const denominator =
        13.5 * math.pow(C0, 4)
        - 54.0 * math.pow(C0, 3) * CI
        + 81.0 * math.pow(C0, 2) * math.pow(CI, 2)
        - 54.0 * C0 * math.pow(CI, 3)
        + 13.5 * math.pow(CI, 4);

    return math.divide(numerator, denominator);
}

export function calculate_rho_alpha3(C0: number, CI: number, z0: number): number {
    const numerator = 54.0 * C0 * CI * z0;
    const denominator =
        4.5 * math.pow(C0, 4)
        - 18.0 * math.pow(C0, 3) * CI
        + 27.0 * math.pow(C0, 2) * math.pow(CI, 2)
        - 18.0 * C0 * math.pow(CI, 3)
        + 4.5 * math.pow(CI, 4);

    return math.divide(numerator, denominator);
}

export function calculate_rho_alpha4(C0: number, CI: number, z0: number): number {
    const numerator = -1.0 * math.pow(CI, 2) * z0 * (9.0 * C0 - 3.0 * CI);
    const denominator =
        1.5 * math.pow(C0, 4)
        - 6.0 * math.pow(C0, 3) * CI
        + 9.0 * math.pow(C0, 2) * math.pow(CI, 2)
        - 6.0 * C0 * math.pow(CI, 3)
        + 1.5 * math.pow(CI, 4);

    return math.divide(numerator, denominator);
}
