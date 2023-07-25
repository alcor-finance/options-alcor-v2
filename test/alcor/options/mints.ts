import { ethers } from "hardhat";
import { expect } from "chai";
import { Decimal } from 'decimal.js'

import { BigNumber, Signer, Contract, Wallet } from "ethers";

import { BigNumber as bn } from "bignumber.js";

import { AlcorFactory } from "../../../typechain/AlcorFactory";


import { TokenERC20 } from '../../../typechain/TokenERC20'
import { MockAlcorPoolCallOption } from '../../../typechain/MockAlcorPoolCallOption'

import { delay, tickToPrice } from '../../shared/utils'
import { formatTokenAmount } from '../../shared/format'
import { priceToSqrtPriceX96, sqrtPriceX96ToPrice } from "./utils";


import {
    Tokens, deployTokensFixture,
    loadTokensFixture, FactoryFixture,
    createAlcorPoolCallOption,
    loadAlcorPoolCallOptionContract
} from '../../shared/fixtures'
import { AlcorPoolCallOption } from "../../../typechain";

Decimal.config({ toExpNeg: -500, toExpPos: 500 })

const AlcorPoolsParams = [{
    isCallOption: true,
    optionExpiration: "1695978000",
    optionStrikePrice: ethers.utils.parseEther("2200")
}]

let tokenA: Contract;
let tokenB: Contract;
let alcorFactory: Contract;
let alcorOption: AlcorPoolCallOption;

const OPTION_STRIKE_PRICE = BigNumber.from(2000);
const OPTION_EXPIRATION = "1695978000";
const POOL_FEE = 500;





describe("AlcorOption mint", function () {
    let accountsLength: number = 3
    let account1: Wallet, account2: Wallet, account3: Wallet
    let token0Addr: string, token1Addr: string


    let factory: AlcorFactory
    let mock_alcor_pool_call_option_address: string
    // const { isCallOption, optionExpiration, optionStrikePrice } = AlcorPoolsParams[0];

    before("load wallets", async () => {
        [account1, account2, account3] = await (ethers as any).getSigners()
        // accounts = await (ethers as any).getSigners()
        console.log(account1.address, account2.address, account3.address)
    })
    before('deploy tokens', async function () {
        let [token0Addr, token1Addr] = await deployTokensFixture()
        let deployer: Wallet = account1
        let [token0, token1] = await loadTokensFixture(token0Addr, token1Addr, deployer)
        console.log("token0:", token0.address)
        console.log("token1:", token1.address)

        // Deploy AlcorFactory
        const AlcorFactory = await ethers.getContractFactory("MockAlcorFactory");
        alcorFactory = await AlcorFactory.deploy();
        await alcorFactory.deployed();

        console.log('AlcorFactory deployed')

        // Use AlcorFactory to create AlcorOption
        await alcorFactory.createPoolCallOption(
            token0.address,
            token1.address,
            POOL_FEE,
            OPTION_EXPIRATION,
            OPTION_STRIKE_PRICE
        );

        console.log('AlcorOption created')

        // Get the created AlcorOption address and instance
        const alcorOptionAddress = await alcorFactory.getPool(
            token0.address,
            token1.address,
            OPTION_EXPIRATION,
            true,
            OPTION_STRIKE_PRICE
        );
        alcorOption = await ethers.getContractAt("MockAlcorPoolCallOption", alcorOptionAddress) as AlcorPoolCallOption;
    });

    it('should initialize AlcorOption', async function () {
        let init_tick = -40000;
        await alcorOption.connect(account1).initialize(init_tick);
    })

    it("Should mint successfully", async function () {
        const tickUpper = -39000;
        const Z0 = ethers.utils.parseEther("1"); // 1 TokenA


        before("approve tokens to alcor pool contract", async () => {
            let [token0, token1] = await loadTokensFixture(token0Addr, token1Addr, account1)

            let tx0 = await token0.approve(mock_alcor_pool_call_option_address, BigNumber.from(2).pow(150).toString())
            await tx0.wait();
            let tx1 = await token1.approve(mock_alcor_pool_call_option_address, BigNumber.from(2).pow(150).toString())
            await tx1.wait();

        })

        // Mint options
        console.log(await alcorOption.connect(account1).depositForSelling(tickUpper, Z0))
        // .to.emit(alcorOption, "Mint")
        // .withArgs(await account1.getAddress(), alcorOption.slot0.tick, alcorOption.tickUpper, Z0);
    });
});
