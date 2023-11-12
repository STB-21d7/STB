// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Orchestrated is Ownable {
    event GrantedAccess(address access, bytes4 sig);
    event CancelAccess(address access, bytes4 sig);

    //admin address
    address public adminAddress;

    mapping(address => mapping(bytes4 => bool)) public orchestration;

    constructor() Ownable() {}

    modifier onlyAdmin() {
        require(msg.sender == adminAddress || msg.sender == owner());
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin() {
        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }

    /// @dev Restrict usage to authorized users;
    modifier onlyOrchestrated(string memory err) {
        require(orchestration[msg.sender][msg.sig], err);
        _;
    }

    /// @dev add orchestration
    function orchestrate(address user, bytes4 sig) public onlyOwner {
        orchestration[user][sig] = true;
        emit GrantedAccess(user, sig);
    }

    /// @dev remove orchestration
    function removeOrchestrate(address user, bytes4 sig) public onlyOwner {
        orchestration[user][sig] = false;
        emit CancelAccess(user, sig);
    }


}
