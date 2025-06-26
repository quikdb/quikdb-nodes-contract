// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title UserStorage
 * @dev Storage contract for user-related data
 * @notice This contract is immutable and stores all user data permanently
 */
contract UserStorage is AccessControl {
    bytes32 public constant LOGIC_ROLE = keccak256("LOGIC_ROLE");

    // User types
    enum UserType {
        CONSUMER, // Regular users who consume services
        PROVIDER, // Node operators who provide services
        MARKETPLACE_ADMIN, // Marketplace administrators
        PLATFORM_ADMIN // Platform administrators
    }

    // User profile structure
    struct UserProfile {
        bytes32 profileHash; // Hash of encrypted profile data
        UserType userType; // Type of user
        bool isActive; // Whether user is active
        uint256 createdAt; // Registration timestamp
        uint256 updatedAt; // Last update timestamp
        uint256 totalSpent; // Total amount spent (for consumers)
        uint256 totalEarned; // Total amount earned (for providers)
        uint256 reputationScore; // Reputation score (0-10000)
        bool isVerified; // Whether user is verified
    }

    // User preferences structure
    struct UserPreferences {
        string preferredRegion; // Preferred geographic region
        uint256 maxHourlyRate; // Maximum acceptable hourly rate
        bool autoRenewal; // Auto-renewal for services
        string[] preferredProviders; // List of preferred provider types
        uint256 notificationLevel; // Notification level preference
    }

    // User statistics structure
    struct UserStats {
        uint256 totalTransactions; // Total number of transactions
        uint256 avgRating; // Average rating (0-10000)
        uint256 completedJobs; // Number of completed jobs
        uint256 cancelledJobs; // Number of cancelled jobs
        uint256 lastActivity; // Last activity timestamp
    }

    // Complete user information
    struct UserInfo {
        UserProfile profile;
        UserPreferences preferences;
        UserStats stats;
        bool exists;
    }

    // Storage mappings
    mapping(address => UserInfo) private users;
    mapping(UserType => address[]) private usersByType;
    mapping(address => bool) private registeredUsers;
    mapping(address => bool) private verifiedUsers;

    // Statistics
    uint256 private totalUsers;
    uint256 private activeUsers;
    uint256 private verifiedUsersCount;

    // Events
    event UserDataUpdated(address indexed userAddress, string dataType);

    modifier onlyLogic() {
        require(hasRole(LOGIC_ROLE, msg.sender), "Only logic contract");
        _;
    }

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Set the logic contract address
     * @param logicContract Address of the logic contract
     */
    function setLogicContract(
        address logicContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(LOGIC_ROLE, logicContract);
    }

    /**
     * @dev Register a new user
     * @param userAddress Address of the user
     * @param profileHash Hash of encrypted profile data
     * @param userType Type of user
     */
    function registerUser(
        address userAddress,
        bytes32 profileHash,
        UserType userType
    ) external onlyLogic {
        require(userAddress != address(0), "Invalid user address");
        require(!registeredUsers[userAddress], "User already registered");

        UserInfo storage user = users[userAddress];
        user.profile.profileHash = profileHash;
        user.profile.userType = userType;
        user.profile.isActive = true;
        user.profile.createdAt = block.timestamp;
        user.profile.updatedAt = block.timestamp;
        user.profile.reputationScore = 5000; // Start with neutral reputation (50%)
        user.stats.lastActivity = block.timestamp;
        user.exists = true;

        // Update mappings
        registeredUsers[userAddress] = true;
        usersByType[userType].push(userAddress);

        totalUsers++;
        activeUsers++;

        emit UserDataUpdated(userAddress, "registered");
    }

    /**
     * @dev Update user profile
     * @param userAddress Address of the user
     * @param profileHash New profile hash
     */
    function updateUserProfile(
        address userAddress,
        bytes32 profileHash
    ) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");

        users[userAddress].profile.profileHash = profileHash;
        users[userAddress].profile.updatedAt = block.timestamp;
        users[userAddress].stats.lastActivity = block.timestamp;

        emit UserDataUpdated(userAddress, "profile");
    }

    /**
     * @dev Update user preferences
     * @param userAddress Address of the user
     * @param preferences New preferences
     */
    function updateUserPreferences(
        address userAddress,
        UserPreferences calldata preferences
    ) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");

        users[userAddress].preferences = preferences;
        users[userAddress].profile.updatedAt = block.timestamp;
        users[userAddress].stats.lastActivity = block.timestamp;

        emit UserDataUpdated(userAddress, "preferences");
    }

    /**
     * @dev Update user status
     * @param userAddress Address of the user
     * @param isActive New active status
     */
    function updateUserStatus(
        address userAddress,
        bool isActive
    ) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");

        bool wasActive = users[userAddress].profile.isActive;
        users[userAddress].profile.isActive = isActive;
        users[userAddress].profile.updatedAt = block.timestamp;
        users[userAddress].stats.lastActivity = block.timestamp;

        // Update active users count
        if (isActive && !wasActive) {
            activeUsers++;
        } else if (!isActive && wasActive) {
            activeUsers--;
        }

        emit UserDataUpdated(userAddress, "status");
    }

    /**
     * @dev Verify user
     * @param userAddress Address of the user
     */
    function verifyUser(address userAddress) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");

        if (!users[userAddress].profile.isVerified) {
            users[userAddress].profile.isVerified = true;
            users[userAddress].profile.updatedAt = block.timestamp;
            verifiedUsers[userAddress] = true;
            verifiedUsersCount++;

            emit UserDataUpdated(userAddress, "verified");
        }
    }

    /**
     * @dev Update user reputation
     * @param userAddress Address of the user
     * @param newScore New reputation score (0-10000)
     */
    function updateUserReputation(
        address userAddress,
        uint256 newScore
    ) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");
        require(newScore <= 10000, "Invalid reputation score");

        users[userAddress].profile.reputationScore = newScore;
        users[userAddress].profile.updatedAt = block.timestamp;

        emit UserDataUpdated(userAddress, "reputation");
    }

    /**
     * @dev Update user financial data
     * @param userAddress Address of the user
     * @param amountSpent Amount spent (for consumers)
     * @param amountEarned Amount earned (for providers)
     */
    function updateUserFinancials(
        address userAddress,
        uint256 amountSpent,
        uint256 amountEarned
    ) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");

        users[userAddress].profile.totalSpent += amountSpent;
        users[userAddress].profile.totalEarned += amountEarned;
        users[userAddress].profile.updatedAt = block.timestamp;
        users[userAddress].stats.lastActivity = block.timestamp;

        if (amountSpent > 0 || amountEarned > 0) {
            users[userAddress].stats.totalTransactions++;
        }

        emit UserDataUpdated(userAddress, "financials");
    }

    /**
     * @dev Update user statistics
     * @param userAddress Address of the user
     * @param completedJobs Number of completed jobs to add
     * @param cancelledJobs Number of cancelled jobs to add
     * @param rating New rating to factor in (0-10000)
     */
    function updateUserStats(
        address userAddress,
        uint256 completedJobs,
        uint256 cancelledJobs,
        uint256 rating
    ) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");
        require(rating <= 10000, "Invalid rating");

        UserStats storage stats = users[userAddress].stats;
        stats.completedJobs += completedJobs;
        stats.cancelledJobs += cancelledJobs;
        stats.lastActivity = block.timestamp;

        // Update average rating using weighted average
        if (rating > 0) {
            uint256 totalRatings = stats.completedJobs > 0
                ? stats.completedJobs
                : 1;
            stats.avgRating =
                ((stats.avgRating * (totalRatings - 1)) + rating) /
                totalRatings;
        }

        users[userAddress].profile.updatedAt = block.timestamp;

        emit UserDataUpdated(userAddress, "stats");
    }

    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get complete user information
     * @param userAddress Address of the user
     * @return User information struct
     */
    function getUserInfo(
        address userAddress
    ) external view returns (UserInfo memory) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress];
    }

    /**
     * @dev Get user profile
     * @param userAddress Address of the user
     * @return User profile struct
     */
    function getUserProfile(
        address userAddress
    ) external view returns (UserProfile memory) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress].profile;
    }

    /**
     * @dev Get user preferences
     * @param userAddress Address of the user
     * @return User preferences struct
     */
    function getUserPreferences(
        address userAddress
    ) external view returns (UserPreferences memory) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress].preferences;
    }

    /**
     * @dev Get user statistics
     * @param userAddress Address of the user
     * @return User statistics struct
     */
    function getUserStats(
        address userAddress
    ) external view returns (UserStats memory) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress].stats;
    }

    /**
     * @dev Get users by type
     * @param userType Type of user
     * @return Array of user addresses
     */
    function getUsersByType(
        UserType userType
    ) external view returns (address[] memory) {
        return usersByType[userType];
    }

    /**
     * @dev Check if user is registered
     * @param userAddress Address to check
     * @return Whether the user is registered
     */
    function isUserRegistered(
        address userAddress
    ) external view returns (bool) {
        return registeredUsers[userAddress];
    }

    /**
     * @dev Check if user is verified
     * @param userAddress Address to check
     * @return Whether the user is verified
     */
    function isUserVerified(address userAddress) external view returns (bool) {
        return verifiedUsers[userAddress];
    }

    /**
     * @dev Check if user is active
     * @param userAddress Address to check
     * @return Whether the user is active
     */
    function isUserActive(address userAddress) external view returns (bool) {
        if (!registeredUsers[userAddress]) return false;
        return users[userAddress].profile.isActive;
    }

    /**
     * @dev Get user type
     * @param userAddress Address of the user
     * @return User type
     */
    function getUserType(address userAddress) external view returns (UserType) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress].profile.userType;
    }

    /**
     * @dev Get user reputation score
     * @param userAddress Address of the user
     * @return Reputation score (0-10000)
     */
    function getUserReputation(
        address userAddress
    ) external view returns (uint256) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress].profile.reputationScore;
    }

    /**
     * @dev Get total statistics
     * @return total Total number of users
     * @return active Number of active users
     * @return verified Number of verified users
     */
    function getStats()
        external
        view
        returns (uint256 total, uint256 active, uint256 verified)
    {
        return (totalUsers, activeUsers, verifiedUsersCount);
    }

    /**
     * @dev Get total users count
     * @return Total number of users
     */
    function getTotalUsers() external view returns (uint256) {
        return totalUsers;
    }

    // =============================================================================
    // ADMIN FUNCTIONS
    // =============================================================================

    /**
     * @dev Force update user status (admin only)
     * @param userAddress Address of the user
     * @param isActive New active status
     */
    function adminUpdateUserStatus(
        address userAddress,
        bool isActive
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(registeredUsers[userAddress], "User not registered");

        bool wasActive = users[userAddress].profile.isActive;
        users[userAddress].profile.isActive = isActive;
        users[userAddress].profile.updatedAt = block.timestamp;

        // Update active users count
        if (isActive && !wasActive) {
            activeUsers++;
        } else if (!isActive && wasActive) {
            activeUsers--;
        }

        emit UserDataUpdated(userAddress, "admin_status");
    }

    /**
     * @dev Revoke user verification (admin only)
     * @param userAddress Address of the user
     */
    function revokeUserVerification(
        address userAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(registeredUsers[userAddress], "User not registered");

        if (users[userAddress].profile.isVerified) {
            users[userAddress].profile.isVerified = false;
            users[userAddress].profile.updatedAt = block.timestamp;
            verifiedUsers[userAddress] = false;
            verifiedUsersCount--;

            emit UserDataUpdated(userAddress, "unverified");
        }
    }
}
