// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

enum SafetyModuleState {
  ACTIVE,
  TRIGGERED,
  PAUSED
}

enum RewardsManagerState {
  ACTIVE,
  PAUSED
}

enum TriggerState {
  ACTIVE,
  TRIGGERED,
  FROZEN
}
