// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {RewardsManagerState} from "./Enums.sol";

interface IRewardsManager {
  struct ClaimableRewardsData {
    uint256 cumulativeClaimableRewards;
    uint256 indexSnapshot;
  }

  struct PreviewClaimableRewards {
    uint16 stakePoolId;
    PreviewClaimableRewardsData[] claimableRewardsData;
  }

  struct PreviewClaimableRewardsData {
    uint16 rewardPoolId;
    uint256 amount;
    address asset;
  }

  struct RewardPool {
    uint256 undrippedRewards;
    uint256 cumulativeDrippedRewards;
    uint128 lastDripTime;
    address asset;
    address dripModel;
    address depositReceiptToken;
  }

  struct RewardPoolConfig {
    address asset;
    address dripModel;
  }

  struct StakePool {
    uint256 amount;
    address asset;
    address stkReceiptToken;
    uint16 rewardsWeight;
  }

  struct StakePoolConfig {
    address asset;
    uint16 rewardsWeight;
  }

  struct UserRewardsData {
    uint256 accruedRewards;
    uint256 indexSnapshot;
  }

  error AddressEmptyCode(address target);
  error AddressInsufficientBalance(address account);
  error AmountIsZero();
  error FailedInnerCall();
  error Initialized();
  error InvalidAddress();
  error InvalidConfiguration();
  error InvalidDeposit();
  error InvalidDripFactor();
  error InvalidState();
  error InvalidStateTransition();
  error RoundsToZero();
  error SafeERC20FailedOperation(address token);
  error Unauthorized();

  event ClaimedRewards(
    uint16 indexed stakePoolId_,
    uint16 indexed rewardPoolId_,
    address rewardAsset_,
    uint256 amount_,
    address indexed owner_,
    address receiver_
  );
  event ConfigUpdatesApplied(StakePoolConfig[] stakePoolConfigs, RewardPoolConfig[] rewardPoolConfigs);
  event Deposited(
    address indexed caller_,
    address indexed receiver_,
    uint16 indexed rewardPoolId_,
    address depositReceiptToken_,
    uint256 assetAmount_,
    uint256 depositReceiptTokenAmount_
  );
  event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event PauserUpdated(address indexed newPauser_);
  event RedeemedUndrippedRewards(
    address caller_,
    address indexed receiver_,
    address indexed owner_,
    uint16 indexed rewardPoolId_,
    address depositReceiptToken_,
    uint256 depositReceiptTokenAmount_,
    uint256 rewardAssetAmount_
  );
  event RewardPoolCreated(uint16 indexed rewardPoolId, address depositReceiptToken, address asset);
  event RewardsManagerStateUpdated(RewardsManagerState indexed updatedTo_);
  event StakePoolCreated(uint16 indexed stakePoolId, address stkReceiptToken, address asset);
  event Staked(
    address indexed caller_,
    address indexed receiver_,
    uint16 indexed stakePoolId_,
    address stkReceiptToken_,
    uint256 assetAmount_
  );
  event Unstaked(
    address caller_,
    address indexed receiver_,
    address indexed owner_,
    uint16 indexed stakePoolId_,
    address stkReceiptToken_,
    uint256 stkReceiptTokenAmount_
  );

  function acceptOwnership() external;
  function allowedRewardPools() external view returns (uint16);
  function allowedStakePools() external view returns (uint16);
  function assetPools(address asset_) external view returns (uint256 amount);
  function assetToStakePoolIds(address asset_) external view returns (uint16 index, bool exists);
  function claimRewards(uint16 stakePoolId_, address receiver_) external;
  function claimRewards(uint16[] memory stakePoolIds_, address receiver_) external;
  function claimableRewards(uint16, uint16)
    external
    view
    returns (uint256 cumulativeClaimableRewards, uint256 indexSnapshot);
  function convertRewardAssetToReceiptTokenAmount(uint16 rewardPoolId_, uint256 rewardAssetAmount_)
    external
    view
    returns (uint256 depositReceiptTokenAmount_);
  function convertRewardReceiptTokenToAssetAmount(uint16 rewardPoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 rewardAssetAmount_);
  function cozyManager() external view returns (address);
  function depositRewardAssets(uint16 rewardPoolId_, uint256 rewardAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);
  function depositRewardAssetsWithoutTransfer(uint16 rewardPoolId_, uint256 rewardAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);
  function dripRewardPool(uint16 rewardPoolId_) external;
  function dripRewards() external;
  function getClaimableRewards(uint16 stakePoolId_) external view returns (ClaimableRewardsData[] memory);
  function getClaimableRewards() external view returns (ClaimableRewardsData[][] memory);
  function getRewardPools() external view returns (RewardPool[] memory);
  function getStakePools() external view returns (StakePool[] memory);
  function getUserRewards(uint16 stakePoolId_, address user) external view returns (UserRewardsData[] memory);
  function initialize(
    address owner_,
    address pauser_,
    StakePoolConfig[] memory stakePoolConfigs_,
    RewardPoolConfig[] memory rewardPoolConfigs_
  ) external;
  function initialized() external view returns (bool);
  function owner() external view returns (address);
  function pause() external;
  function pauser() external view returns (address);
  function pendingOwner() external view returns (address);
  function previewClaimableRewards(uint16[] memory stakePoolIds_, address owner_)
    external
    view
    returns (PreviewClaimableRewards[] memory previewClaimableRewards_);
  function previewUndrippedRewardsRedemption(uint16 rewardPoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 rewardAssetAmount_);
  function receiptTokenFactory() external view returns (address);
  function redeemUndrippedRewards(
    uint16 rewardPoolId_,
    uint256 depositReceiptTokenAmount_,
    address receiver_,
    address owner_
  ) external returns (uint256 rewardAssetAmount_);
  function rewardPools(uint256)
    external
    view
    returns (
      uint256 undrippedRewards,
      uint256 cumulativeDrippedRewards,
      uint128 lastDripTime,
      address asset,
      address dripModel,
      address depositReceiptToken
    );
  function rewardsManagerState() external view returns (RewardsManagerState);
  function stake(uint16 stakePoolId_, uint256 assetAmount_, address receiver_) external;
  function stakePools(uint256)
    external
    view
    returns (uint256 amount, address asset, address stkReceiptToken, uint16 rewardsWeight);
  function stakeWithoutTransfer(uint16 stakePoolId_, uint256 assetAmount_, address receiver_) external;
  function stkReceiptTokenToStakePoolIds(address stkReceiptToken_) external view returns (uint16 index, bool exists);
  function transferOwnership(address newOwner_) external;
  function unpause() external;
  function unstake(uint16 stakePoolId_, uint256 stkReceiptTokenAmount_, address receiver_, address owner_) external;
  function updateConfigs(StakePoolConfig[] memory stakePoolConfigs_, RewardPoolConfig[] memory rewardPoolConfigs_)
    external;
  function updatePauser(address newPauser_) external;
  function updateUserRewardsForStkReceiptTokenTransfer(address from_, address to_) external;
  function userRewards(uint16, address, uint256) external view returns (uint256 accruedRewards, uint256 indexSnapshot);
}
