// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./base/OrchestratedUpgradeable.sol";


interface ISFBToken is IERC20{
    function contractMint(address account, uint amount) external;
    function contractBurn(address account, uint256 amount) external;
}

contract SfbManage is OrchestratedUpgradeable, PausableUpgradeable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    ISFBToken public sfbToken;
    IERC20 public usdtToken;

    function initialize(
        address _sfbToken,
        address _usdtToken
    ) initializer public {
        __Pausable_init();
        __Ownable_init_unchained();
        __Orchestrated_init_unchained();

        sfbToken = ISFBToken(_sfbToken);
        usdtToken = IERC20(_usdtToken);
    }

    function setAllAuth(address account) public onlyAdmin {
        orchestrate(account, 0xcf891518);
        orchestrate(account, 0x0cbf9266);
    }

    //0xcf891518
    function mintSfb(uint usdtAmount) public onlyOrchestrated("onlyOrchestrated: mintSfb"){
        sfbToken.contractMint(address(this), usdtAmount);
    }

    //0x0cbf9266
    function burnSfb(uint sfbAmount) public onlyOrchestrated("onlyOrchestrated: burnSfb"){
        sfbToken.contractBurn(address(this), sfbAmount);
        usdtToken.transfer(_msgSender(), sfbAmount);
    }


    fallback() external payable {}
    receive() external payable {}


}
