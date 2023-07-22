import { ethers } from 'hardhat'
import { expect } from 'chai'
import { Contract } from 'ethers'

import * as utils from './utils'

describe('PolynomialLibrary', () => {
    let polynomial: Contract

    beforeEach(async () => {
        const Polynomial = await ethers.getContractFactory('Polynomial')
        polynomial = await Polynomial.deploy()
        await polynomial.deployed()
    })

    describe('alpha12_denominator', () => {
        it('correctly calculates the denominator', async () => {
            const C0 = 0.01
            const CI = 0.1
            const z0 = 0.5
            const C0_eth = ethers.utils.parseUnits(C0.toString(), 18) // changed from parseEther to parseUnits
            const CI_eth = ethers.utils.parseUnits(CI.toString(), 18) // changed from parseEther to parseUnits
            const result = await polynomial.alpha12_denominator(C0_eth, CI_eth) // use the ether format numbers

            const res_expected = utils.alpha12_denominator(C0, CI, z0)
            console.log(res_expected.toString())

            // substitute the correct value you are expecting here
            // const expected = ethers.utils.parseEther('...')
            console.log(result.toString())
            // expect(result).to.equal(expected)
        })
    })
})
