import { ethers } from 'hardhat'
import { expect } from 'chai'
import { Contract } from 'ethers'

import * as utils from './utils'

import { TestPolynomialsLibrary } from '../../../typechain'

describe('PolynomialLibrary', () => {
    let polynomial: Contract
    const scale = ethers.BigNumber.from(10).pow(8)

    beforeEach(async () => {
        const Polynomial = await ethers.getContractFactory('TestPolynomialsLibrary')
        polynomial = await Polynomial.deploy() as TestPolynomialsLibrary
        await polynomial.deployed()
    })

    it('rho_alpha1', async () => {
        const C0 = 0.01
        const CI = 0.1
        const z0 = 0.5
        const C0_eth = ethers.utils.parseUnits(C0.toString(), 18) // changed from parseEther to parseUnits
        const CI_eth = ethers.utils.parseUnits(CI.toString(), 18) // changed from parseEther to parseUnits
        const z0_eth = ethers.utils.parseUnits(z0.toString(), 18) // changed from parseEther to parseUnits
        const result = await polynomial.rho_alpha1(C0_eth, CI_eth, z0_eth) // use the ether format numbers

        const res_expected = utils.calculate_rho_alpha1(C0, CI, z0)
        console.log(res_expected.toString())

        const expected = ethers.utils.parseUnits(res_expected.toString(), 18)
        console.log(result.toString())

        expect(result.div(scale)).to.equal(expected.div(scale))
    })

    it('rho_alpha2', async () => {
        const C0 = 0.01
        const CI = 0.1
        const z0 = 0.5
        const C0_eth = ethers.utils.parseUnits(C0.toString(), 18) // changed from parseEther to parseUnits
        const CI_eth = ethers.utils.parseUnits(CI.toString(), 18) // changed from parseEther to parseUnits
        const z0_eth = ethers.utils.parseUnits(z0.toString(), 18) // changed from parseEther to parseUnits
        const result = await polynomial.rho_alpha2(C0_eth, CI_eth, z0_eth) // use the ether format numbers

        const res_expected = utils.calculate_rho_alpha2(C0, CI, z0)
        console.log(res_expected.toString())

        const expected = ethers.utils.parseUnits(res_expected.toString(), 18)
        console.log(result.toString())

        expect(result.div(scale)).to.equal(expected.div(scale))
    }
    )

    it('rho_alpha3', async () => {
        const C0 = 0.01
        const CI = 0.1
        const z0 = 0.5
        const C0_eth = ethers.utils.parseUnits(C0.toString(), 18) // changed from parseEther to parseUnits
        const CI_eth = ethers.utils.parseUnits(CI.toString(), 18) // changed from parseEther to parseUnits
        const z0_eth = ethers.utils.parseUnits(z0.toString(), 18) // changed from parseEther to parseUnits
        const result = await polynomial.rho_alpha3(C0_eth, CI_eth, z0_eth) // use the ether format numbers

        const res_expected = utils.calculate_rho_alpha3(C0, CI, z0)
        console.log(res_expected.toString())

        const expected = ethers.utils.parseUnits(res_expected.toString(), 18)
        console.log(result.toString())

        expect(result.div(scale)).to.equal(expected.div(scale))
    }
    )

    it('rho_alpha4', async () => {
        const C0 = 0.01
        const CI = 0.1
        const z0 = 0.5
        const C0_eth = ethers.utils.parseUnits(C0.toString(), 18) // changed from parseEther to parseUnits
        const CI_eth = ethers.utils.parseUnits(CI.toString(), 18) // changed from parseEther to parseUnits
        const z0_eth = ethers.utils.parseUnits(z0.toString(), 18) // changed from parseEther to parseUnits
        const result = await polynomial.rho_alpha4(C0_eth, CI_eth, z0_eth) // use the ether format numbers

        const res_expected = utils.calculate_rho_alpha4(C0, CI, z0)
        console.log(res_expected.toString())

        const expected = ethers.utils.parseUnits(res_expected.toString(), 18)
        console.log(result.toString())

        expect(result.div(scale)).to.equal(expected.div(scale))
    }
    )

    it('calculate_dy', async () => {
        const C = 0.1
        const C0 = 0.01
        const CI = 0.1
        const z0 = 0.5
        const C_eth = ethers.utils.parseUnits(C.toString(), 18) // changed from parseEther to parseUnits
        const C0_eth = ethers.utils.parseUnits(C0.toString(), 18) // changed from parseEther to parseUnits
        const CI_eth = ethers.utils.parseUnits(CI.toString(), 18) // changed from parseEther to parseUnits
        const z0_eth = ethers.utils.parseUnits(z0.toString(), 18) // changed from parseEther to parseUnits
        const result = await polynomial.calculate_dy(C_eth, C0_eth, CI_eth, z0_eth) // use the ether format numbers

        // const res_expected = utils.calculate_dy(C0, CI, z0)
        // console.log(res_expected.toString())

        const expected = ethers.utils.parseUnits(z0.toString(), 18)
        console.log(result.toString())

        expect(result.div(scale)).to.equal(expected.div(scale))
    })
})
