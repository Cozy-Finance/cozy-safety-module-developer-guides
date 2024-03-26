// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISafetyModuleCozyManager {
  struct Delays {
    uint64 configUpdateDelay;
    uint64 configUpdateGracePeriod;
    uint64 withdrawDelay;
  }

  struct ReservePoolConfig {
    uint256 maxSlashPercentage;
    address asset;
  }

  struct TriggerConfig {
    address trigger;
    address payoutHandler;
    bool exists;
  }

  struct UpdateConfigsCalldataParams {
    ReservePoolConfig[] reservePoolConfigs;
    TriggerConfig[] triggerConfigUpdates;
    Delays delaysConfig;
  }

  error InvalidAddress();
  error InvalidConfiguration();
  error Unauthorized();

  event ClaimedSafetyModuleFees(address indexed safetyModule_);
  event FeeDripModelUpdated(address indexed feeDripModel_);
  event OverrideFeeDripModelUpdated(address indexed safetyModule_, address indexed feeDripModel_);
  event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event PauserUpdated(address indexed newPauser_);

  function acceptOwnership() external;
  function allowedReservePools() external view returns (uint8);
  function claimFees(address safetyModules_) external;
  function computeSafetyModuleAddress(address caller_, bytes32 salt_) external view returns (address);
  function createSafetyModule(
    address owner_,
    address pauser_,
    UpdateConfigsCalldataParams memory configs_,
    bytes32 salt_
  ) external returns (address safetyModule_);
  function feeDripModel() external view returns (address);
  function getFeeDripModel(address safetyModule_) external view returns (address);
  function isSafetyModule(address) external view returns (bool);
  function overrideFeeDripModels(address) external view returns (address dripModel, bool exists);
  function owner() external view returns (address);
  function pause(address safetyModules_) external;
  function pauser() external view returns (address);
  function pendingOwner() external view returns (address);
  function resetOverrideFeeDripModel(address safetyModule_) external;
  function safetyModuleFactory() external view returns (address);
  function transferOwnership(address newOwner_) external;
  function unpause(address safetyModules_) external;
  function updateFeeDripModel(address feeDripModel_) external;
  function updateOverrideFeeDripModel(address safetyModule_, address feeDripModel_) external;
}
