const NativeToken = artifacts.require('./NativeToken.sol')

module.exports = async function (deployer) {

    await deployer.deploy(NativeToken, "DONUT", "DONUT")

    const token = await NativeToken.deployed()

    await token.mint(process.env.DEV_ADDRESS, web3.utils.toWei(process.env.TOKENS_MINT))
    
    //await token.mint(process.env.OWNER_ADDRESS, web3.utils.toWei(process.env.TOKENS_MINT))
    

}