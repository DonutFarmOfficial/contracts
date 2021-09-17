const Strategy = artifacts.require('./StrategyWault.sol')
const argv = require('yargs').argv
const fields = ['nativeFarmAddress', 'NATIVEAddress', 'isSingleVault', 'isAutoComp', 'farmContractAddress', 'pid', 'wantAddress', 'token0Address', 'token1Address', 'earnedAddress', 'uniRouterAddress', 'wbnbAddress', 'buybackRouterAddress', 'govAddress']

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
            argv.isSingleVault === 'true' ? true : false,
            argv.isAutoComp === 'true' ? true : false,
            argv.farmContractAddress === 0 ? '0x0000000000000000000000000000000000000000' : argv.farmContractAddress,
            argv.pid,
            argv.wantAddress,
            argv.token0Address === 0 ? '0x0000000000000000000000000000000000000000' : argv.token0Address,
            argv.token1Address === 0 ? '0x0000000000000000000000000000000000000000' : argv.token1Address,
            argv.earnedAddress,
            argv.uniRouterAddress === 0 ? '0x0000000000000000000000000000000000000000' : argv.uniRouterAddress,
            argv.wbnbAddress === 0 ? '0x0000000000000000000000000000000000000000' : argv.wbnbAddress,
            argv.buybackRouterAddress === 0 ? '0x0000000000000000000000000000000000000000' : argv.buybackRouterAddress,
            argv.govAddress
        )

    } else {
        console.log("fields error")
    }

}

