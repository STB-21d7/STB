// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Pausable is Ownable {
    //bytes4 internal constant MY_METHOD_SELECTOR = bytes4(keccak256("myMethod()"));
    mapping(bytes4 => bool) public pausedMethods;

    function setMethodsStatus(bytes4[] memory methods, bool paused) public onlyOwner {
        for(uint i=0; i<methods.length; i++) {
            pausedMethods[methods[i]] = paused;
        }
    }

    modifier whenNotPaused(bytes4 method) {
        require(!pausedMethods[method], "Paused.");
        _;
    }

    function pause(bytes4 method) public onlyOwner {
        pausedMethods[method] = true;
    }

    function unpause(bytes4 method) public onlyOwner {
        pausedMethods[method] = false;
    }
}
