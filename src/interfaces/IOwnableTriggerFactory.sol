// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {ITrigger} from "./ITrigger.sol";
import {ICozyRouter} from "./ICozyRouter.sol";

interface IOwnableTriggerFactory {
  function deployTrigger(address _owner, ICozyRouter.TriggerMetadata memory _metadata, bytes32 _salt)
    external
    returns (ITrigger _trigger);

  function computeTriggerAddress(address _owner, bytes32 _salt) external view returns (address _address);
}
