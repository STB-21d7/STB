// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./base/OrchestratedUpgradeable.sol";


interface ISTBToken is IERC20{
    function split(uint rate) external;
    function splitRate() external view returns(uint);
    function burn(uint amount) external returns(bool);
}


contract SellPoolManage is OrchestratedUpgradeable, PausableUpgradeable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    ISTBToken public stbToken;

    mapping(uint => mapping(uint=>bool)) public sellPoolRelease;

    function initialize(
        address _stbToken
    ) initializer public {
        __Pausable_init();
        __Ownable_init_unchained();
        __Orchestrated_init_unchained();

        stbToken = ISTBToken(_stbToken);
    }

    function stbSplitRate() public view returns(uint) {
        return stbToken.splitRate();
    }
    
    function getSplitAmount(uint amount) public view returns(uint) {
        return amount.mul(stbSplitRate()).div(10000);
    }

    function getRealAmount(uint amount) public view returns(uint) {
        return amount.mul(10000).div(stbSplitRate());
    }

    //0x8070c401
    function manualRelease(uint amount) public onlyOrchestrated("onlyOrchestrated: stbSellPoolRelease") {
        stbToken.transfer(_msgSender(), amount);
    }

    //0x8940f6b1
    function stbSellPoolRelease(uint price) public onlyOrchestrated("onlyOrchestrated: stbSellPoolRelease") returns(uint){
        uint splitRate = stbToken.splitRate();
        uint stbRealBalance = getRealAmount(stbToken.balanceOf(address(this)));
        uint releaseRate = 0;
        if(price >= 11*1e16 && price < 12*1e16 && !sellPoolRelease[splitRate][11*1e16]){
            sellPoolRelease[splitRate][11*1e16] = true;
            releaseRate = 100;
        } else if(price >= 12*1e16 && price < 13*1e16 && !sellPoolRelease[splitRate][12*1e16]){
            sellPoolRelease[splitRate][12*1e16] = true;
            releaseRate = 111;
        } else if(price >= 13*1e16 && price < 14*1e16 && !sellPoolRelease[splitRate][13*1e16]){
            sellPoolRelease[splitRate][13*1e16] = true;
            releaseRate = 124;
        } else if(price >= 14*1e16 && price < 15*1e16 && !sellPoolRelease[splitRate][14*1e16]){
            sellPoolRelease[splitRate][14*1e16] = true;
            releaseRate = 143;
        } else if(price >= 15*1e16 && price < 16*1e16 && !sellPoolRelease[splitRate][15*1e16]){
            sellPoolRelease[splitRate][15*1e16] = true;
            releaseRate = 167;
        } else if(price >= 16*1e16 && price < 17*1e16 && !sellPoolRelease[splitRate][16*1e16]){
            sellPoolRelease[splitRate][16*1e16] = true;
            releaseRate = 200;
        } else if(price >= 17*1e16 && price < 18*1e16 && !sellPoolRelease[splitRate][17*1e16]){
            sellPoolRelease[splitRate][17*1e16] = true;
            releaseRate = 250;
        } else if(price >= 18*1e16 && price < 19*1e16 && !sellPoolRelease[splitRate][18*1e16]){
            sellPoolRelease[splitRate][18*1e16] = true;
            releaseRate = 333;
        } else if(price >= 19*1e16){
            sellPoolRelease[splitRate][19*1e16] = true;
            releaseRate = 1000;
        }
        uint releaseRealAmount = stbRealBalance.mul(releaseRate).div(1000);
        if(releaseRealAmount>0){
            stbToken.transfer(_msgSender(), getSplitAmount(releaseRealAmount));
        }
        return releaseRealAmount;
    }

    fallback() external payable {}
    receive() external payable {}


}
