// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SafetyModuleState} from "./Enums.sol";

interface ISafetyModule {
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

  struct RedemptionPreview {
    uint40 delayRemaining;
    uint216 receiptTokenAmount;
    address receiptToken;
    uint128 reserveAssetAmount;
    address owner;
    address receiver;
  }

  struct Slash {
    uint8 reservePoolId;
    uint256 amount;
  }

  event ClaimedFees(address indexed reserveAsset_, uint256 feeAmount_, address indexed owner_);
  event ConfigUpdatesFinalized(
    ReservePoolConfig[] reservePoolConfigs, TriggerConfig[] triggerConfigUpdates, Delays delaysConfig
  );
  event ConfigUpdatesQueued(
    ReservePoolConfig[] reservePoolConfigs,
    TriggerConfig[] triggerConfigUpdates,
    Delays delaysConfig,
    uint256 updateTime,
    uint256 updateDeadline
  );
  event Deposited(
    address indexed caller_,
    address indexed receiver_,
    uint8 indexed reservePoolId_,
    address depositReceiptToken_,
    uint256 assetAmount_,
    uint256 depositReceiptTokenAmount_
  );
  event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event PauserUpdated(address indexed newPauser_);
  event Redeemed(
    address caller_,
    address indexed receiver_,
    address indexed owner_,
    uint8 indexed reservePoolId_,
    address receiptToken_,
    uint256 receiptTokenAmount_,
    uint256 reserveAssetAmount_,
    uint64 redemptionId_
  );
  event RedemptionPending(
    address caller_,
    address indexed receiver_,
    address indexed owner_,
    uint8 indexed reservePoolId_,
    address receiptToken_,
    uint256 receiptTokenAmount_,
    uint256 reserveAssetAmount_,
    uint64 redemptionId_
  );
  event ReservePoolCreated(uint16 indexed reservePoolId, address reserveAsset, address depositReceiptToken);
  event SafetyModuleStateUpdated(SafetyModuleState indexed updatedTo_);
  event Slashed(
    address indexed payoutHandler_, address indexed receiver_, uint8 indexed reservePoolId_, uint256 assetAmount_
  );

  error AlreadySlashed(uint8 reservePoolId_);
  error AmountIsZero();
  error DelayNotElapsed();
  error ExceedsMaxSlashPercentage(uint8 reservePoolId_, uint256 slashPercentage_);
  error InvalidAddress();
  error InvalidConfiguration();
  error InvalidDeposit();
  error InvalidDripFactor();
  error InvalidState();
  error InvalidStateTransition();
  error InvalidTimestamp();
  error NoAssetsToRedeem();
  error RedemptionNotFound();
  error RoundsToZero();
  error Unauthorized();

  function acceptOwnership() external;
  function assetPools(address reserveAsset_) external view returns (uint256 amount);
  function claimFees(uint8[] memory reservePoolIds_) external;
  function claimFees(address owner_, address dripModel_) external;
  function completeRedemption(uint64 redemptionId_) external returns (uint256 reserveAssetAmount_);
  function convertToReceiptTokenAmount(uint8 reservePoolId_, uint256 reserveAssetAmount_)
    external
    view
    returns (uint256);
  function convertToReserveAssetAmount(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256);
  function cozySafetyModuleManager() external view returns (address);
  function delays()
    external
    view
    returns (uint64 configUpdateDelay, uint64 configUpdateGracePeriod, uint64 withdrawDelay);
  function depositReserveAssets(uint8 reservePoolId_, uint256 reserveAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);
  function depositReserveAssetsWithoutTransfer(uint8 reservePoolId_, uint256 reserveAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);
  function dripFees() external;
  function dripFeesFromReservePool(uint8 reservePoolId_) external;
  function finalizeUpdateConfigs(UpdateConfigsCalldataParams memory configUpdates_) external;
  function getMaxSlashableReservePoolAmount(uint8 reservePoolId_)
    external
    view
    returns (uint256 slashableReservePoolAmount_);
  function initialized() external view returns (bool);
  function lastConfigUpdate()
    external
    view
    returns (bytes32 queuedConfigUpdateHash, uint64 configUpdateTime, uint64 configUpdateDeadline);
  function numPendingSlashes() external view returns (uint16);
  function owner() external view returns (address);
  function pauser() external view returns (address);
  function payoutHandlerNumPendingSlashes(address payoutHandler_) external view returns (uint256 numPendingSlashes_);
  function pendingOwner() external view returns (address);
  function previewQueuedRedemption(uint64 redemptionId_)
    external
    view
    returns (RedemptionPreview memory redemptionPreview_);
  function previewRedemption(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 reserveAssetAmount_);
  function receiptTokenFactory() external view returns (address);
  function redeem(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_, address receiver_, address owner_)
    external
    returns (uint64 redemptionId_, uint256 reserveAssetAmount_);
  function redemptions(uint256)
    external
    view
    returns (
      uint8 reservePoolId,
      uint216 receiptTokenAmount,
      address receiptToken,
      uint128 assetAmount,
      address owner,
      address receiver,
      uint40 queueTime,
      uint40 delay,
      uint32 queuedAccISFsLength,
      uint256 queuedAccISF
    );
  function reservePools(uint256)
    external
    view
    returns (
      uint256 depositAmount,
      uint256 pendingWithdrawalsAmount,
      uint256 feeAmount,
      uint256 maxSlashPercentage,
      address asset,
      address depositReceiptToken,
      uint128 lastFeesDripTime
    );
  function safetyModuleState() external view returns (SafetyModuleState);
  function slash(Slash[] memory slashes_, address receiver_) external;
  function triggerData(address trigger_) external view returns (bool exists, address payoutHandler, bool triggered);
  function transferOwnership(address newOwner_) external;
  function updateConfigs(UpdateConfigsCalldataParams memory configUpdates_) external;
  function updatePauser(address newPauser_) external;
}
