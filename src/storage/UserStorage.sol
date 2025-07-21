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

    // Authentication method enum
    enum AuthMethod {
        WALLET,
        EMAIL,
        GOOGLE_OAUTH
    }

    // Account status enum
    enum AccountStatus {
        ACTIVE,
        PENDING_VERIFICATION,
        EMAIL_PENDING,
        EMAIL_VERIFIED,
        SUSPENDED,
        DELETED
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
        // Authentication-related fields
        bytes32 emailHash; // Encrypted email address
        bool emailVerified; // Whether email is verified
        bytes32 googleIdHash; // Encrypted Google ID
        uint256 blockchainNonce; // Current nonce for wallet signatures
        AuthMethod[] authMethods; // Supported authentication methods
        AccountStatus accountStatus; // Enhanced account status
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

    // Email-to-wallet reverse lookup mappings
    mapping(bytes32 => address) private emailHashToWallet;           // email hash to wallet address
    mapping(address => bytes32[]) private walletToEmailHashes;       // wallet to associated email hashes
    mapping(bytes32 => bool) private usedEmailHashes;               // prevent email reuse across wallets
    mapping(address => uint256) private emailLookupCount;           // rate limiting for email lookups
    mapping(address => uint256) private lastEmailLookupTime;        // timestamp of last email lookup

    // Email verification tracking
    mapping(bytes32 => bool) private emailVerificationStatus;       // email hash verification status
    mapping(address => uint256) private emailChangeCount;           // track email changes per wallet
    mapping(bytes32 => uint256) private emailCreationTime;          // when email hash was first registered

    // Security parameters for email lookups
    uint256 private constant MAX_EMAIL_LOOKUPS_PER_HOUR = 10;      // Rate limit for email lookups
    uint256 private constant EMAIL_LOOKUP_WINDOW = 1 hours;        // Time window for rate limiting
    uint256 private constant MAX_EMAILS_PER_WALLET = 3;            // Maximum emails per wallet
    uint256 private constant MAX_EMAIL_CHANGES_PER_DAY = 2;        // Maximum email changes per day

    // Statistics
    uint256 private totalUsers;
    uint256 private activeUsers;
    uint256 private verifiedUsersCount;
    uint256 private totalEmailMappings;                             // Total email-to-wallet mappings

    // Events
    event UserDataUpdated(address indexed userAddress, string dataType);
    
    // Email authentication events
    event EmailWalletMappingCreated(bytes32 indexed emailHash, address indexed walletAddress, uint256 timestamp);
    event EmailWalletMappingUpdated(bytes32 indexed oldEmailHash, bytes32 indexed newEmailHash, address indexed walletAddress, uint256 timestamp);
    event EmailWalletMappingRemoved(bytes32 indexed emailHash, address indexed walletAddress, string reason, uint256 timestamp);
    event EmailVerificationStatusChanged(bytes32 indexed emailHash, address indexed walletAddress, bool verified, uint256 timestamp);
    event EmailLookupPerformed(bytes32 indexed emailHash, address indexed requester, bool found, uint256 timestamp);
    event EmailRateLimitExceeded(address indexed requester, uint256 attemptCount, uint256 timestamp);

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
    function setLogicContract(address logicContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(LOGIC_ROLE, logicContract);
    }

    /**
     * @dev Register a new user
     * @param userAddress Address of the user
     * @param profileHash Hash of encrypted profile data
     * @param userType Type of user
     */
    function registerUser(address userAddress, bytes32 profileHash, UserType userType) external onlyLogic {
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
     * @dev Register a new user with email hash
     * @param userAddress Address of the user
     * @param profileHash Hash of encrypted profile data
     * @param userType Type of user
     * @param emailHash Hash of the user's email address
     */
    function registerUserWithEmail(
        address userAddress, 
        bytes32 profileHash, 
        UserType userType, 
        bytes32 emailHash
    ) external onlyLogic {
        require(userAddress != address(0), "Invalid user address");
        require(!registeredUsers[userAddress], "User already registered");
        require(emailHash != bytes32(0), "Invalid email hash");
        require(!usedEmailHashes[emailHash], "Email already associated with another wallet");

        UserInfo storage user = users[userAddress];
        user.profile.profileHash = profileHash;
        user.profile.userType = userType;
        user.profile.isActive = true;
        user.profile.createdAt = block.timestamp;
        user.profile.updatedAt = block.timestamp;
        user.profile.reputationScore = 5000; // Start with neutral reputation (50%)
        user.profile.emailHash = emailHash;
        user.profile.emailVerified = false;
        user.stats.lastActivity = block.timestamp;
        user.exists = true;

        // Update mappings
        registeredUsers[userAddress] = true;
        usersByType[userType].push(userAddress);

        // Update email mappings
        emailHashToWallet[emailHash] = userAddress;
        walletToEmailHashes[userAddress].push(emailHash);
        usedEmailHashes[emailHash] = true;
        emailCreationTime[emailHash] = block.timestamp;

        totalUsers++;
        activeUsers++;
        totalEmailMappings++;

        emit UserDataUpdated(userAddress, "registered");
        emit EmailWalletMappingCreated(emailHash, userAddress, block.timestamp);
    }

    /**
     * @dev Update user profile
     * @param userAddress Address of the user
     * @param profileHash New profile hash
     */
    function updateUserProfile(address userAddress, bytes32 profileHash) external onlyLogic {
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
    function updateUserPreferences(address userAddress, UserPreferences calldata preferences) external onlyLogic {
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
    function updateUserStatus(address userAddress, bool isActive) external onlyLogic {
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
    function updateUserReputation(address userAddress, uint256 newScore) external onlyLogic {
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
    function updateUserFinancials(address userAddress, uint256 amountSpent, uint256 amountEarned) external onlyLogic {
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
    function updateUserStats(address userAddress, uint256 completedJobs, uint256 cancelledJobs, uint256 rating)
        external
        onlyLogic
    {
        require(registeredUsers[userAddress], "User not registered");
        require(rating <= 10000, "Invalid rating");

        UserStats storage stats = users[userAddress].stats;
        stats.completedJobs += completedJobs;
        stats.cancelledJobs += cancelledJobs;
        stats.lastActivity = block.timestamp;

        // Update average rating using weighted average
        if (rating > 0) {
            uint256 totalRatings = stats.completedJobs > 0 ? stats.completedJobs : 1;
            stats.avgRating = ((stats.avgRating * (totalRatings - 1)) + rating) / totalRatings;
        }

        users[userAddress].profile.updatedAt = block.timestamp;

        emit UserDataUpdated(userAddress, "stats");
    }

    /**
     * @dev Update user authentication data
     * @param userAddress Address of the user
     * @param emailHash Encrypted email hash
     * @param emailVerified Whether email is verified
     * @param googleIdHash Encrypted Google ID hash
     * @param authMethods Array of supported auth methods
     * @param accountStatus New account status
     */
    function updateUserAuth(
        address userAddress,
        bytes32 emailHash,
        bool emailVerified,
        bytes32 googleIdHash,
        AuthMethod[] calldata authMethods,
        AccountStatus accountStatus
    ) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");

        UserProfile storage profile = users[userAddress].profile;
        bytes32 oldEmailHash = profile.emailHash;

        // Handle email hash updates with mapping consistency
        if (emailHash != bytes32(0) && emailHash != oldEmailHash) {
            require(!usedEmailHashes[emailHash], "Email already associated with another wallet");
            require(
                walletToEmailHashes[userAddress].length < MAX_EMAILS_PER_WALLET,
                "Maximum emails per wallet reached"
            );

            // Check email change rate limiting
            if (oldEmailHash != bytes32(0)) {
                require(
                    emailChangeCount[userAddress] < MAX_EMAIL_CHANGES_PER_DAY,
                    "Email change rate limit exceeded"
                );
                emailChangeCount[userAddress]++;
            }

            // Remove old email mapping if exists
            if (oldEmailHash != bytes32(0)) {
                delete emailHashToWallet[oldEmailHash];
                delete usedEmailHashes[oldEmailHash];
                delete emailVerificationStatus[oldEmailHash];
                _removeEmailFromWalletArray(userAddress, oldEmailHash);
                totalEmailMappings--;
            }

            // Add new email mapping
            emailHashToWallet[emailHash] = userAddress;
            walletToEmailHashes[userAddress].push(emailHash);
            usedEmailHashes[emailHash] = true;
            emailCreationTime[emailHash] = block.timestamp;
            profile.emailHash = emailHash;
            totalEmailMappings++;

            emit EmailWalletMappingUpdated(oldEmailHash, emailHash, userAddress, block.timestamp);
        }

        // Update email verification status
        if (profile.emailHash != bytes32(0)) {
            bool oldVerificationStatus = emailVerificationStatus[profile.emailHash];
            if (emailVerified != oldVerificationStatus) {
                emailVerificationStatus[profile.emailHash] = emailVerified;
                emit EmailVerificationStatusChanged(profile.emailHash, userAddress, emailVerified, block.timestamp);
            }
        }

        profile.emailVerified = emailVerified;

        if (googleIdHash != bytes32(0)) {
            profile.googleIdHash = googleIdHash;
        }

        profile.authMethods = authMethods;
        profile.accountStatus = accountStatus;
        profile.updatedAt = block.timestamp;

        users[userAddress].stats.lastActivity = block.timestamp;

        emit UserDataUpdated(userAddress, "auth");
    }

    /**
     * @dev Update user blockchain nonce
     * @param userAddress Address of the user
     * @param newNonce New nonce value
     */
    function updateUserNonce(address userAddress, uint256 newNonce) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");

        users[userAddress].profile.blockchainNonce = newNonce;
        users[userAddress].profile.updatedAt = block.timestamp;

        emit UserDataUpdated(userAddress, "nonce");
    }

    /**
     * @dev Delete user and all associated data (logic contract only)
     * @param userAddress Address of the user to delete
     */
    function deleteUser(address userAddress) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");

        UserInfo storage user = users[userAddress];

        // Update statistics before deletion
        if (user.profile.isActive) {
            activeUsers--;
        }
        if (user.profile.isVerified) {
            verifiedUsersCount--;
        }
        totalUsers--;

        // Remove from usersByType mapping
        UserType userType = user.profile.userType;
        address[] storage typeArray = usersByType[userType];
        for (uint256 i = 0; i < typeArray.length; i++) {
            if (typeArray[i] == userAddress) {
                // Replace with last element and remove last
                typeArray[i] = typeArray[typeArray.length - 1];
                typeArray.pop();
                break;
            }
        }

        // Delete all user data
        delete users[userAddress];
        delete registeredUsers[userAddress];
        delete verifiedUsers[userAddress];

        emit UserDataUpdated(userAddress, "deleted");
    }

    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get complete user information
     * @param userAddress Address of the user
     * @return User information struct
     */
    function getUserInfo(address userAddress) external view returns (UserInfo memory) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress];
    }

    /**
     * @dev Get user profile
     * @param userAddress Address of the user
     * @return User profile struct
     */
    function getUserProfile(address userAddress) external view returns (UserProfile memory) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress].profile;
    }

    /**
     * @dev Get user preferences
     * @param userAddress Address of the user
     * @return User preferences struct
     */
    function getUserPreferences(address userAddress) external view returns (UserPreferences memory) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress].preferences;
    }

    /**
     * @dev Get user statistics
     * @param userAddress Address of the user
     * @return User statistics struct
     */
    function getUserStats(address userAddress) external view returns (UserStats memory) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress].stats;
    }

    /**
     * @dev Get users by type
     * @param userType Type of user
     * @return Array of user addresses
     */
    function getUsersByType(UserType userType) external view returns (address[] memory) {
        return usersByType[userType];
    }

    /**
     * @dev Check if user is registered
     * @param userAddress Address to check
     * @return Whether the user is registered
     */
    function isUserRegistered(address userAddress) external view returns (bool) {
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
    function getUserReputation(address userAddress) external view returns (uint256) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress].profile.reputationScore;
    }

    /**
     * @dev Get total statistics
     * @return total Total number of users
     * @return active Number of active users
     * @return verified Number of verified users
     */
    function getStats() external view returns (uint256 total, uint256 active, uint256 verified) {
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
    function adminUpdateUserStatus(address userAddress, bool isActive) external onlyRole(DEFAULT_ADMIN_ROLE) {
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
    function revokeUserVerification(address userAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(registeredUsers[userAddress], "User not registered");

        if (users[userAddress].profile.isVerified) {
            users[userAddress].profile.isVerified = false;
            users[userAddress].profile.updatedAt = block.timestamp;
            verifiedUsers[userAddress] = false;
            verifiedUsersCount--;

            emit UserDataUpdated(userAddress, "unverified");
        }
    }

    // ============ EMAIL-TO-WALLET AUTHENTICATION FUNCTIONS ============

    /**
     * @dev Get wallet address by email hash (with rate limiting)
     * @param emailHash The email hash to look up
     * @return walletAddress The associated wallet address (address(0) if not found)
     */
    function getWalletByEmailHash(bytes32 emailHash) external onlyLogic returns (address walletAddress) {
        require(emailHash != bytes32(0), "Invalid email hash");

        // Apply rate limiting
        address requester = tx.origin; // Get the original transaction sender
        _checkEmailLookupRateLimit(requester);

        walletAddress = emailHashToWallet[emailHash];
        bool found = walletAddress != address(0);

        // Update rate limiting counters
        emailLookupCount[requester]++;
        lastEmailLookupTime[requester] = block.timestamp;

        emit EmailLookupPerformed(emailHash, requester, found, block.timestamp);

        return walletAddress;
    }

    /**
     * @dev Update email wallet mapping (for email changes)
     * @param userAddress The wallet address
     * @param newEmailHash The new email hash
     */
    function updateEmailWalletMapping(address userAddress, bytes32 newEmailHash) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");
        require(newEmailHash != bytes32(0), "Invalid email hash");
        require(!usedEmailHashes[newEmailHash], "Email already associated with another wallet");
        require(
            walletToEmailHashes[userAddress].length < MAX_EMAILS_PER_WALLET,
            "Maximum emails per wallet reached"
        );

        UserProfile storage profile = users[userAddress].profile;
        bytes32 oldEmailHash = profile.emailHash;

        // Check email change rate limiting
        require(
            emailChangeCount[userAddress] < MAX_EMAIL_CHANGES_PER_DAY,
            "Email change rate limit exceeded"
        );

        // Remove old email mapping if exists
        if (oldEmailHash != bytes32(0)) {
            delete emailHashToWallet[oldEmailHash];
            delete usedEmailHashes[oldEmailHash];
            delete emailVerificationStatus[oldEmailHash];
            _removeEmailFromWalletArray(userAddress, oldEmailHash);
            totalEmailMappings--;
        }

        // Add new email mapping
        emailHashToWallet[newEmailHash] = userAddress;
        walletToEmailHashes[userAddress].push(newEmailHash);
        usedEmailHashes[newEmailHash] = true;
        emailCreationTime[newEmailHash] = block.timestamp;
        profile.emailHash = newEmailHash;
        profile.emailVerified = false; // Reset verification status
        totalEmailMappings++;
        emailChangeCount[userAddress]++;

        emit EmailWalletMappingUpdated(oldEmailHash, newEmailHash, userAddress, block.timestamp);
    }

    /**
     * @dev Validate email ownership for a wallet
     * @param userAddress The wallet address
     * @param emailHash The email hash to validate
     * @return isOwner Whether the wallet owns the email
     * @return isVerified Whether the email is verified
     */
    function validateEmailOwnership(address userAddress, bytes32 emailHash) 
        external 
        view 
        returns (bool isOwner, bool isVerified) 
    {
        require(userAddress != address(0), "Invalid user address");
        require(emailHash != bytes32(0), "Invalid email hash");

        isOwner = (emailHashToWallet[emailHash] == userAddress);
        isVerified = emailVerificationStatus[emailHash];

        return (isOwner, isVerified);
    }

    /**
     * @dev Add additional email to a wallet (multi-email support)
     * @param userAddress The wallet address
     * @param emailHash The additional email hash
     */
    function addEmailToWallet(address userAddress, bytes32 emailHash) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");
        require(emailHash != bytes32(0), "Invalid email hash");
        require(!usedEmailHashes[emailHash], "Email already associated with another wallet");
        require(
            walletToEmailHashes[userAddress].length < MAX_EMAILS_PER_WALLET,
            "Maximum emails per wallet reached"
        );

        // Add email mapping
        emailHashToWallet[emailHash] = userAddress;
        walletToEmailHashes[userAddress].push(emailHash);
        usedEmailHashes[emailHash] = true;
        emailCreationTime[emailHash] = block.timestamp;
        emailVerificationStatus[emailHash] = false;
        totalEmailMappings++;

        emit EmailWalletMappingCreated(emailHash, userAddress, block.timestamp);
    }

    /**
     * @dev Remove email from wallet
     * @param userAddress The wallet address
     * @param emailHash The email hash to remove
     */
    function removeEmailFromWallet(address userAddress, bytes32 emailHash) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");
        require(emailHash != bytes32(0), "Invalid email hash");
        require(emailHashToWallet[emailHash] == userAddress, "Email not owned by this wallet");

        // Remove email mapping
        delete emailHashToWallet[emailHash];
        delete usedEmailHashes[emailHash];
        delete emailVerificationStatus[emailHash];
        delete emailCreationTime[emailHash];
        _removeEmailFromWalletArray(userAddress, emailHash);
        totalEmailMappings--;

        // If this was the primary email, clear it from profile
        if (users[userAddress].profile.emailHash == emailHash) {
            users[userAddress].profile.emailHash = bytes32(0);
            users[userAddress].profile.emailVerified = false;
        }

        emit EmailWalletMappingRemoved(emailHash, userAddress, "removed_by_user", block.timestamp);
    }

    /**
     * @dev Verify email for a wallet
     * @param userAddress The wallet address
     * @param emailHash The email hash to verify
     */
    function verifyEmailForWallet(address userAddress, bytes32 emailHash) external onlyLogic {
        require(registeredUsers[userAddress], "User not registered");
        require(emailHashToWallet[emailHash] == userAddress, "Email not owned by this wallet");

        emailVerificationStatus[emailHash] = true;

        // If this is the primary email, update profile verification
        if (users[userAddress].profile.emailHash == emailHash) {
            users[userAddress].profile.emailVerified = true;
            users[userAddress].profile.updatedAt = block.timestamp;
        }

        emit EmailVerificationStatusChanged(emailHash, userAddress, true, block.timestamp);
    }

    /**
     * @dev Get all emails associated with a wallet
     * @param userAddress The wallet address
     * @return emailHashes Array of email hashes associated with the wallet
     */
    function getWalletEmails(address userAddress) external view returns (bytes32[] memory emailHashes) {
        return walletToEmailHashes[userAddress];
    }

    /**
     * @dev Check if email hash is available (not used by any wallet)
     * @param emailHash The email hash to check
     * @return available Whether the email hash is available
     */
    function isEmailHashAvailable(bytes32 emailHash) external view returns (bool available) {
        return !usedEmailHashes[emailHash];
    }

    /**
     * @dev Get email lookup statistics for rate limiting
     * @param userAddress The user address to check
     * @return lookupCount Number of lookups in current window
     * @return lastLookupTime Timestamp of last lookup
     * @return canLookup Whether user can perform more lookups
     */
    function getEmailLookupStats(address userAddress) 
        external 
        view 
        returns (uint256 lookupCount, uint256 lastLookupTime, bool canLookup) 
    {
        lookupCount = emailLookupCount[userAddress];
        lastLookupTime = lastEmailLookupTime[userAddress];
        
        // Check if we're still in the same rate limit window
        if (block.timestamp >= lastLookupTime + EMAIL_LOOKUP_WINDOW) {
            canLookup = true; // Rate limit window has reset
        } else {
            canLookup = (lookupCount < MAX_EMAIL_LOOKUPS_PER_HOUR);
        }

        return (lookupCount, lastLookupTime, canLookup);
    }

    /**
     * @dev Get email security parameters
     * @return maxLookupsPerHour Maximum email lookups per hour
     * @return lookupWindow Time window for rate limiting in seconds
     * @return maxEmailsPerWallet Maximum emails per wallet
     * @return maxEmailChangesPerDay Maximum email changes per day
     */
    function getEmailSecurityParameters() 
        external 
        pure 
        returns (
            uint256 maxLookupsPerHour,
            uint256 lookupWindow,
            uint256 maxEmailsPerWallet,
            uint256 maxEmailChangesPerDay
        ) 
    {
        return (
            MAX_EMAIL_LOOKUPS_PER_HOUR,
            EMAIL_LOOKUP_WINDOW,
            MAX_EMAILS_PER_WALLET,
            MAX_EMAIL_CHANGES_PER_DAY
        );
    }

    /**
     * @dev Emergency function to revoke email mapping (admin only)
     * @param emailHash The email hash to revoke
     * @param reason Reason for revocation
     */
    function adminRevokeEmailMapping(bytes32 emailHash, string calldata reason) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(emailHash != bytes32(0), "Invalid email hash");
        address walletAddress = emailHashToWallet[emailHash];
        require(walletAddress != address(0), "Email mapping does not exist");

        // Remove email mapping
        delete emailHashToWallet[emailHash];
        delete usedEmailHashes[emailHash];
        delete emailVerificationStatus[emailHash];
        delete emailCreationTime[emailHash];
        _removeEmailFromWalletArray(walletAddress, emailHash);
        totalEmailMappings--;

        // If this was the primary email, clear it from profile
        if (users[walletAddress].profile.emailHash == emailHash) {
            users[walletAddress].profile.emailHash = bytes32(0);
            users[walletAddress].profile.emailVerified = false;
        }

        emit EmailWalletMappingRemoved(emailHash, walletAddress, reason, block.timestamp);
    }

    // ============ INTERNAL HELPER FUNCTIONS ============

    /**
     * @dev Internal function to check email lookup rate limiting
     * @param requester The address performing the lookup
     */
    function _checkEmailLookupRateLimit(address requester) internal view {
        uint256 lastLookup = lastEmailLookupTime[requester];
        uint256 lookupCount = emailLookupCount[requester];

        // If we're still in the same rate limit window, check the count
        if (block.timestamp < lastLookup + EMAIL_LOOKUP_WINDOW) {
            require(
                lookupCount < MAX_EMAIL_LOOKUPS_PER_HOUR,
                "Email lookup rate limit exceeded"
            );
        }
        // If window has passed, rate limit resets automatically
    }

    /**
     * @dev Internal function to remove email hash from wallet's email array
     * @param userAddress The wallet address
     * @param emailHash The email hash to remove
     */
    function _removeEmailFromWalletArray(address userAddress, bytes32 emailHash) internal {
        bytes32[] storage emailArray = walletToEmailHashes[userAddress];
        
        for (uint256 i = 0; i < emailArray.length; i++) {
            if (emailArray[i] == emailHash) {
                // Move last element to current position and pop
                emailArray[i] = emailArray[emailArray.length - 1];
                emailArray.pop();
                break;
            }
        }
    }
}
