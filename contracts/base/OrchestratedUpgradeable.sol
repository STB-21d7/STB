// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OrchestratedUpgradeable is Initializable, OwnableUpgradeable {
    event GrantedAccess(address access, bytes4 sig);
    event CancelAccess(address access, bytes4 sig);

    //admin address
    address public adminAddress;
    address public configAddress;

    mapping(address => mapping(bytes4 => bool)) public orchestration;

    // function initialize() initializer public {
    //     __Orchestrated_init();
    // }

    function __Orchestrated_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Orchestrated_init_unchained();
    }

    function __Orchestrated_init_unchained() internal onlyInitializing {

    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress || msg.sender == owner() || msg.sender == configAddress);
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
