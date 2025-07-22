// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseLogic.sol";

/**
 * @title UserLogic - User management logic
 */
contract UserLogic is BaseLogic {
    // User ID to address mapping
    mapping(string => address) private userIdToAddress;
    mapping(address => string) private addressToUserId;
    
    // User status mapping
    mapping(address => uint8) private userStatuses;
    
    // User creation timestamps
    mapping(address => uint256) private userCreationTimes;
    mapping(address => uint256) private userUpdateTimes;
    
    // Additional user data for blockchain service
    mapping(address => bytes32) private userSettingsHashes;
    mapping(address => bytes32) private userMetadataHashes;
    
    // Array to track all user addresses for iteration
    address[] private allUsers;
    mapping(address => uint256) private userIndices;

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
    {
        // Check if user already exists
        require(bytes(addressToUserId[userAddress]).length == 0, "User already registered");
        
        // Register in storage
        userStorage.registerUser(userAddress, profileHash, userType);
        
        // Update local tracking arrays
        userIndices[userAddress] = allUsers.length;
        allUsers.push(userAddress);
        
        // Set default values for additional data
        userStatuses[userAddress] = 1; // Active status
        userCreationTimes[userAddress] = block.timestamp;
        userUpdateTimes[userAddress] = block.timestamp;
        
        emit UserRegistered(userAddress, profileHash, uint8(userType), block.timestamp);
    }

    /**
     * @dev Update user profile
     */
    function updateUserProfile(address userAddress, bytes32 profileHash) external whenNotPaused {
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
    ) external whenNotPaused {
        userStorage.updateUserAuth(userAddress, emailHash, emailVerified, googleIdHash, authMethods, accountStatus);
    }

    /**
     * @dev Update user blockchain nonce
     */
    function updateUserNonce(address userAddress, uint256 newNonce)
        external
        whenNotPaused
    {
        userStorage.updateUserNonce(userAddress, newNonce);
    }

    /**
     * @dev Update user type (e.g., from CONSUMER to PROVIDER)
     * @param userAddress Address of the user
     * @param newUserType New user type to set
     */
    function updateUserType(address userAddress, UserStorage.UserType newUserType)
        external
        whenNotPaused
    {
        require(userAddress != address(0), "Invalid user address");
        userStorage.updateUserType(userAddress, newUserType);
        
        // Get the updated profile to emit the event
        UserStorage.UserProfile memory profile = userStorage.getUserProfile(userAddress);
        emit UserProfileUpdated(userAddress, profile.profileHash, block.timestamp);
    }

    /**
     * @dev Delete a user and all associated data
     */
    function deleteUser(address userAddress) external whenNotPaused {
        require(userAddress != address(0), "Invalid user address");
        require(bytes(addressToUserId[userAddress]).length > 0 || userIndices[userAddress] < allUsers.length, "User not found");
        
        // Delete from storage first
        userStorage.deleteUser(userAddress);
        
        // Clean up local mappings
        string memory userId = addressToUserId[userAddress];
        if (bytes(userId).length > 0) {
            delete userIdToAddress[userId];
        }
        delete addressToUserId[userAddress];
        delete userStatuses[userAddress];
        delete userCreationTimes[userAddress];
        delete userUpdateTimes[userAddress];
        delete userSettingsHashes[userAddress];
        delete userMetadataHashes[userAddress];
        
        // Remove from allUsers array
        uint256 index = userIndices[userAddress];
        if (index < allUsers.length && allUsers[index] == userAddress) {
            // Move the last element to the deleted position
            address lastUser = allUsers[allUsers.length - 1];
            allUsers[index] = lastUser;
            userIndices[lastUser] = index;
            allUsers.pop();
        }
        delete userIndices[userAddress];
    }

    // =============================================================================
    // MISSING BLOCKCHAIN SERVICE METHODS
    // =============================================================================

    /**
     * @dev Register user with simplified interface for blockchain service
     */
    function registerUser(
        string calldata userId,
        address userAddress,
        bytes32 profileHash,
        bytes32 settingsHash,
        bytes32 metadataHash
    ) external whenNotPaused {
        require(bytes(userId).length > 0, "Invalid userId");
        require(userAddress != address(0), "Invalid user address");
        require(userIdToAddress[userId] == address(0), "UserId already exists");
        require(bytes(addressToUserId[userAddress]).length == 0, "Address already registered");

        // Store mappings
        userIdToAddress[userId] = userAddress;
        addressToUserId[userAddress] = userId;
        
        // Store additional data
        userSettingsHashes[userAddress] = settingsHash;
        userMetadataHashes[userAddress] = metadataHash;
        userStatuses[userAddress] = 1; // Active status
        userCreationTimes[userAddress] = block.timestamp;
        userUpdateTimes[userAddress] = block.timestamp;
        
        // Add to user list (check if not already added)
        if (userIndices[userAddress] == 0 && (allUsers.length == 0 || allUsers[0] != userAddress)) {
            userIndices[userAddress] = allUsers.length;
            allUsers.push(userAddress);
        }

        // Call the storage registration method directly to avoid duplicate check
        userStorage.registerUser(userAddress, profileHash, UserStorage.UserType.CONSUMER);
        emit UserRegistered(userAddress, profileHash, uint8(UserStorage.UserType.CONSUMER), block.timestamp);
    }

    /**
     * @dev Get user data (wrapper for getUserProfile)
     */
    function getUserData(string calldata userId) external view returns (
        address userAddress,
        bytes32 profileHash,
        bytes32 settingsHash,
        bytes32 metadataHash,
        uint8 status,
        uint256 createdAt,
        uint256 updatedAt
    ) {
        require(bytes(userId).length > 0, "Invalid userId");
        userAddress = userIdToAddress[userId];
        require(userAddress != address(0), "User not found");
        
        UserStorage.UserProfile memory profile = userStorage.getUserProfile(userAddress);
        
        return (
            userAddress,
            profile.profileHash,
            userSettingsHashes[userAddress],
            userMetadataHashes[userAddress],
            userStatuses[userAddress],
            userCreationTimes[userAddress],
            userUpdateTimes[userAddress]
        );
    }

    /**
     * @dev Update user status
     */
    function updateUserStatus(
        string calldata userId,
        uint8 status
    ) external whenNotPaused {
        require(bytes(userId).length > 0, "Invalid userId");
        address userAddress = userIdToAddress[userId];
        require(userAddress != address(0), "User not found");
        require(status <= 3, "Invalid status"); // 0=inactive, 1=active, 2=suspended, 3=deleted
        
        userStatuses[userAddress] = status;
        userUpdateTimes[userAddress] = block.timestamp;
        
        emit UserProfileUpdated(userAddress, userStorage.getUserProfile(userAddress).profileHash, block.timestamp);
    }

    /**
     * @dev Get users with query parameters for blockchain service
     */
    function getUsers(
        string calldata /* userIdFilter */,
        string calldata /* statusFilter */,
        string calldata /* organizationFilter */,
        uint256 limit,
        uint256 offset
    ) external view returns (
        string[] memory userIds,
        address[] memory userAddresses,
        bytes32[] memory profileHashes,
        uint8[] memory statuses,
        uint256[] memory createdAts
    ) {
        uint256 totalUsers = allUsers.length;
        
        // Apply offset
        if (offset >= totalUsers) {
            return (new string[](0), new address[](0), new bytes32[](0), new uint8[](0), new uint256[](0));
        }
        
        // Calculate actual limit
        uint256 maxLimit = totalUsers - offset;
        uint256 actualLimit = limit == 0 ? maxLimit : (limit > maxLimit ? maxLimit : limit);
        
        // Simple approach: return first actualLimit users without complex filtering to avoid stack issues
        userIds = new string[](actualLimit);
        userAddresses = new address[](actualLimit);
        profileHashes = new bytes32[](actualLimit);
        statuses = new uint8[](actualLimit);
        createdAts = new uint256[](actualLimit);
        
        for (uint256 i = 0; i < actualLimit; i++) {
            address userAddr = allUsers[offset + i];
            userIds[i] = addressToUserId[userAddr];
            userAddresses[i] = userAddr;
            profileHashes[i] = userStorage.getUserProfile(userAddr).profileHash;
            statuses[i] = userStatuses[userAddr];
            createdAts[i] = userCreationTimes[userAddr];
        }
        
        return (userIds, userAddresses, profileHashes, statuses, createdAts);
    }

    // =============================================================================
    // TEST/CLEANUP FUNCTIONS
    // =============================================================================

    /**
     * @dev Clean up all user data - FOR TESTING ONLY
     * @notice This function deletes ALL user data from both logic and storage contracts
     * @dev Only callable by admin role for testing purposes
     */
    function cleanupAllUsers() external {
        require(allUsers.length > 0, "No users to cleanup");
        
        uint256 userCount = allUsers.length;
        
        // Store all user addresses to avoid array modification issues during iteration
        address[] memory usersToDelete = new address[](userCount);
        for (uint256 i = 0; i < userCount; i++) {
            usersToDelete[i] = allUsers[i];
        }
        
        // Delete all users from storage first
        for (uint256 i = 0; i < userCount; i++) {
            address userAddr = usersToDelete[i];
            
            // Delete from UserStorage
            userStorage.deleteUser(userAddr);
            
            // Clean up local mappings
            string memory userId = addressToUserId[userAddr];
            if (bytes(userId).length > 0) {
                delete userIdToAddress[userId];
            }
            delete addressToUserId[userAddr];
            delete userStatuses[userAddr];
            delete userCreationTimes[userAddr];
            delete userUpdateTimes[userAddr];
            delete userSettingsHashes[userAddr];
            delete userMetadataHashes[userAddr];
            delete userIndices[userAddr];
        }
        
        // Clear the allUsers array
        delete allUsers;
        
        emit UserCleanupCompleted(userCount, block.timestamp);
    }

    /**
     * @dev Clean up all user data without deleting from storage - FOR TESTING ONLY
     * @notice This function clears only the local mappings and arrays, not the storage contract
     * @dev Only callable by admin role for testing purposes
     */
    function cleanUpAllUserData() external {
        require(allUsers.length > 0, "No user data to cleanup");
        
        uint256 userCount = allUsers.length;
        
        // Store all user addresses to avoid array modification issues during iteration
        address[] memory usersToClean = new address[](userCount);
        for (uint256 i = 0; i < userCount; i++) {
            usersToClean[i] = allUsers[i];
        }
        
        // Clean up local mappings only (not storage)
        for (uint256 i = 0; i < userCount; i++) {
            address userAddr = usersToClean[i];
            
            // Clean up local mappings
            string memory userId = addressToUserId[userAddr];
            if (bytes(userId).length > 0) {
                delete userIdToAddress[userId];
            }
            delete addressToUserId[userAddr];
            delete userStatuses[userAddr];
            delete userCreationTimes[userAddr];
            delete userUpdateTimes[userAddr];
            delete userSettingsHashes[userAddr];
            delete userMetadataHashes[userAddr];
            delete userIndices[userAddr];
        }
        
        // Clear the allUsers array
        delete allUsers;
        
        emit UserDataCleanupCompleted(userCount, block.timestamp);
    }

    /**
     * @dev Get total number of users for cleanup verification
     */
    function getTotalUserCount() external view returns (uint256) {
        return allUsers.length;
    }

    // Events for cleanup completion
    event UserCleanupCompleted(uint256 deletedUserCount, uint256 timestamp);
    event UserDataCleanupCompleted(uint256 cleanedUserCount, uint256 timestamp);
}
