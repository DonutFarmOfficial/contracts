const TimelockController = artifacts.require('./TimelockController.sol')
const Referrals = artifacts.require('./Referrals.sol')

module.exports = async function (deployer) {
    const timelock = await TimelockController.deployed()

    await deployer.deploy(Referrals)

    const referrals = await Referrals.deployed()

    await referrals.addMember(timelock.address, timelock.address)
}