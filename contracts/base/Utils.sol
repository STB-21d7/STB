// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Utils {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}