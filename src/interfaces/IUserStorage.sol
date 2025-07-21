// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUserStorage
 * @dev Interface for cross-contract verification with UserStorage
 */
interface IUserStorage {
    function isUserRegistered(address userAddress) external view returns (bool);
    function isUserVerified(address userAddress) external view returns (bool);
    function getUserType(address userAddress) external view returns (uint8);
}
