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
 * forge script script/DeployUnionRewardsManager.s.sol \
 *   --sig "run(string)" "deploy-union-rewards-manager"
 *   --rpc-url "http://127.0.0.1:8545" \
 *   -vvvv \
 *   --sender 0xBBD3321f377742c4b3fe458b270c2F271d3294D8 \
 *   --unlocked
 *
 * # Or, to broadcast transactions.
 * forge script script/DeployUnionRewardsManager.s.sol \
 *   --sig "run(string)" "deploy-union-rewards-manager"
 *   --rpc-url "http://127.0.0.1:8545" \
 *   --broadcast \
 *   -vvvv \
 *   --sender 0xBBD3321f377742c4b3fe458b270c2F271d3294D8 \
 *   --unlocked
 * ```
 */
contract DeployUnionRewardsManager is ScriptUtils {
  using stdJson for string;

  address caller_ = address(0xBBD3321f377742c4b3fe458b270c2F271d3294D8);
  ICozyRouter router = ICozyRouter(payable(address(0xedC9dE3FCE03FB0AB2387486A89545dE0E38e2c6)));
  IDripModelConstantFactory dripModelConstantFactory =
    IDripModelConstantFactory(address(0x372eA1BF5728EDef068034cf4531F8E6049a3d3a));
  IRewardsManagerCozyManager rewardsManagerCozyManager =
    IRewardsManagerCozyManager(address(0xEECba9b8f76123CdB733C9973032e96f3041640c)); // New rewards manager
  address depositReceiptToken = address(0xae28465D11239DEF4B418085A82e24F661204871); // Deposit receit token for already deployed SM

  function run(string memory fileName_) public virtual {
    string memory json_ = readInput(fileName_);

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

    address deployedRewardsManager_ = deployRewardsManager(json_, depositReceiptToken, dripModel_);
    assert(
      deployedRewardsManager_
        == rewardsManagerCozyManager.computeRewardsManagerAddress(
          address(router), router.computeSalt(caller_, json_.readBytes32(".rewardsManagerSalt"))
        )
    );
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
