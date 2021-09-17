const TimelockController = artifacts.require('./TimelockController.sol')

module.exports = async function (deployer) {
    await deployer.deploy(TimelockController, process.env.DEV_ADDRESS)
}