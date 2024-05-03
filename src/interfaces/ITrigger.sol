// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {TriggerState} from "./Enums.sol";

/**
 * @dev The minimal functions a trigger must implement to work with SafetyModules.
 */
interface ITrigger {
  /// @notice The current trigger state.
  function state() external returns (TriggerState);
}
