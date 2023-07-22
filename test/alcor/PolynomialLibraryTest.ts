import { ethers } from 'hardhat'
import { expect } from 'chai'
import { Contract } from 'ethers'

describe('PolynomialLibrary', () => {
    let polynomial: Contract

    beforeEach(async () => {
        const Polynomial = await ethers.getContractFactory('Polynomial')
        polynomial = await Polynomial.deploy()
        await polynomial.deployed()
    })

    describe('alpha12_denominator', () => {
        it('correctly calculates the denominator', async () => {
            const C0 = ethers.utils.parseEther('0.01')
            const CI = ethers.utils.parseEther('0.1')
            const result = await polynomial.alpha12_denominator(C0, CI)

            // substitute the correct value you are expecting here
            // const expected = ethers.utils.parseEther('...')
            console.log(result.toString())
            // expect(result).to.equal(expected)

        })
    })
})
