// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRewardsManagerCozyManager {
  struct RewardPoolConfig {
    address asset;
    address dripModel;
  }

  struct StakePoolConfig {
    address asset;
    uint16 rewardsWeight;
  }

  error InvalidAddress();
  error Unauthorized();

  event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event PauserUpdated(address indexed newPauser_);

  function acceptOwnership() external;
  function computeRewardsManagerAddress(address caller_, bytes32 salt_) external view returns (address);
  function createRewardsManager(
    address owner_,
    address pauser_,
    StakePoolConfig[] memory stakePoolConfigs_,
    RewardPoolConfig[] memory rewardPoolConfigs_,
    bytes32 salt_
  ) external returns (address rewardsManager_);
  function owner() external view returns (address);
  function pause(address rewardsManagers_) external;
  function pauser() external view returns (address);
  function pendingOwner() external view returns (address);
  function rewardsManagerFactory() external view returns (address);
  function transferOwnership(address newOwner_) external;
  function unpause(address rewardsManagers_) external;
}
