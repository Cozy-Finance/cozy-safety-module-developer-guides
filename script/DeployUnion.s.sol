// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

import {IERC20} from "../src/interfaces/IERC20.sol";
import {ICozyRouter} from "../src/interfaces/ICozyRouter.sol";
import {IDripModelConstantFactory} from "../src/interfaces/IDripModelConstantFactory.sol";
import {IRewardsManagerCozyManager} from "../src/interfaces/IRewardsManagerCozyManager.sol";
import {ISafetyModuleCozyManager} from "../src/interfaces/ISafetyModuleCozyManager.sol";
import {ISafetyModule} from "../src/interfaces/ISafetyModule.sol";
import {ITrigger} from "../src/interfaces/ITrigger.sol";
import {IMetadataRegistry} from "../src/interfaces/IMetadataRegistry.sol";
import {IOwnableTriggerFactory} from "../src/interfaces/IOwnableTriggerFactory.sol";
import {IRewardsManager} from "../src/interfaces/IRewardsManager.sol";
import {ScriptUtils} from "./utils/ScriptUtils.sol";
import {console2} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";

/**
 * @dev To run this script:
 *
 * ```sh
 * # Start anvil, forking from the current state of the desired chain.
 * anvil --fork-url $ETH_RPC_URL
 *
 * # Impersonate the Union DAO address and fund address
 * cast rpc --rpc-url "http://127.0.0.1:8545" anvil_impersonateAccount 0xBBD3321f377742c4b3fe458b270c2F271d3294D8
 * cast rpc --rpc-url "http://127.0.0.1:8545" anvil_setBalance 0xBBD3321f377742c4b3fe458b270c2F271d3294D8
 * 10000000000000000000
 *
 * # In a separate terminal, perform a dry run the script.
 * forge script script/DeployUnion.s.sol \
 *   --sig "run(string)" "deploy-union"
 *   --rpc-url "http://127.0.0.1:8545" \
 *   -vvvv \
 *   --sender 0xBBD3321f377742c4b3fe458b270c2F271d3294D8 \
 *   --unlocked
 *
 * # Or, to broadcast transactions.
 * forge script script/DeployUnion.s.sol \
 *   --sig "run(string)" "deploy-union"
 *   --rpc-url "http://127.0.0.1:8545" \
 *   --broadcast \
 *   -vvvv \
 *   --sender 0xBBD3321f377742c4b3fe458b270c2F271d3294D8 \
 *   --unlocked
 * ```
 */
