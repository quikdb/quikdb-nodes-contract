// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";

/**
 * @title UserLogic - User management logic
 */
contract UserLogic is BaseLogic {
    // User events
    event UserRegistered(address indexed userAddress, bytes32 profileHash, uint8 userType, uint256 timestamp);
    event UserProfileUpdated(address indexed userAddress, bytes32 profileHash, uint256 timestamp);

    /**
     * @dev Initialize the user logic contract
     */
    function initialize(address _nodeStorage, address _userStorage, address _resourceStorage, address _admin)
        external
    {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, _admin);
    }

    // =============================================================================
    // USER MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Register a new user
     */
    function registerUser(address userAddress, bytes32 profileHash, UserStorage.UserType userType)
        external
        whenNotPaused
        onlyRole(AUTH_SERVICE_ROLE)
    {
        userStorage.registerUser(userAddress, profileHash, userType);
        emit UserRegistered(userAddress, profileHash, uint8(userType), block.timestamp);
    }

    /**
     * @dev Update user profile
     */
    function updateUserProfile(address userAddress, bytes32 profileHash) external whenNotPaused {
        require(msg.sender == userAddress || hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        userStorage.updateUserProfile(userAddress, profileHash);
        emit UserProfileUpdated(userAddress, profileHash, block.timestamp);
    }

    /**
     * @dev Get user profile
     */
    function getUserProfile(address userAddress) external view returns (UserStorage.UserProfile memory) {
        return userStorage.getUserProfile(userAddress);
    }

    /**
     * @dev Get total users count
     */
    function getUserStats() external view returns (uint256 totalUsers) {
        return userStorage.getTotalUsers();
    }

    /**
     * @dev Update user authentication data
     */
    function updateUserAuth(
        address userAddress,
        bytes32 emailHash,
        bool emailVerified,
        bytes32 googleIdHash,
        UserStorage.AuthMethod[] calldata authMethods,
        UserStorage.AccountStatus accountStatus
    ) external whenNotPaused onlyRole(AUTH_SERVICE_ROLE) {
        userStorage.updateUserAuth(userAddress, emailHash, emailVerified, googleIdHash, authMethods, accountStatus);
    }

    /**
     * @dev Update user blockchain nonce
     */
    function updateUserNonce(address userAddress, uint256 newNonce)
        external
        whenNotPaused
        onlyRole(AUTH_SERVICE_ROLE)
    {
        userStorage.updateUserNonce(userAddress, newNonce);
    }

    /**
     * @dev Delete a user and all associated data
     */
    function deleteUser(address userAddress) external whenNotPaused onlyRole(AUTH_SERVICE_ROLE) {
        userStorage.deleteUser(userAddress);
    }
}
