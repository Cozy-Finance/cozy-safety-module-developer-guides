// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICozyRouter {
  struct Delays {
    uint64 configUpdateDelay;
    uint64 configUpdateGracePeriod;
    uint64 withdrawDelay;
  }

  struct Metadata {
    string name;
    string description;
    string logoURI;
    string extraData;
  }

  struct ReservePoolConfig {
    uint256 maxSlashPercentage;
    address asset;
  }

  struct RewardPoolConfig {
    address asset;
    address dripModel;
  }

  struct StakePoolConfig {
    address asset;
    uint16 rewardsWeight;
  }

  struct TriggerConfig {
    address trigger;
    address payoutHandler;
    bool exists;
  }

  struct TriggerMetadata {
    string name;
    string description;
    string logoURI;
    string extraData;
  }

  struct UpdateConfigsCalldataParams {
    ReservePoolConfig[] reservePoolConfigs;
    TriggerConfig[] triggerConfigUpdates;
    Delays delaysConfig;
  }

  error CallFailed(uint256 index, bytes returnData);
  error InsufficientBalance();
  error InvalidAddress();
  error TransferFailed();

  receive() external payable;

  function aggregate(bytes[] memory calls_) external payable returns (bytes[] memory returnData_);
  function chainlinkTriggerFactory() external view returns (address);
  function completeRedemption(address safetyModule_, uint64 id_) external payable;
  function completeWithdraw(address safetyModule_, uint64 id_) external payable;
  function computeSalt(address caller_, bytes32 baseSalt_) external pure returns (bytes32);
  function deployChainlinkFixedPriceTrigger(
    int256 price_,
    uint8 decimals_,
    address trackingOracle_,
    uint256 priceTolerance_,
    uint256 frequencyTolerance_,
    TriggerMetadata memory metadata_
  ) external payable returns (address trigger_);
  function deployChainlinkTrigger(
    address truthOracle_,
    address trackingOracle_,
    uint256 priceTolerance_,
    uint256 truthFrequencyTolerance_,
    uint256 trackingFrequencyTolerance_,
    TriggerMetadata memory metadata_
  ) external payable returns (address trigger_);
  function deployDripModelConstant(address owner_, uint256 amountPerSecond_, bytes32 baseSalt_)
    external
    payable
    returns (address dripModel_);
  function deployOwnableTrigger(address owner_, TriggerMetadata memory metadata_, bytes32 salt_)
    external
    payable
    returns (address trigger_);
  function deployRewardsManager(
    address owner_,
    address pauser_,
    StakePoolConfig[] memory stakePoolConfigs_,
    RewardPoolConfig[] memory rewardPoolConfigs_,
    bytes32 salt_
  ) external payable returns (address rewardsManager_);
  function deploySafetyModule(
    address owner_,
    address pauser_,
    UpdateConfigsCalldataParams memory configs_,
    bytes32 salt_
  ) external payable returns (address safetyModule_);
  function deployUMATrigger(
    string memory query_,
    address rewardToken_,
    uint256 rewardAmount_,
    address refundRecipient_,
    uint256 bondAmount_,
    uint256 proposalDisputeWindow_,
    TriggerMetadata memory metadata_
  ) external payable returns (address trigger_);
  function depositReserveAssets(
    address safetyModule_,
    uint8 reservePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) external payable returns (uint256 depositReceiptTokenAmount_);
  function depositReserveAssetsAndStake(
    address safetyModule_,
    address rewardsManager_,
    uint8 reservePoolId_,
    uint16 stakePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) external payable returns (uint256 receiptTokenAmount_);
  function depositReserveAssetsViaConnectorAndStake(
    address connector_,
    address safetyModule_,
    address rewardsManager_,
    uint8 reservePoolId_,
    uint16 stakePoolId_,
    uint256 baseAssetAmount_,
    address receiver_
  ) external payable returns (uint256 receiptTokenAmount_);
  function depositReserveAssetsWithoutTransfer(
    address safetyModule_,
    uint8 reservePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) external payable returns (uint256 depositReceiptTokenAmount_);
  function depositRewardAssets(
    address rewardsManager_,
    uint16 rewardPoolId_,
    uint256 rewardAssetAmount_,
    address receiver_
  ) external payable returns (uint256 depositReceiptTokenAmount_);
  function depositRewardAssetsWithoutTransfer(
    address rewardsManager_,
    uint16 rewardPoolId_,
    uint256 rewardAssetAmount_,
    address receiver_
  ) external payable returns (uint256 depositReceiptTokenAmount_);
  function dripModelConstantFactory() external view returns (address);
  function ownableTriggerFactory() external view returns (address);
  function permitRouter(address token_, uint256 value_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
    external
    payable;
  function redeemReservePoolDepositReceiptTokens(
    address safetyModule_,
    uint8 reservePoolId_,
    uint256 depositReceiptTokenAmount_,
    address receiver_
  ) external payable returns (uint64 redemptionId_, uint256 assetsReceived_);
  function redeemRewardPoolDepositReceiptTokens(
    address rewardsManager_,
    uint16 rewardPoolId_,
    uint256 depositReceiptTokenAmount_,
    address receiver_
  ) external payable returns (uint256 assetsReceived_);
  function rewardsManagerCozyManager() external view returns (address);
  function safetyModuleCozyManager() external view returns (address);
  function stEth() external view returns (address);
  function stake(address rewardsManager_, uint16 stakePoolId_, uint256 stakeAssetAmount_, address receiver_)
    external
    payable;
  function stakeWithoutTransfer(
    address rewardsManager_,
    uint16 stakePoolId_,
    uint256 stakeAssetAmount_,
    address receiver_
  ) external payable;
  function sweepToken(address token_, address recipient_, uint256 amountMin_)
    external
    payable
    returns (uint256 amount_);
  function transferTokens(address token_, address recipient_, uint256 amount_) external payable;
  function umaTriggerFactory() external view returns (address);
  function unstake(address rewardsManager_, uint16 stakePoolId_, uint256 stakeReceiptTokenAmount, address receiver_)
    external
    payable;
  function unstakeReserveAssetsAndWithdraw(
    address safetyModule_,
    address rewardsManager_,
    uint8 reservePoolId_,
    uint16 stakePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) external payable returns (uint64 redemptionId_, uint256 stakeReceiptTokenAmount_);
  function unstakeStakeReceiptTokensAndRedeem(
    address safetyModule_,
    address rewardsManager_,
    uint8 reservePoolId_,
    uint16 stakePoolId_,
    uint256 stakeReceiptTokenAmount_,
    address receiver_
  ) external payable returns (uint64 redemptionId_, uint256 reserveAssetAmount_);
  function unwrapStEth(address recipient_) external;
  function unwrapWeth(address recipient_, uint256 amount_) external payable;
  function unwrapWeth(address recipient_) external payable;
  function unwrapWrappedAssetViaConnector(address connector_, uint256 assets_, address receiver_) external payable;
  function unwrapWrappedAssetViaConnectorForWithdraw(address connector_, address receiver_) external payable;
  function updateSafetyModuleMetadata(address metadataRegistry_, address safetyModule_, Metadata memory metadata_)
    external
    payable;
  function weth() external view returns (address);
  function withdrawReservePoolAssets(
    address safetyModule_,
    uint8 reservePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) external payable returns (uint64 redemptionId_, uint256 depositReceiptTokenAmount_);
  function withdrawRewardPoolAssets(
    address rewardsManager_,
    uint8 rewardPoolId_,
    uint256 rewardAssetAmount_,
    address receiver_
  ) external payable returns (uint256 depositReceiptTokenAmount_);
  function wrapBaseAssetViaConnectorAndDepositReserveAssets(
    address connector_,
    address safetyModule_,
    uint8 reservePoolId_,
    uint256 baseAssetAmount_,
    address receiver_
  ) external payable returns (uint256 depositReceiptTokenAmount_);
  function wrapBaseAssetViaConnectorAndDepositRewardAssets(
    address connector_,
    address rewardsManager_,
    uint8 reservePoolId_,
    uint256 baseAssetAmount_,
    address receiver_
  ) external payable returns (uint256 depositReceiptTokenAmount_);
  function wrapStEth(address safetyModule_) external;
  function wrapStEth(address safetyModule_, uint256 amount_) external;
  function wrapWeth(address safetyModule_, uint256 amount_) external payable;
  function wrapWeth(address safetyModule_) external payable;
  function wstEth() external view returns (address);
}
