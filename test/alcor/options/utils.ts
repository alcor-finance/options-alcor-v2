import { BigNumber } from "bignumber.js";

export function priceToSqrtPriceX96(price: BigNumber): BigNumber {
    return price.sqrt().multipliedBy(new BigNumber(2).pow(96));
}

export function sqrtPriceX96ToPrice(sqrtPriceX96: BigNumber): BigNumber {
    return sqrtPriceX96.dividedBy(new BigNumber(2).pow(48)).pow(2);
}
