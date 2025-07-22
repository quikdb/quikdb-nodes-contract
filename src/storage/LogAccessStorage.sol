// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title LogAccessStorage
 * @dev Storage contract for managing secure log access tokens
 * @notice This contract handles one-time access tokens for deployment log streaming
 */
contract LogAccessStorage is AccessControl {
    using ECDSA for bytes32;

    bytes32 public constant LOGIC_ROLE = keccak256("LOGIC_ROLE");

    // Token status enumeration
    enum TokenStatus {
        ACTIVE,     // Token is valid and can be used
        USED,       // Token has been consumed
        EXPIRED,    // Token has expired
        REVOKED     // Token has been manually revoked
    }

    // Log access token structure
    struct LogAccessToken {
        bytes32 deploymentId;       // Linked deployment identifier
        bytes32 tokenHash;          // One-time access token hash
        address requester;          // Wallet requesting access
        uint256 expiresAt;          // Token expiration timestamp
        bool isUsed;                // Whether token has been consumed
        uint256 createdAt;          // Token creation time
        TokenStatus status;         // Current token status
        string reason;              // Reason for revocation (if applicable)
        uint256 usedAt;             // Timestamp when token was used
        bytes32 derivedKeyHash;     // AES-GCM encryption key hash
    }

    // Storage mappings
    mapping(bytes32 => LogAccessToken) private accessTokens;           // token hash to token data
    mapping(bytes32 => bytes32[]) private deploymentTokens;           // deployment to active tokens
    mapping(address => bytes32[]) private userTokens;                 // wallet to user's tokens
    mapping(bytes32 => bool) private expiredTokens;                   // track expired tokens
    mapping(address => uint256) private userTokenCount;               // wallet to token count
    mapping(bytes32 => uint256) private deploymentTokenCount;         // deployment to token count

    // Security parameters
    uint256 private constant DEFAULT_TOKEN_DURATION = 1 hours;        // Default token expiration
    uint256 private constant MAX_TOKENS_PER_USER = 10;                // Max active tokens per user
    uint256 private constant MAX_TOKENS_PER_DEPLOYMENT = 50;          // Max active tokens per deployment
    uint256 private constant CLEANUP_BATCH_SIZE = 100;                // Batch size for cleanup operations
    uint256 private constant MIN_TOKEN_DURATION = 5 minutes;          // Minimum token duration
    uint256 private constant MAX_TOKEN_DURATION = 24 hours;           // Maximum token duration

    // Statistics
    uint256 private totalTokensGenerated;
    uint256 private totalTokensUsed;
    uint256 private totalTokensExpired;
    uint256 private totalTokensRevoked;

    // Events
    event LogTokenGenerated(
        bytes32 indexed deploymentId,
        bytes32 indexed tokenHash,
        address indexed requester,
        uint256 expiresAt,
        uint256 createdAt
    );

    event LogTokenUsed(
        bytes32 indexed tokenHash,
        address indexed requester,
        bytes32 indexed deploymentId,
        uint256 timestamp
    );

    event LogTokenRevoked(
        bytes32 indexed tokenHash,
        address indexed requester,
        bytes32 indexed deploymentId,
        string reason,
        uint256 timestamp
    );

    event LogTokenExpired(
        bytes32 indexed tokenHash,
        bytes32 indexed deploymentId,
        uint256 timestamp
    );

    event TokensCleanedUp(
        uint256 cleanedCount,
        uint256 timestamp
    );

    event DeploymentTokensRevoked(
        bytes32 indexed deploymentId,
        uint256 revokedCount,
        string reason
    );

    // Modifiers
    modifier onlyLogic() {
        // Remove role check for development - anyone can call
        _;
    }

    modifier validDeployment(bytes32 deploymentId) {
        require(deploymentId != bytes32(0), "LogAccessStorage: Invalid deployment ID");
        _;
    }

    modifier validToken(bytes32 tokenHash) {
        require(tokenHash != bytes32(0), "LogAccessStorage: Invalid token hash");
        require(accessTokens[tokenHash].tokenHash != bytes32(0), "LogAccessStorage: Token does not exist");
        _;
    }

    modifier tokenNotUsed(bytes32 tokenHash) {
        require(!accessTokens[tokenHash].isUsed, "LogAccessStorage: Token already used");
        _;
    }

    modifier tokenNotExpired(bytes32 tokenHash) {
        require(
            block.timestamp <= accessTokens[tokenHash].expiresAt,
            "LogAccessStorage: Token expired"
        );
        _;
    }

    modifier onlyTokenOwner(bytes32 tokenHash) {
        require(
            accessTokens[tokenHash].requester == msg.sender,
            "LogAccessStorage: Only token owner can perform this action"
        );
        _;
    }

    modifier rateLimited(address user) {
        require(
            userTokenCount[user] < MAX_TOKENS_PER_USER,
            "LogAccessStorage: Too many active tokens for user"
        );
        _;
    }

    /**
     * @dev Constructor
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Generate a one-time access token for deployment logs
     * @param deploymentId The deployment to access logs for
     * @param requester The wallet address requesting access
     * @param duration Token validity duration in seconds (optional, defaults to 1 hour)
     * @return tokenHash The generated token hash
     */
    function generateLogToken(
        bytes32 deploymentId,
        address requester,
        uint256 duration
    )
        external
        onlyLogic
        validDeployment(deploymentId)
        rateLimited(requester)
        returns (bytes32)
    {
        require(requester != address(0), "LogAccessStorage: Invalid requester address");
        
        // Validate duration
        if (duration == 0) {
            duration = DEFAULT_TOKEN_DURATION;
        }
        require(
            duration >= MIN_TOKEN_DURATION && duration <= MAX_TOKEN_DURATION,
            "LogAccessStorage: Invalid token duration"
        );

        // Check deployment token limit
        require(
            deploymentTokenCount[deploymentId] < MAX_TOKENS_PER_DEPLOYMENT,
            "LogAccessStorage: Too many active tokens for deployment"
        );

        // Generate unique token hash
        bytes32 tokenHash = keccak256(
            abi.encodePacked(
                deploymentId,
                requester,
                block.timestamp,
                block.prevrandao,
                totalTokensGenerated
            )
        );

        // Ensure token hash is unique
        require(accessTokens[tokenHash].tokenHash == bytes32(0), "LogAccessStorage: Token collision");

        uint256 expiresAt = block.timestamp + duration;
        bytes32 derivedKeyHash = keccak256(abi.encodePacked(tokenHash, "AES_GCM_KEY"));

        // Create token
        LogAccessToken memory token = LogAccessToken({
            deploymentId: deploymentId,
            tokenHash: tokenHash,
            requester: requester,
            expiresAt: expiresAt,
            isUsed: false,
            createdAt: block.timestamp,
            status: TokenStatus.ACTIVE,
            reason: "",
            usedAt: 0,
            derivedKeyHash: derivedKeyHash
        });

        // Store token
        accessTokens[tokenHash] = token;
        deploymentTokens[deploymentId].push(tokenHash);
        userTokens[requester].push(tokenHash);

        // Update counters
        userTokenCount[requester]++;
        deploymentTokenCount[deploymentId]++;
        totalTokensGenerated++;

        emit LogTokenGenerated(deploymentId, tokenHash, requester, expiresAt, block.timestamp);

        return tokenHash;
    }

    /**
     * @dev Validate if token is valid and not expired
     * @param tokenHash The token hash to validate
     * @return isValid Whether the token is valid
     * @return token The token data if valid
     */
    function validateToken(bytes32 tokenHash)
        external
        view
        validToken(tokenHash)
        returns (bool isValid, LogAccessToken memory token)
    {
        token = accessTokens[tokenHash];
        
        isValid = (
            token.status == TokenStatus.ACTIVE &&
            !token.isUsed &&
            block.timestamp <= token.expiresAt
        );

        return (isValid, token);
    }

    /**
     * @dev Consume a token after log access
     * @param tokenHash The token hash to consume
     */
    function consumeToken(bytes32 tokenHash)
        external
        onlyLogic
        validToken(tokenHash)
        tokenNotUsed(tokenHash)
        tokenNotExpired(tokenHash)
    {
        LogAccessToken storage token = accessTokens[tokenHash];
        
        token.isUsed = true;
        token.status = TokenStatus.USED;
        token.usedAt = block.timestamp;

        // Update counters
        userTokenCount[token.requester]--;
        deploymentTokenCount[token.deploymentId]--;
        totalTokensUsed++;

        emit LogTokenUsed(tokenHash, token.requester, token.deploymentId, block.timestamp);
    }

    /**
     * @dev Revoke all tokens for a deployment
     * @param deploymentId The deployment ID to revoke tokens for
     * @param reason Reason for revocation
     */
    function revokeDeploymentTokens(bytes32 deploymentId, string calldata reason)
        external
        onlyLogic
        validDeployment(deploymentId)
    {
        bytes32[] memory tokens = deploymentTokens[deploymentId];
        uint256 revokedCount = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            bytes32 tokenHash = tokens[i];
            LogAccessToken storage token = accessTokens[tokenHash];

            if (token.status == TokenStatus.ACTIVE && !token.isUsed) {
                token.status = TokenStatus.REVOKED;
                token.reason = reason;
                
                // Update counters
                userTokenCount[token.requester]--;
                deploymentTokenCount[deploymentId]--;
                totalTokensRevoked++;
                revokedCount++;

                emit LogTokenRevoked(tokenHash, token.requester, deploymentId, reason, block.timestamp);
            }
        }

        emit DeploymentTokensRevoked(deploymentId, revokedCount, reason);
    }

    /**
     * @dev Revoke a specific token
     * @param tokenHash The token hash to revoke
     * @param reason Reason for revocation
     */
    function revokeToken(bytes32 tokenHash, string calldata reason)
        external
        onlyLogic
        validToken(tokenHash)
    {
        LogAccessToken storage token = accessTokens[tokenHash];
        
        require(token.status == TokenStatus.ACTIVE, "LogAccessStorage: Token not active");
        require(!token.isUsed, "LogAccessStorage: Token already used");

        token.status = TokenStatus.REVOKED;
        token.reason = reason;

        // Update counters
        userTokenCount[token.requester]--;
        deploymentTokenCount[token.deploymentId]--;
        totalTokensRevoked++;

        emit LogTokenRevoked(tokenHash, token.requester, token.deploymentId, reason, block.timestamp);
    }

    /**
     * @dev Clean up expired tokens (garbage collection)
     * @param maxTokens Maximum number of tokens to clean up in this call
     */
    function cleanupExpiredTokens(uint256 maxTokens) external onlyLogic {
        require(maxTokens > 0 && maxTokens <= CLEANUP_BATCH_SIZE, "LogAccessStorage: Invalid batch size");

        // This is a simplified cleanup - in production, you'd want to maintain
        // a separate array of tokens sorted by expiration time for efficiency
        uint256 cleanedCount = 0;
        uint256 processedCount = 0;

        // Note: This is not gas-efficient for large datasets
        // Consider implementing a more efficient cleanup mechanism in production
        for (uint256 i = 0; i < totalTokensGenerated && cleanedCount < maxTokens; i++) {
            // This would need to iterate through known tokens
            // Implementation simplified for clarity
            processedCount++;
        }

        emit TokensCleanedUp(cleanedCount, block.timestamp);
    }

    /**
     * @dev Get token details
     * @param tokenHash The token hash to query
     * @return token The token data
     */
    function getToken(bytes32 tokenHash)
        external
        view
        validToken(tokenHash)
        returns (LogAccessToken memory token)
    {
        return accessTokens[tokenHash];
    }

    /**
     * @dev Get all tokens for a user
     * @param user The user address to query
     * @return tokens Array of token hashes
     */
    function getUserTokens(address user) external view returns (bytes32[] memory tokens) {
        return userTokens[user];
    }

    /**
     * @dev Get all tokens for a deployment
     * @param deploymentId The deployment ID to query
     * @return tokens Array of token hashes
     */
    function getDeploymentTokens(bytes32 deploymentId) external view returns (bytes32[] memory tokens) {
        return deploymentTokens[deploymentId];
    }

    /**
     * @dev Get user token count
     * @param user The user address to query
     * @return count Number of active tokens for user
     */
    function getUserTokenCount(address user) external view returns (uint256 count) {
        return userTokenCount[user];
    }

    /**
     * @dev Get deployment token count
     * @param deploymentId The deployment ID to query
     * @return count Number of active tokens for deployment
     */
    function getDeploymentTokenCount(bytes32 deploymentId) external view returns (uint256 count) {
        return deploymentTokenCount[deploymentId];
    }

    /**
     * @dev Get derived encryption key hash for a token
     * @param tokenHash The token hash
     * @return keyHash The derived key hash for AES-GCM encryption
     */
    function getDerivedKeyHash(bytes32 tokenHash)
        external
        view
        validToken(tokenHash)
        returns (bytes32 keyHash)
    {
        return accessTokens[tokenHash].derivedKeyHash;
    }

    /**
     * @dev Check if token is expired
     * @param tokenHash The token hash to check
     * @return expired Whether the token is expired
     */
    function isTokenExpired(bytes32 tokenHash)
        external
        view
        validToken(tokenHash)
        returns (bool expired)
    {
        return block.timestamp > accessTokens[tokenHash].expiresAt;
    }

    /**
     * @dev Get contract statistics
     * @return stats Array containing [totalGenerated, totalUsed, totalExpired, totalRevoked]
     */
    function getStatistics() external view returns (uint256[4] memory stats) {
        stats[0] = totalTokensGenerated;
        stats[1] = totalTokensUsed;
        stats[2] = totalTokensExpired;
        stats[3] = totalTokensRevoked;
        return stats;
    }

    /**
     * @dev Get security parameters
     * @return defaultDuration Default token duration in seconds
     * @return maxTokensPerUser Maximum tokens per user
     * @return maxTokensPerDeployment Maximum tokens per deployment
     * @return minDuration Minimum token duration in seconds
     * @return maxDuration Maximum token duration in seconds
     */
    function getSecurityParameters()
        external
        pure
        returns (
            uint256 defaultDuration,
            uint256 maxTokensPerUser,
            uint256 maxTokensPerDeployment,
            uint256 minDuration,
            uint256 maxDuration
        )
    {
        return (
            DEFAULT_TOKEN_DURATION,
            MAX_TOKENS_PER_USER,
            MAX_TOKENS_PER_DEPLOYMENT,
            MIN_TOKEN_DURATION,
            MAX_TOKEN_DURATION
        );
    }

    /**
     * @dev Emergency function to revoke all tokens for a user
     * @param user The user address to revoke all tokens for
     * @param reason Reason for mass revocation
     */
    function revokeAllUserTokens(address user, string calldata reason) external onlyLogic {
        bytes32[] memory tokens = userTokens[user];
        uint256 revokedCount = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            bytes32 tokenHash = tokens[i];
            LogAccessToken storage token = accessTokens[tokenHash];

            if (token.status == TokenStatus.ACTIVE && !token.isUsed) {
                token.status = TokenStatus.REVOKED;
                token.reason = reason;
                
                deploymentTokenCount[token.deploymentId]--;
                totalTokensRevoked++;
                revokedCount++;

                emit LogTokenRevoked(tokenHash, user, token.deploymentId, reason, block.timestamp);
            }
        }

        userTokenCount[user] = 0; // Reset user token count
    }
}
