// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
 Website: https://donutfarm.finance/
 twitter: https://twitter.com/donut_farm
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SmartChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastDepositBlock; // Block number of the last deposit.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e21. See below.
        bool isWithdrawFee;      // if the pool has withdraw fee
    }

    // The CAKE TOKEN!
    IERC20 public syrup;
    IERC20 public rewardToken;

    // CAKE tokens created per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // The block number when CAKE mining starts.
    uint256 public startBlock;
    // The block number when CAKE mining ends.
    uint256 public bonusEndBlock;

    uint256[] public withdrawalFeeIntervals = [28800, 57600, 86400];
    uint16[] public withdrawalFeeBP = [300, 200, 100, 0];
    uint16 public constant MAX_WITHDRAWAL_FEE_BP = 500;
    // fee address
    address public fee;
    // Approx Monday, 11 October 2021 19:00:00 GMT
    uint256 public startTime = 1633978800;
    // Counter StartTime
    uint256 public startTimeCount = 0;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event SetUpdateEmissionRate(uint256 indexed tokenPerBlock, uint256 indexed _tokenPerBlock);

    constructor(
        IERC20 _syrup,
        IERC20 _rewardToken,
        address _fee,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        syrup = _syrup;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        fee = _fee;

        poolInfo.push(PoolInfo({lpToken: _syrup, allocPoint: 1000, lastRewardBlock: startBlock, accCakePerShare: 0, isWithdrawFee: true}));

        totalAllocPoint = 1000;
    }

    function stopReward() public onlyOwner {
        bonusEndBlock = block.number;
    }

    function adjustBlockEnd() public {
        uint256 totalLeft = rewardToken.balanceOf(address(this));
        bonusEndBlock = block.number + totalLeft.div(rewardPerBlock);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e21).div(lpSupply));
        }
        return user.amount.mul(accCakePerShare).div(1e21).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e21).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Stake SYRUP tokens to SmartChef
    function deposit(uint256 _amount) public nonReentrant {
        require(block.timestamp > startTime, "!startTime");

        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e21).sub(user.rewardDebt);
            if (pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            user.lastDepositBlock = block.number;
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e21);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw SYRUP tokens from STAKING.
    function withdraw(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e21).sub(user.rewardDebt);
        if (pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if (_amount > 0) {

            user.amount = user.amount.sub(_amount);

            if (pool.isWithdrawFee) {
                uint16 withdrawFeeBP = getWithdrawFee(msg.sender);
                if (withdrawFeeBP > 0) {
                    uint256 withdrawFee = _amount.mul(withdrawFeeBP).div(10000);
                    pool.lpToken.safeTransfer(fee, withdrawFee);
                    _amount = (_amount).sub(withdrawFee);
                }
            }

            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e21);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < rewardToken.balanceOf(address(this)), "not enough token");
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    function updateEmissionRate(uint256 _tokenPerBlock) public onlyOwner {
        massUpdatePools();
        uint256 last_tokenPerBlock = rewardPerBlock;
        rewardPerBlock = _tokenPerBlock;
        adjustBlockEnd();
        emit SetUpdateEmissionRate(last_tokenPerBlock, _tokenPerBlock);
    }

    function balance() public view returns(uint256){
        return rewardToken.balanceOf(address(this));
    }

    function setWithdrawFee(uint256[] memory _withdrawalFeeIntervals, uint16[] memory _withdrawalFeeBP) external onlyOwner {
        require (_withdrawalFeeIntervals.length + 1 == _withdrawalFeeBP.length, 'setWithdrawFee: _withdrawalFeeBP length is one more than _withdrawalFeeIntervals length');
        require (_withdrawalFeeBP.length > 0, 'setWithdrawFee: _withdrawalFeeBP length is one more than 0');
        for (uint i = 0; i < _withdrawalFeeIntervals.length - 1; i++) {
            require (_withdrawalFeeIntervals[i] < _withdrawalFeeIntervals[i + 1], 'setWithdrawFee: The interval must be ascending');
        }
        for (uint i = 0; i < _withdrawalFeeBP.length; i++) {
            require (_withdrawalFeeBP[i] <= MAX_WITHDRAWAL_FEE_BP, 'setWithdrawFee: invalid withdrawal fee basis points');
        }
        withdrawalFeeIntervals = _withdrawalFeeIntervals;
        withdrawalFeeBP = _withdrawalFeeBP;
    }

    function getWithdrawFee(address _user) public view returns (uint16) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        if (!pool.isWithdrawFee) {
            return 0;
        }
        uint256 blockElapsed = block.number - user.lastDepositBlock;
        uint i = 0;
        for (; i < withdrawalFeeIntervals.length; i++) {
            if (blockElapsed < withdrawalFeeIntervals[i]) {
                break;
            }
        }
        return withdrawalFeeBP[i];
    }

    function inCaseOfRequiringChangeOfInitialDate(uint256 _newDate)
        external
        onlyOwner
    {
        require(startTimeCount == 0, "!inCaseOfRequiringChangeOfInitialDate");
        require(block.timestamp < _newDate, "!startTime");
        startTime = _newDate;
        startTimeCount = 1;
    }

}