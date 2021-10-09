const Strategy = artifacts.require('./SmartChef.sol')
const argv = require('yargs').argv
const fields = ['syrup', 'rewardToken', 'fee', 'rewardPerBlock', 'startBlock', 'bonusEndBlock']

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
            argv.syrup === 0 ? '0x0000000000000000000000000000000000000000' : argv.syrup,
            argv.rewardToken === 0 ? '0x0000000000000000000000000000000000000000' : argv.rewardToken,
            argv.fee === 0 ? '0x0000000000000000000000000000000000000000' : argv.fee,
            argv.rewardPerBlock,
            argv.startBlock,
            argv.bonusEndBlock
        )

    } else {
        console.log("fields error")
    }

}

