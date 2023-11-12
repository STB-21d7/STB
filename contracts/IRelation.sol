// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRelation {

    struct UserInfo{
        uint lowerCount;
        address leader;
        bool isUsed;
    }

    function getUsers(address account) external view returns(UserInfo memory);
}
