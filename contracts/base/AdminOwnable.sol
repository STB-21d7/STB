// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AdminOwnable is Ownable {
    //admin address
    address public adminAddress;

    constructor() Ownable() {}

    modifier onlyAdmin() {
        require(msg.sender == adminAddress || msg.sender == owner());
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin() {
        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }
}
