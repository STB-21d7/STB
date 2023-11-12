// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./base/OrchestratedUpgradeable.sol";

contract UsdtBalanceManage is OrchestratedUpgradeable, PausableUpgradeable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;


    function initialize(
    ) initializer public {
        __Pausable_init();
        __Ownable_init_unchained();
        __Orchestrated_init_unchained();

    }

    fallback() external payable {}
    receive() external payable {}


}
