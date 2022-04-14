pragma solidity ^0.8.4;

import "./Heliumwars.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTstaking is IERC721Receiver, AccessControl {
    using SafeMath for uint256;
    bytes32 public constant ADMIN = keccak256("ADMIN");
    Heliumwars public HeliumwarsNFTcontract;
    address public rewardTokenContract;
    bool public stakableState = false;
    bool public rewardClaimableState = false;
    uint256 public MAX_REWARD_ALLOWED;
    uint256 public totalStakedNFT;
    uint256 public tokenPerStakingTime;
    uint256 constant tokenUnit = 10e18;
    uint256 constant stakingTimeUnit = 1 days;

    struct staker {
        uint256[] tokenIDs;
        mapping(uint256 => uint256) tokenStakingStartingTime;
        uint256 rewardBalance;
        uint256 rewardClaimed;
    }

    mapping(address => staker) public stakers;
    mapping(uint256 => address) public tokenOwner;

    event rewardClaimableStateUpdated(bool status);
    event stakableStateUpdated(bool status);
    event Staked(address owner, uint256 tokenID);
    event Unstaked(address owner, uint256 tokenID);
    event RewardPaid(address owner, uint256 balance);

    constructor(
        Heliumwars _HeliumwarsNFTcontract,
        address _rewardTokenContract,
        uint256 _MAX_REWARD_ALLOWED,
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        HeliumwarsNFTcontract = Heliumwars(_HeliumwarsNFTcontract);
        rewardTokenContract = _rewardTokenContract;
        MAX_REWARD_ALLOWED = _MAX_REWARD_ALLOWED;
    }

    function setStakableState(bool newState) external onlyRole(ADMIN) {
        stakableState = newState;
        emit stakableStateUpdated(newState);
    }

    function setRewardClaimableState(bool newState) {
        rewardClaimableState = newState;
        emit rewardClaimableStateUpdated(newState);
    }

    function getStakedToken(address addr)
        external
        view
        returns (uint256[] memory tokenIDs)
    {
        return stakers[addr].tokenIDs;
    }

    function getTokenStakingStartingTime(address addr, uint256 tokenID)
        external
        view
        returns (uint256 memory tokenStakingStartingTime)
    {
        return stakers[addr].tokenStakingStartingTime;
    }

    function getBalance(address addr)
        external
        view
        returns (uint256 memory rewardBalance)
    {
        return stakers[addr].rewardBalance;
    }

    function getRewardClaimed(address addr)
        external
        view
        returns (uint256 memory rewardClaimed)
    {
        return stakers[addr].rewardClaimed;
    }

    function stake(uint256 _tokenID) external {
        require(stakableState, "staking is not active");
        require(
            HeliumwarsNFTcontract.ownerOf(_tokenID) == msg.sender,
            "must be the owner of the NFT"
        );
        stakers[msg.sender].tokenIDs.push(_tokenID);
        stakers[msg.sender].tokenStakingStartingTime[_tokenID] = block
            .timestamp;
        tokenOwner[_tokenID] = msg.sender;
        HeliumwarsNFTcontract.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID
        );
        emit Staked(msg.sender, _tokenID);
        totalStakedNFT++;
    }

    function batchStake(uint256[] memory _tokenIDs) external {
        require(stakableState, "staking is not active");
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(
                HeliumwarsNFTcontract.ownerOf(_tokenIDs[i]) == msg.sender,
                "must be the owner of the NFT"
            );
            stakers[msg.sender].tokenIDs.push(_tokenID[i]);
            stakers[msg.sender].tokenStakingStartingTime[_tokenID[i]] = block
                .timestamp;
            tokenOwner[_tokenID[i]] = msg.sender;
            HeliumwarsNFTcontract.approve(address(this), _tokenID[i]);
            HeliumwarsNFTcontract.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenID[i]
            );
            emit Staked(msg.sender, _tokenID[i]);
            totalStakedNFT++;
        }
    }

    function unstake(uint256 _tokenID) external {
        updateReward()
        claimReward();

        require(
            tokenOwner[_tokenID] == msg.sender,
            "must be the owner of the NFT"
        );

        uint256 index = indexOf(stakers[msg.sender].tokenIDs, _tokenID);
        stakers[msg.sender].tokenIDs[index] = stakers[msg.sender].tokenIDs[
            stakers[msg.sender].tokenIDs.length - 1
        ];

        if (stakers[msg.sender].tokenIDs.length > 0) {
            stakers[msg.sender].tokenIDs.pop();
        }
        stakers[msg.sender].tokenStakingStartingTime[_tokenID] = 0;
        HeliumwarsNFTcontract.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenID
        );
        delete tokenOwner[_tokenID];
        totalStakedNFT--;
        emit Unstaked(msg.sender, _tokenID);

        if (
            stakers[msg.sender].rewardBalance == 0 &&
            stakers[msg.sender].tokenIDs.length == 0
        ) {
            delete stakers[msg.sender];
        }
    }

    function batchUnstake(uint256[] memory _tokenIDs) external {
        updateReward()
        claimReward();

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(
                tokenOwner[_tokenIDs[i]] == msg.sender,
                "must be the owner of the NFT"
            );
            uint256 index = indexOf(stakers[msg.sender].tokenIDs, _tokenIDs[i]);
            stakers[msg.sender].tokenIDs[index] = stakers[msg.sender].tokenIDs[
                stakers[msg.sender].tokenIDs.length - 1
            ];

            if (stakers[msg.sender].tokenIDs.length > 0) {
                stakers[msg.sender].tokenIDs.pop();
            }
            stakers[msg.sender].tokenStakingStartingTime[_tokenIDs[i]] = 0;
            HeliumwarsNFTcontract.safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIDs[i]
            );
            delete tokenOwner[_tokenIDs[i]];
            totalStakedNFT--;
            emit Unstaked(msg.sender, _tokenIDs[i]);
        }
        if (
            stakers[msg.sender].rewardBalance == 0 &&
            stakers[msg.sender].tokenIDs.length == 0
        ) {
            delete stakers[msg.sender];
        }
    }

    function claimReward() public {
        require(rewardClaimableState, "unstake is not active");
        require(stakers[msg.sender].rewardBalance > 0, "0 rewards yet");
        stakers[msg.sender].rewardClaimed += stakers[msg.sender].rewardBalance;
        stakers[msg.sender].rewardBalance = 0;

        //mint

        emit RewardPaid(msg.sender, stakers[msg.sender].rewardBalance);
    }

    function updateReward() public {
        require(stakers[msg.sender].tokenIDs.length > 0, "no token staked");
        stakers[msg.sender].rewardBalance = 0
        for (uint256 i = 0; i < stakers[msg.sender].tokenIDs.length; i++) {
            
            if (
                stakers[msg.sender].tokenStakingStartingTime[stakers[msg.sender].tokenIDs[i]] <
                block.timestamp  &&
                stakers[msg.sender].tokenStakingStartingTime[stakers[msg.sender].tokenIDs[i]] > 0
            ) {
                uint256 stakedDays = (
                    (block.timestamp -
                        uint256(stakers[msg.sender].tokenStakingStartingTime[stakers[msg.sender].tokenIDs[i]]))
                ) / stakingTimeUnit;

                stakers[msg.sender].balance += token * stakedDays;
            }
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC721Received(address operator, address from, uint256 tokenId, bytes data)"
                )
            );
    }

    function indexOf(uint256[] memory arr, uint256 searchFor)
        private
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return i;
            }
        }
        revert("Not Found");
    }
}
