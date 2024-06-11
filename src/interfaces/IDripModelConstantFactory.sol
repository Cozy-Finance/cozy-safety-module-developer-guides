// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IDripModel} from "./IDripModel.sol";

interface IDripModelConstantFactory {
  /// @notice Deploys a DripModelConstant contract and emits a DeployedDripModelConstant event that
  /// indicates what the params from the deployment are. This address is then cached inside the
  /// isDeployed mapping.
  /// @return model_ which has an address that is deterministic with the input amountPerSecond_.
  function deployModel(address owner_, uint256 amountPerSecond_, bytes32 baseSalt_)
    external
    returns (IDripModel model_);

  /// @notice Given a `caller_`, `owner_`, `amountPerSecond_`, and `baseSalt_`, return the address of the
  /// DripModelConstant deployed from the `DripModelConstantFactory`.
  function computeAddress(address caller_, address owner_, uint256 amountPerSecond_, bytes32 baseSalt_)
    external
    view
    returns (address);
}
