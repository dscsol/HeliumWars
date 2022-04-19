// SPDX-License-Identifier: MIT
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
    uint256 public rewardMaxSupply;
    uint256 public totalRewardClaimed;
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

    constructor(Heliumwars _HeliumwarsNFTcontract) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        HeliumwarsNFTcontract = Heliumwars(_HeliumwarsNFTcontract);
    }

    function setStakableState(bool newState) external onlyRole(ADMIN) {
        stakableState = newState;
        emit stakableStateUpdated(newState);
    }

    function setRewardClaimableState(bool newState) external onlyRole(ADMIN) {
        rewardClaimableState = newState;
        emit rewardClaimableStateUpdated(newState);
    }

    function setRewardTokenContract(address addr) external onlyRole(ADMIN) {
        rewardTokenContract = addr;
    }

    function setRewardMaxSupply(uint256 amount) external onlyRole(ADMIN) {
        rewardMaxSupply = amount;
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
        returns (uint256)
    {
        return stakers[addr].tokenStakingStartingTime[tokenID];
    }

    function getBalance(address addr) external view returns (uint256) {
        return stakers[addr].rewardBalance;
    }

    function getRewardClaimed(address addr) external view returns (uint256) {
        return stakers[addr].rewardClaimed;
    }

    function stake(address addr, uint256 _tokenID) external {
        require(stakableState, "staking is not active");
        require(
            HeliumwarsNFTcontract.ownerOf(_tokenID) == msg.sender,
            "must be the owner of the NFT"
        );
        stakers[msg.sender].tokenIDs.push(_tokenID);
        stakers[msg.sender].tokenStakingStartingTime[_tokenID] = block
            .timestamp;
        tokenOwner[_tokenID] = msg.sender;
        HeliumwarsNFTcontract.safeTransferFrom(addr, address(this), _tokenID);
        emit Staked(msg.sender, _tokenID);
        totalStakedNFT++;
    }

    function batchStake(address addr, uint256[] memory _tokenIDs) external {
        require(stakableState, "staking is not active");
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(
                HeliumwarsNFTcontract.ownerOf(_tokenIDs[i]) == msg.sender,
                "must be the owner of the NFT"
            );
            stakers[msg.sender].tokenIDs.push(_tokenIDs[i]);
            stakers[msg.sender].tokenStakingStartingTime[_tokenIDs[i]] = block
                .timestamp;
            tokenOwner[_tokenIDs[i]] = msg.sender;
            HeliumwarsNFTcontract.approve(address(this), _tokenIDs[i]);
            HeliumwarsNFTcontract.safeTransferFrom(
                addr,
                address(this),
                _tokenIDs[i]
            );
            emit Staked(msg.sender, _tokenIDs[i]);
            totalStakedNFT++;
        }
    }

    function unstake(address addr, uint256 _tokenID) external {
        updateReward();
        claimReward(addr);

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
        HeliumwarsNFTcontract.safeTransferFrom(address(this), addr, _tokenID);
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

    function batchUnstake(address addr, uint256[] memory _tokenIDs) external {
        updateReward();
        claimReward(addr);

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
                addr,
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

    function claimReward(address addr) public {
        require(rewardClaimableState, "unstake is not active");
        require(stakers[msg.sender].rewardBalance > 0, "0 rewards yet");
        mint(addr, stakers[addr].rewardBalance);
        stakers[msg.sender].rewardClaimed += stakers[msg.sender].rewardBalance;
        stakers[msg.sender].rewardBalance = 0;
        emit RewardPaid(msg.sender, stakers[msg.sender].rewardBalance);
    }

    function updateReward() public {
        require(stakers[msg.sender].tokenIDs.length > 0, "no token staked");
        stakers[msg.sender].rewardBalance = 0;
        for (uint256 i = 0; i < stakers[msg.sender].tokenIDs.length; i++) {
            if (
                stakers[msg.sender].tokenStakingStartingTime[
                    stakers[msg.sender].tokenIDs[i]
                ] <
                block.timestamp &&
                stakers[msg.sender].tokenStakingStartingTime[
                    stakers[msg.sender].tokenIDs[i]
                ] >
                0
            ) {
                uint256 stakedDays = (
                    (block.timestamp -
                        uint256(
                            stakers[msg.sender].tokenStakingStartingTime[
                                stakers[msg.sender].tokenIDs[i]
                            ]
                        ))
                ) / stakingTimeUnit;

                stakers[msg.sender].rewardBalance += tokenUnit * stakedDays;
            }
        }
    }

    function mint(address addr, uint256 amount)
        internal
        returns (bool success)
    {
        require(
            rewardMaxSupply > totalRewardClaimed + amount,
            "reach max supply"
        );
        bytes memory payload = abi.encodeWithSignature(
            "mint(address, uint256)",
            addr,
            amount
        );
        address(rewardTokenContract).call(payload);
        totalRewardClaimed += amount;
        return true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
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