contract DeployUnion is ScriptUtils {
  using stdJson for string;

  address caller_ = address(0xBBD3321f377742c4b3fe458b270c2F271d3294D8);
  ICozyRouter router = ICozyRouter(payable(address(0xC58F8634E085243CC661b1623B3bC3224D80B439)));
  ISafetyModuleCozyManager cozySafetyModuleManager =
    ISafetyModuleCozyManager(address(0x388C9BcBFc8279caae1F85AD164dA61C7a04CEDb));
  IOwnableTriggerFactory ownableTriggerFactory =
    IOwnableTriggerFactory(address(0xFBE275c3a83235357FC5Edf5AfDf68bA6682f785));
  IMetadataRegistry metadataRegistry = IMetadataRegistry(address(0xA97a1cC5609E8149b5fe0902F9076BF125009346));
  IDripModelConstantFactory dripModelConstantFactory =
    IDripModelConstantFactory(address(0x372eA1BF5728EDef068034cf4531F8E6049a3d3a));
  IRewardsManagerCozyManager rewardsManagerCozyManager =
    IRewardsManagerCozyManager(address(0x6a4b05e7759152dDB113dacA8148a16e513Befe4));

  function run(string memory fileName_) public virtual {
    string memory json_ = readInput(fileName_);
    address deployedTrigger_ = deployTrigger(json_);
    assert(
      deployedTrigger_
        == ownableTriggerFactory.computeTriggerAddress(
          caller_, router.computeSalt(caller_, json_.readBytes32(".triggerSalt"))
        )
    );

    (address deployedSafetyModule_, address depositReceiptToken_) = deploySafetyModule(json_, deployedTrigger_);
    assert(
      deployedSafetyModule_
        == cozySafetyModuleManager.computeSafetyModuleAddress(
          address(router), router.computeSalt(caller_, json_.readBytes32(".safetyModuleSalt"))
        )
    );

    updateMetadata(json_, deployedSafetyModule_);

    address dripModel_ = deployRewardsDripModel(json_);
    uint256 amountPerSecond_ =
      json_.readUint(".tokensPerDay") * 10 ** IERC20(json_.readAddress(".rewardPoolAsset")).decimals() / (60 * 60 * 24);
    assert(
      dripModel_
        == dripModelConstantFactory.computeAddress(
          address(router),
          json_.readAddress(".dripModelOwner"),
          amountPerSecond_,
          router.computeSalt(caller_, json_.readBytes32(".dripModelSalt"))
        )
    );

    address deployedRewardsManager_ = deployRewardsManager(json_, depositReceiptToken_, dripModel_);
    assert(
      deployedRewardsManager_
        == rewardsManagerCozyManager.computeRewardsManagerAddress(
          address(router), router.computeSalt(caller_, json_.readBytes32(".rewardsManagerSalt"))
        )
    );
  }

  function deployTrigger(string memory json_) public virtual returns (address) {
    // -------- Load json --------
    address triggerOwner_ = json_.readAddress(".triggerOwner");
    bytes32 triggerSalt_ = json_.readBytes32(".triggerSalt");
    ICozyRouter.TriggerMetadata memory triggerMetadata_ = ICozyRouter.TriggerMetadata(
      json_.readString(".triggerName"),
      json_.readString(".triggerDescription"),
      json_.readString(".triggerLogoURI"),
      json_.readString(".triggerExtraData")
    );

    // -------------------------------------
    // ----------- Generate Calldata -------
    // -------------------------------------
    address targetContract_ = address(router);
    uint256 value_ = 0;
    bytes memory calldata_ = abi.encode(
      triggerOwner_,
      ICozyRouter.TriggerMetadata(
        triggerMetadata_.description, triggerMetadata_.extraData, triggerMetadata_.logoURI, triggerMetadata_.name
      ),
      triggerSalt_
    );
    bytes memory payload_ = abi.encodeWithSelector(
      router.deployOwnableTrigger.selector,
      triggerOwner_,
      ICozyRouter.TriggerMetadata(
        triggerMetadata_.description, triggerMetadata_.extraData, triggerMetadata_.logoURI, triggerMetadata_.name
      ),
      triggerSalt_
    );
    string memory signature_ = "deployOwnableTrigger(address,(string,string,string,string),bytes32)";

    console2.log("targetContract", targetContract_);
    console2.log("value", value_);
    console2.log("signature", signature_);
    console2.log("calldata:");
    console2.logBytes(calldata_);
    console2.log("payload:");
    console2.logBytes(payload_);
    assert(keccak256(payload_) == keccak256(abi.encodePacked(bytes4(keccak256(bytes(signature_))), calldata_)));

    // -------------------------------------
    // ----------- Deploy Trigger ----------
    // -------------------------------------
    console2.log("========");
    console2.log("Deploying OwnableTrigger...");
    console2.log("    triggerOwner", triggerOwner_);
    console2.log("    triggerName", triggerMetadata_.name);
    console2.log("    triggerDescription", triggerMetadata_.description);
    console2.log("    triggerLogoURI", triggerMetadata_.logoURI);
    console2.log("    triggerExtraData", triggerMetadata_.extraData);

    require(triggerOwner_ != address(0), "Trigger owner cannot be zero address");

    vm.broadcast();
    address deployedTrigger_ = router.deployOwnableTrigger(
      triggerOwner_,
      ICozyRouter.TriggerMetadata(
        triggerMetadata_.description, triggerMetadata_.extraData, triggerMetadata_.logoURI, triggerMetadata_.name
      ),
      triggerSalt_
    );

    console2.log("OwnableTrigger deployed", deployedTrigger_);
    console2.log("========");

    return deployedTrigger_;
  }

  function deploySafetyModule(string memory json_, address deployedTrigger_) public virtual returns (address, address) {
    // -------- Load json --------
    address safetyModuleOwner_ = json_.readAddress(".safetyModuleOwner");
    address safetyModulePauser_ = json_.readAddress(".safetyModulePauser");
    bytes32 safetyModuleSalt_ = json_.readBytes32(".safetyModuleSalt");

    address reservePoolAsset_ = json_.readAddress(".reservePoolAsset");
    uint256 reservePoolMaxSlashPercentage_ = json_.readUint(".reservePoolMaxSlashPercentage");
    ICozyRouter.ReservePoolConfig[] memory reservePoolConfigs_ = new ICozyRouter.ReservePoolConfig[](1);
    reservePoolConfigs_[0] = ICozyRouter.ReservePoolConfig(reservePoolMaxSlashPercentage_, reservePoolAsset_);

    address payoutHandler_ = json_.readAddress(".payoutHandlerAddress");
    ICozyRouter.TriggerConfig[] memory triggerConfigs_ = new ICozyRouter.TriggerConfig[](1);
    triggerConfigs_[0] = ICozyRouter.TriggerConfig(deployedTrigger_, payoutHandler_, true);

    ICozyRouter.Delays memory delays_ = ICozyRouter.Delays(
      uint64(json_.readUint(".delaysConfigUpdateDelay")),
      uint64(json_.readUint(".delaysConfigUpdateGracePeriod")),
      uint64(json_.readUint(".delaysWithdrawalDelay"))
    );

    ICozyRouter.UpdateConfigsCalldataParams memory configs_ =
      ICozyRouter.UpdateConfigsCalldataParams(reservePoolConfigs_, triggerConfigs_, delays_);

    // -------------------------------------
    // ----------- Generate Calldata -------
    // -------------------------------------
    address targetContract_ = address(router);
    uint256 value_ = 0;
    bytes memory calldata_ = abi.encode(safetyModuleOwner_, safetyModulePauser_, configs_, safetyModuleSalt_);
    bytes memory payload_ = abi.encodeWithSelector(
      router.deploySafetyModule.selector, safetyModuleOwner_, safetyModulePauser_, configs_, safetyModuleSalt_
    );
    string memory signature_ =
      "deploySafetyModule(address,address,((uint256,address)[],(address,address,bool)[],(uint64,uint64,uint64)),bytes32)";

    console2.log("targetContract", targetContract_);
    console2.log("value", value_);
    console2.log("signature", signature_);
    console2.log("calldata:");
    console2.logBytes(calldata_);
    console2.log("payload:");
    console2.logBytes(payload_);
    assert(keccak256(payload_) == keccak256(abi.encodePacked(bytes4(keccak256(bytes(signature_))), calldata_)));

    // -------------------------------------
    // ------ Deploy SafetyModule ----------
    // -------------------------------------
    console2.log("========");
    console2.log("Deploying SafetyModule...");
    console2.log("    safetyModuleOwner", safetyModuleOwner_);
    console2.log("    safetyModulePauser", safetyModulePauser_);
    console2.log("    reservePoolAsset", reservePoolAsset_);
    console2.log("    reservePoolMaxSlashPercentage", reservePoolMaxSlashPercentage_);
    console2.log("    triggerPayoutHandler", payoutHandler_);
    console2.log("    triggerAddress", deployedTrigger_);
    console2.log("    delaysConfigUpdateDelay", delays_.configUpdateDelay);
    console2.log("    delaysConfigUpdateGracePeriod", delays_.configUpdateGracePeriod);
    console2.log("    delaysWithdrawDelay", delays_.withdrawDelay);

    vm.broadcast();
    address safetyModule_ =
      router.deploySafetyModule(safetyModuleOwner_, safetyModulePauser_, configs_, safetyModuleSalt_);

    console2.log("SafetyModule deployed", safetyModule_);
    console2.log("========");

    (,,,,, address depositReceiptToken_,) = ISafetyModule(safetyModule_).reservePools(0);

    return (safetyModule_, depositReceiptToken_);
  }

  function updateMetadata(string memory json_, address deployedSafetyModule_) public virtual {
    // -------- Load json --------
    ICozyRouter.Metadata memory metadata_ = ICozyRouter.Metadata(
      json_.readString(".name"),
      json_.readString(".description"),
      json_.readString(".logoURI"),
      json_.readString(".extraData")
    );

    // -------------------------------------
    // ----------- Generate Calldata -------
    // -------------------------------------
    address targetContract_ = address(router);
    uint256 value_ = 0;
    bytes memory calldata_ = abi.encode(metadataRegistry, deployedSafetyModule_, metadata_);
    bytes memory payload_ = abi.encodeWithSelector(
      router.updateSafetyModuleMetadata.selector, metadataRegistry, deployedSafetyModule_, metadata_
    );
    string memory signature_ = "updateSafetyModuleMetadata(address,address,(string,string,string,string))";

    console2.log("targetContract", targetContract_);
    console2.log("value", value_);
    console2.log("signature", signature_);
    console2.log("calldata:");
    console2.logBytes(calldata_);
    console2.log("payload:");
    console2.logBytes(payload_);
    assert(keccak256(payload_) == keccak256(abi.encodePacked(bytes4(keccak256(bytes(signature_))), calldata_)));

    // -------------------------------------
    // --------  Update Metadata  ----------
    // -------------------------------------
    console2.log("========");
    console2.log("Updating SafetyModule Metadata...");
    console2.log("    SafetyModule", deployedSafetyModule_);
    console2.log("    Metadata.name", metadata_.name);
    console2.log("    Metadata.description", metadata_.description);
    console2.log("    Metadata.logoURI", metadata_.logoURI);
    console2.log("    Metadata.extraData", metadata_.extraData);

    vm.broadcast();
    router.updateSafetyModuleMetadata(address(metadataRegistry), deployedSafetyModule_, metadata_);

    console2.log("SafetyModule Metadata updated");
    console2.log("========");
  }

  function deployRewardsDripModel(string memory json_) public virtual returns (address) {
    // -------- Load json --------
    address dripModelOwner_ = json_.readAddress(".dripModelOwner");
    uint256 tokensPerDay_ = json_.readUint(".tokensPerDay");
    bytes32 dripModelSalt_ = json_.readBytes32(".dripModelSalt");
    uint256 decimals_ = IERC20(json_.readAddress(".rewardPoolAsset")).decimals();
    uint256 amountPerSecond_ = (tokensPerDay_ * 10 ** decimals_) / (60 * 60 * 24);

    // -------------------------------------
    // ----------- Generate Calldata -------
    // -------------------------------------
    address targetContract_ = address(router);
    uint256 value_ = 0;
    bytes memory calldata_ = abi.encode(dripModelOwner_, amountPerSecond_, dripModelSalt_);
    bytes memory payload_ =
      abi.encodeWithSelector(router.deployDripModelConstant.selector, dripModelOwner_, amountPerSecond_, dripModelSalt_);
    string memory signature_ = "deployDripModelConstant(address,uint256,bytes32)";

    console2.log("targetContract", targetContract_);
    console2.log("value", value_);
    console2.log("signature", signature_);
    console2.log("calldata:");
    console2.logBytes(calldata_);
    console2.log("payload:");
    console2.logBytes(payload_);
    assert(keccak256(payload_) == keccak256(abi.encodePacked(bytes4(keccak256(bytes(signature_))), calldata_)));

    // -------------------------------------
    // ------ Deploy Drip model   ----------
    // -------------------------------------
    console2.log("========");
    console2.log("Deploying DripModelConstant...");
    console2.log("    dripModelOwner", dripModelOwner_);
    console2.log("    amountPerSecond", amountPerSecond_);

    vm.broadcast();
    address dripModel_ = router.deployDripModelConstant(dripModelOwner_, amountPerSecond_, dripModelSalt_);

    console2.log("DripModelConstant deployed", dripModel_);
    console2.log("========");

    return dripModel_;
  }

  function deployRewardsManager(string memory json_, address depositReceiptToken_, address dripModel_)
    public
    virtual
    returns (address)
  {
    address rewardsManagerOwner_ = json_.readAddress(".rewardsManagerOwner");
    address rewardsManagerPauser_ = json_.readAddress(".rewardsManagerPauser");
    bytes32 rewardsManagerSalt_ = json_.readBytes32(".rewardsManagerSalt");

    ICozyRouter.StakePoolConfig[] memory stakePoolConfigs_ = new ICozyRouter.StakePoolConfig[](1);
    stakePoolConfigs_[0] = ICozyRouter.StakePoolConfig(depositReceiptToken_, 10_000);
    ICozyRouter.RewardPoolConfig[] memory rewardsPoolConfigs_ = new ICozyRouter.RewardPoolConfig[](1);
    rewardsPoolConfigs_[0] = ICozyRouter.RewardPoolConfig(json_.readAddress(".rewardPoolAsset"), dripModel_);

    // -------------------------------------
    // ----------- Generate Calldata -------
    // -------------------------------------
    address targetContract_ = address(router);
    uint256 value_ = 0;
    bytes memory calldata_ = abi.encode(
      rewardsManagerOwner_, rewardsManagerPauser_, stakePoolConfigs_, rewardsPoolConfigs_, rewardsManagerSalt_
    );
    bytes memory payload_ = abi.encodeWithSelector(
      router.deployRewardsManager.selector,
      rewardsManagerOwner_,
      rewardsManagerPauser_,
      stakePoolConfigs_,
      rewardsPoolConfigs_,
      rewardsManagerSalt_
    );
    string memory signature_ = "deployRewardsManager(address,address,(address,uint16)[],(address,address)[],bytes32)";

    console2.log("targetContract", targetContract_);
    console2.log("value", value_);
    console2.log("signature", signature_);
    console2.log("calldata:");
    console2.logBytes(calldata_);
    console2.log("payload:");
    console2.logBytes(payload_);
    assert(keccak256(payload_) == keccak256(abi.encodePacked(bytes4(keccak256(bytes(signature_))), calldata_)));

    // -------------------------------------
    // ------ Deploy RewardsManager --------
    // -------------------------------------
    console2.log("========");
    console2.log("Deploying RewardsManager...");
    console2.log("    rewardsManagerOwner", rewardsManagerOwner_);
    console2.log("    rewardsManagerPauser", rewardsManagerPauser_);
    console2.log("    stakeAsset", stakePoolConfigs_[0].asset);
    console2.log("    stakeAssetWeight", stakePoolConfigs_[0].rewardsWeight);
    console2.log("    rewardAsset", rewardsPoolConfigs_[0].asset);
    console2.log("    dripModel", rewardsPoolConfigs_[0].dripModel);

    vm.broadcast();
    address rewardsManager_ = router.deployRewardsManager(
      rewardsManagerOwner_, rewardsManagerPauser_, stakePoolConfigs_, rewardsPoolConfigs_, rewardsManagerSalt_
    );

    console2.log("RewardsManager deployed", rewardsManager_);
    console2.log("========");

    return rewardsManager_;
  }
}
