const Strategy = artifacts.require('./StrategyNative.sol')
const fields = ['nativeFarmAddress', 'NATIVEAddress', 'farmContractAddress', 'pid', 'wantAddress', 'token0Address', 'token1Address', 'earnedAddress', 'uniRouterAddress', 'govAddress']
const argv = require('yargs').argv


module.exports = async function (deployer) {

    let check = true

    for (const k in fields) {
        const field = fields[k]
        if(argv[field] === undefined || argv[field] === null){
            check = false
        } else {
            try {
                const f = argv[field]
                argv[field] = f.replace('_', '')   
            } catch (error) {
                
            }
        }
    }

    if(check){
        await deployer.deploy(
            Strategy, 
            argv.nativeFarmAddress,
            argv.NATIVEAddress,
            argv.farmContractAddress === 0 ? '0x0000000000000000000000000000000000000000' : argv.farmContractAddress,
            argv.pid,
            argv.wantAddress,
            argv.token0Address === 0 ? '0x0000000000000000000000000000000000000000' : argv.token0Address,
            argv.token1Address === 0 ? '0x0000000000000000000000000000000000000000' : argv.token1Address,
            argv.earnedAddress,
            argv.uniRouterAddress === 0 ? '0x0000000000000000000000000000000000000000' : argv.uniRouterAddress,
            argv.govAddress
        )
    } else {
        console.log("fields error")
    }

}

