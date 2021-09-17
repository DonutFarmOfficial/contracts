const MasterChef = artifacts.require('./MasterChef.sol')
const NativeToken = artifacts.require('./NativeToken.sol')
const Referrals = artifacts.require('./Referrals.sol')
const TimelockController = artifacts.require('./TimelockController.sol')

module.exports = async function (deployer) {
    const token = await NativeToken.deployed()
    const referrals = await Referrals.deployed()
    const timelock = await TimelockController.deployed()

    await deployer.deploy(MasterChef, token.address, process.env.FEE_ADDRESS, referrals.address)

    const chef = await MasterChef.deployed()

    await referrals.transferOwnership(chef.address)

    await token.transferOwnership(chef.address)

    await chef.transferOwnership(timelock.address)

}