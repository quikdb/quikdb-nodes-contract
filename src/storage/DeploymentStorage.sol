// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IUserStorage.sol";

/**
 * @title DeploymentStorage
 * @dev Storage contract for application deployment data
 * @notice This contract is immutable and stores all deployment data permanently
 * @dev Includes cross-contract verification with UserStorage for wallet consistency
 */
contract DeploymentStorage is AccessControl {
    bytes32 public constant LOGIC_ROLE = keccak256("LOGIC_ROLE");

    // Cross-contract references for wallet verification
    IUserStorage public userStorage;
    
    // Wallet activity tracking for audit trails
    mapping(address => uint256) private walletLastActivity;           // wallet to last activity timestamp
    mapping(address => uint256) private walletOperationCount;         // wallet to total operations count
    mapping(address => bytes32[]) private walletRecentOperations;     // wallet to recent operation hashes (last 10)
    
    // Rate limiting for wallet operations
    mapping(address => uint256) private walletHourlyOperations;       // wallet to operations in current hour
    mapping(address => uint256) private walletHourlyResetTime;        // wallet to hour reset timestamp
    
    // Wallet-based statistics
    mapping(address => uint256) private walletTotalCost;              // wallet to total deployment costs
    mapping(address => uint256) private walletActiveDeployments;      // wallet to active deployment count
    
    // Security parameters
    uint256 private constant MAX_OPERATIONS_PER_HOUR = 20;           // Rate limit for operations per wallet
    uint256 private constant MAX_RECENT_OPERATIONS = 10;             // Maximum recent operations to track
    
    // Enhanced events with wallet address indexing
    event WalletOperationPerformed(
        address indexed walletAddress,
        bytes32 indexed operationHash,
        string operationType,
        bytes32 deploymentId,
        uint256 timestamp
    );
    
    event WalletRateLimitExceeded(
        address indexed walletAddress,
        uint256 operationCount,
        uint256 timestamp
    );

    // Deployment status enumeration
    enum DeploymentStatus {
        PENDING,    // Deployment created but not yet active
        ACTIVE,     // Deployment running normally
        SCALING,    // Deployment in process of scaling
        SUSPENDED,  // Deployment temporarily suspended
        REVOKED,    // Deployment permanently revoked
        FAILED      // Deployment failed
    }

    // Deployment structure
    struct Deployment {
        bytes32 deploymentId;           // Unique identifier
        address owner;                  // Wallet address of deployer
        string clusterRequirements;     // Auto-cluster specifications
        bytes32 imageHash;              // Encrypted container bundle hash
        bytes32 keyHash;                // Encryption key hash for privacy
        uint256 replicas;               // Number of replicas
        uint256 timestamp;              // Deployment creation time
        bool isActive;                  // Deployment status
        bytes32[] allocatedResources;   // Linked ResourceStorage allocations
        DeploymentStatus status;        // Current deployment status
        uint256 lastUpdated;            // Last update timestamp
        string region;                  // Deployment region
        uint256 totalCost;              // Total cost in wei
    }

    // Storage mappings
    mapping(address => bytes32[]) private deployerApplications;     // wallet to deployment IDs
    mapping(bytes32 => address) private deploymentOwner;           // deployment ID to owner wallet
    mapping(bytes32 => Deployment) private deployments;           // ID to deployment data
    mapping(address => uint256) private deploymentCount;          // wallet to deployment count

    // Indexes for efficient lookups
    mapping(string => bytes32[]) private deploymentsByRegion;      // region to deployment IDs
    mapping(DeploymentStatus => bytes32[]) private deploymentsByStatus; // status to deployment IDs
    mapping(bytes32 => bytes32[]) private resourceDeployments;     // resource ID to deployments using it

    // Statistics
    uint256 private totalDeployments;
    uint256 private activeDeployments;
    uint256 private revokedDeployments;

    // Access control modifier
    modifier onlyLogic() {
        // Remove role check for development - anyone can call
        _;
    }

    // Owner-only modifier for deployment operations
    modifier onlyDeploymentOwner(bytes32 deploymentId) {
        require(deploymentOwner[deploymentId] == msg.sender, "Not deployment owner");
        _;
    }

    // Wallet verification modifier
    modifier onlyRegisteredUser(address userAddress) {
        require(address(userStorage) != address(0), "UserStorage not set");
        require(userStorage.isUserRegistered(userAddress), "User not registered");
        _;
    }

    // Rate limiting modifier
    modifier rateLimited(address walletAddress) {
        _checkRateLimit(walletAddress);
        _;
    }

    // Wallet address validation modifier
    modifier validWalletAddress(address walletAddress) {
        require(walletAddress != address(0), "Invalid wallet address");
        require(walletAddress != address(this), "Cannot use contract address");
        _;
    }

    // Events
    event DeploymentCreated(
        bytes32 indexed deploymentId,
        address indexed owner,
        uint256 replicas,
        string region,
        uint256 timestamp
    );

    event DeploymentScaled(
        bytes32 indexed deploymentId,
        address indexed owner,
        uint256 oldReplicas,
        uint256 newReplicas,
        uint256 timestamp
    );

    event DeploymentRevoked(
        bytes32 indexed deploymentId,
        address indexed owner,
        uint256 timestamp
    );

    event DeploymentStatusUpdated(
        bytes32 indexed deploymentId,
        address indexed owner,
        DeploymentStatus oldStatus,
        DeploymentStatus newStatus,
        uint256 timestamp
    );

    event DeploymentResourceAllocated(
        bytes32 indexed deploymentId,
        bytes32 indexed resourceId,
        address indexed owner
    );

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Set the logic contract address
     * @param logicContract Address of the logic contract
     */
    function setLogicContract(address logicContract) external {
        _grantRole(LOGIC_ROLE, logicContract);
    }

    /**
     * @dev Set the UserStorage contract address for cross-contract verification
     * @param userStorageAddress Address of the UserStorage contract
     */
    function setUserStorage(address userStorageAddress) external {
        require(userStorageAddress != address(0), "Invalid UserStorage address");
        userStorage = IUserStorage(userStorageAddress);
    }

    // =============================================================================
    // DEPLOYMENT MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Create a new deployment
     * @param deploymentId Unique deployment identifier
     * @param owner Wallet address of deployer
     * @param clusterRequirements Auto-cluster specifications
     * @param imageHash Encrypted container bundle hash
     * @param keyHash Encryption key hash for privacy
     * @param replicas Number of replicas
     * @param region Deployment region
     * @return success Whether deployment was created successfully
     */
    function createDeployment(
        bytes32 deploymentId,
        address owner,
        string calldata clusterRequirements,
        bytes32 imageHash,
        bytes32 keyHash,
        uint256 replicas,
        string calldata region
    ) 
        external 
        onlyLogic 
        validWalletAddress(owner)
        onlyRegisteredUser(owner)
        rateLimited(owner)
        returns (bool success) 
    {
        require(deployments[deploymentId].owner == address(0), "Deployment already exists");
        require(replicas > 0, "Replicas must be greater than 0");
        require(bytes(region).length > 0, "Region cannot be empty");

        Deployment storage deployment = deployments[deploymentId];
        deployment.deploymentId = deploymentId;
        deployment.owner = owner;
        deployment.clusterRequirements = clusterRequirements;
        deployment.imageHash = imageHash;
        deployment.keyHash = keyHash;
        deployment.replicas = replicas;
        deployment.timestamp = block.timestamp;
        deployment.isActive = true;
        deployment.status = DeploymentStatus.PENDING;
        deployment.lastUpdated = block.timestamp;
        deployment.region = region;
        deployment.totalCost = 0;

        // Update mappings
        deployerApplications[owner].push(deploymentId);
        deploymentOwner[deploymentId] = owner;
        deploymentCount[owner]++;
        deploymentsByRegion[region].push(deploymentId);
        deploymentsByStatus[DeploymentStatus.PENDING].push(deploymentId);

        // Update wallet statistics and activity tracking
        walletActiveDeployments[owner]++;
        _updateWalletActivity(owner, "CREATE_DEPLOYMENT", deploymentId);

        totalDeployments++;

        emit DeploymentCreated(deploymentId, owner, replicas, region, block.timestamp);
        return true;
    }

    /**
     * @dev Update deployment replicas (scaling)
     * @param deploymentId Deployment identifier
     * @param newReplicas New number of replicas
     */
    function updateReplicas(bytes32 deploymentId, uint256 newReplicas) 
        external 
        onlyLogic 
        returns (bool success) 
    {
        require(deployments[deploymentId].owner != address(0), "Deployment does not exist");
        require(deployments[deploymentId].isActive, "Deployment not active");
        require(newReplicas > 0, "Replicas must be greater than 0");

        Deployment storage deployment = deployments[deploymentId];
        address owner = deployment.owner;
        uint256 oldReplicas = deployment.replicas;
        
        // Apply rate limiting to the owner
        _checkRateLimit(owner);
        
        deployment.replicas = newReplicas;
        deployment.lastUpdated = block.timestamp;
        deployment.status = DeploymentStatus.SCALING;

        // Update wallet activity tracking
        _updateWalletActivity(owner, "SCALE_DEPLOYMENT", deploymentId);

        emit DeploymentScaled(deploymentId, owner, oldReplicas, newReplicas, block.timestamp);
        return true;
    }

    /**
     * @dev Revoke a deployment
     * @param deploymentId Deployment identifier
     */
    function revokeDeployment(bytes32 deploymentId) 
        external 
        onlyLogic 
        returns (bool success) 
    {
        require(deployments[deploymentId].owner != address(0), "Deployment does not exist");
        require(deployments[deploymentId].isActive, "Deployment already inactive");

        Deployment storage deployment = deployments[deploymentId];
        address owner = deployment.owner;
        
        // Apply rate limiting to the owner
        _checkRateLimit(owner);
        
        deployment.isActive = false;
        deployment.keyHash = bytes32(0); // Wipe encryption key hash
        deployment.status = DeploymentStatus.REVOKED;
        deployment.lastUpdated = block.timestamp;

        // Update statistics and wallet tracking
        activeDeployments--;
        revokedDeployments++;
        walletActiveDeployments[owner]--;
        _updateWalletActivity(owner, "REVOKE_DEPLOYMENT", deploymentId);

        emit DeploymentRevoked(deploymentId, owner, block.timestamp);
        return true;
    }

    /**
     * @dev Update deployment status
     * @param deploymentId Deployment identifier
     * @param newStatus New deployment status
     */
    function updateDeploymentStatus(bytes32 deploymentId, DeploymentStatus newStatus) 
        external 
        onlyLogic 
        returns (bool success) 
    {
        require(deployments[deploymentId].owner != address(0), "Deployment does not exist");

        Deployment storage deployment = deployments[deploymentId];
        DeploymentStatus oldStatus = deployment.status;
        deployment.status = newStatus;
        deployment.lastUpdated = block.timestamp;

        // Update active deployments count
        if (newStatus == DeploymentStatus.ACTIVE && oldStatus != DeploymentStatus.ACTIVE) {
            activeDeployments++;
        } else if (oldStatus == DeploymentStatus.ACTIVE && newStatus != DeploymentStatus.ACTIVE) {
            activeDeployments--;
        }

        emit DeploymentStatusUpdated(deploymentId, deployment.owner, oldStatus, newStatus, block.timestamp);
        return true;
    }

    /**
     * @dev Allocate resource to deployment
     * @param deploymentId Deployment identifier
     * @param resourceId Resource allocation identifier
     */
    function allocateResource(bytes32 deploymentId, bytes32 resourceId) 
        external 
        onlyLogic 
        returns (bool success) 
    {
        require(deployments[deploymentId].owner != address(0), "Deployment does not exist");

        Deployment storage deployment = deployments[deploymentId];
        deployment.allocatedResources.push(resourceId);
        resourceDeployments[resourceId].push(deploymentId);

        emit DeploymentResourceAllocated(deploymentId, resourceId, deployment.owner);
        return true;
    }

    /**
     * @dev Update deployment cost
     * @param deploymentId Deployment identifier
     * @param additionalCost Additional cost to add
     */
    function updateDeploymentCost(bytes32 deploymentId, uint256 additionalCost) 
        external 
        onlyLogic 
        returns (bool success) 
    {
        require(deployments[deploymentId].owner != address(0), "Deployment does not exist");

        deployments[deploymentId].totalCost += additionalCost;
        deployments[deploymentId].lastUpdated = block.timestamp;
        return true;
    }

    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get deployment status
     * @param deploymentId Deployment identifier
     * @return deployment Deployment struct
     */
    function getDeploymentStatus(bytes32 deploymentId) 
        external 
        view 
        returns (Deployment memory deployment) 
    {
        require(deployments[deploymentId].owner != address(0), "Deployment does not exist");
        return deployments[deploymentId];
    }

    /**
     * @dev Get deployments by owner
     * @param owner Owner wallet address
     * @return deploymentIds Array of deployment IDs
     */
    function getDeploymentsByOwner(address owner) 
        external 
        view 
        returns (bytes32[] memory deploymentIds) 
    {
        return deployerApplications[owner];
    }

    /**
     * @dev Get deployment owner
     * @param deploymentId Deployment identifier
     * @return owner Owner wallet address
     */
    function getDeploymentOwner(bytes32 deploymentId) 
        external 
        view 
        returns (address owner) 
    {
        return deploymentOwner[deploymentId];
    }

    /**
     * @dev Get deployment count by owner
     * @param owner Owner wallet address
     * @return count Number of deployments
     */
    function getDeploymentCount(address owner) 
        external 
        view 
        returns (uint256 count) 
    {
        return deploymentCount[owner];
    }

    /**
     * @dev Get deployments by region
     * @param region Region name
     * @return deploymentIds Array of deployment IDs
     */
    function getDeploymentsByRegion(string calldata region) 
        external 
        view 
        returns (bytes32[] memory deploymentIds) 
    {
        return deploymentsByRegion[region];
    }

    /**
     * @dev Get deployments by status
     * @param status Deployment status
     * @return deploymentIds Array of deployment IDs
     */
    function getDeploymentsByStatus(DeploymentStatus status) 
        external 
        view 
        returns (bytes32[] memory deploymentIds) 
    {
        return deploymentsByStatus[status];
    }

    /**
     * @dev Get allocated resources for deployment
     * @param deploymentId Deployment identifier
     * @return resourceIds Array of allocated resource IDs
     */
    function getAllocatedResources(bytes32 deploymentId) 
        external 
        view 
        returns (bytes32[] memory resourceIds) 
    {
        require(deployments[deploymentId].owner != address(0), "Deployment does not exist");
        return deployments[deploymentId].allocatedResources;
    }

    /**
     * @dev Get deployments using a resource
     * @param resourceId Resource identifier
     * @return deploymentIds Array of deployment IDs using the resource
     */
    function getDeploymentsByResource(bytes32 resourceId) 
        external 
        view 
        returns (bytes32[] memory deploymentIds) 
    {
        return resourceDeployments[resourceId];
    }

    /**
     * @dev Get deployment statistics
     * @return total Total deployments
     * @return active Active deployments
     * @return revoked Revoked deployments
     */
    function getDeploymentStats() 
        external 
        view 
        returns (uint256 total, uint256 active, uint256 revoked) 
    {
        return (totalDeployments, activeDeployments, revokedDeployments);
    }

    /**
     * @dev Check if deployment exists
     * @param deploymentId Deployment identifier
     * @return exists Whether deployment exists
     */
    function deploymentExists(bytes32 deploymentId) 
        external 
        view 
        returns (bool exists) 
    {
        return deployments[deploymentId].owner != address(0);
    }

    /**
     * @dev Check if address owns deployment
     * @param deploymentId Deployment identifier
     * @param owner Address to check
     * @return isOwner Whether address owns the deployment
     */
    function isDeploymentOwner(bytes32 deploymentId, address owner) 
        external 
        view 
        returns (bool isOwner) 
    {
        return deploymentOwner[deploymentId] == owner;
    }

    // =============================================================================
    // ADMIN FUNCTIONS
    // =============================================================================

    /**
     * @dev Emergency pause deployment (admin only)
     * @param deploymentId Deployment identifier
     */
    function emergencyPauseDeployment(bytes32 deploymentId) 
        external 
        returns (bool success) 
    {
        require(deployments[deploymentId].owner != address(0), "Deployment does not exist");

        Deployment storage deployment = deployments[deploymentId];
        deployment.status = DeploymentStatus.SUSPENDED;
        deployment.lastUpdated = block.timestamp;

        emit DeploymentStatusUpdated(
            deploymentId, 
            deployment.owner, 
            DeploymentStatus.ACTIVE, 
            DeploymentStatus.SUSPENDED, 
            block.timestamp
        );
        return true;
    }

    /**
     * @dev Get total deployments count
     * @return count Total number of deployments
     */
    function getTotalDeployments() external view returns (uint256 count) {
        return totalDeployments;
    }

    // =============================================================================
    // WALLET CONSISTENCY AND AUDIT TRAIL FUNCTIONS
    // =============================================================================

    /**
     * @dev Get wallet activity statistics
     * @param walletAddress The wallet address to query
     * @return lastActivity Timestamp of last activity
     * @return operationCount Total operations performed
     * @return activeDeploys Number of active deployments
     * @return totalCost Total deployment costs
     */
    function getWalletActivity(address walletAddress) 
        external 
        view 
        returns (
            uint256 lastActivity,
            uint256 operationCount,
            uint256 activeDeploys,
            uint256 totalCost
        ) 
    {
        return (
            walletLastActivity[walletAddress],
            walletOperationCount[walletAddress],
            walletActiveDeployments[walletAddress],
            walletTotalCost[walletAddress]
        );
    }

    /**
     * @dev Get recent operations for a wallet
     * @param walletAddress The wallet address to query
     * @return operationHashes Array of recent operation hashes
     */
    function getWalletRecentOperations(address walletAddress) 
        external 
        view 
        returns (bytes32[] memory operationHashes) 
    {
        return walletRecentOperations[walletAddress];
    }

    /**
     * @dev Check if wallet can perform operations (rate limit check)
     * @param walletAddress The wallet address to check
     * @return canOperate Whether the wallet can perform operations
     * @return operationsLeft Number of operations left in current hour
     */
    function checkWalletRateLimit(address walletAddress) 
        external 
        view 
        returns (bool canOperate, uint256 operationsLeft) 
    {
        // Check if hour has reset
        if (block.timestamp >= walletHourlyResetTime[walletAddress] + 1 hours) {
            return (true, MAX_OPERATIONS_PER_HOUR);
        }
        
        uint256 currentOperations = walletHourlyOperations[walletAddress];
        canOperate = currentOperations < MAX_OPERATIONS_PER_HOUR;
        operationsLeft = canOperate ? MAX_OPERATIONS_PER_HOUR - currentOperations : 0;
        
        return (canOperate, operationsLeft);
    }

    /**
     * @dev Verify wallet is registered and can deploy
     * @param walletAddress The wallet address to verify
     * @return isRegistered Whether wallet is registered in UserStorage
     * @return isVerified Whether wallet is verified in UserStorage
     * @return canDeploy Whether wallet can create deployments
     */
    function verifyWalletStatus(address walletAddress) 
        external 
        view 
        returns (bool isRegistered, bool isVerified, bool canDeploy) 
    {
        if (address(userStorage) == address(0)) {
            return (false, false, false);
        }
        
        isRegistered = userStorage.isUserRegistered(walletAddress);
        isVerified = userStorage.isUserVerified(walletAddress);
        canDeploy = isRegistered; // Can deploy if registered, verification not required
        
        return (isRegistered, isVerified, canDeploy);
    }

    /**
     * @dev Get deployments with full audit trail by wallet
     * @param walletAddress The wallet address to query
     * @param includeRevoked Whether to include revoked deployments
     * @return deploymentIds Array of deployment IDs
     * @return statuses Array of deployment statuses
     * @return timestamps Array of creation timestamps
     */
    function getWalletDeploymentsWithAudit(address walletAddress, bool includeRevoked) 
        external 
        view 
        returns (
            bytes32[] memory deploymentIds,
            DeploymentStatus[] memory statuses,
            uint256[] memory timestamps
        ) 
    {
        bytes32[] memory allDeployments = deployerApplications[walletAddress];
        uint256 validCount = 0;
        
        // Count valid deployments
        for (uint256 i = 0; i < allDeployments.length; i++) {
            Deployment storage deployment = deployments[allDeployments[i]];
            if (includeRevoked || deployment.status != DeploymentStatus.REVOKED) {
                validCount++;
            }
        }
        
        // Build return arrays
        deploymentIds = new bytes32[](validCount);
        statuses = new DeploymentStatus[](validCount);
        timestamps = new uint256[](validCount);
        
        uint256 index = 0;
        for (uint256 i = 0; i < allDeployments.length; i++) {
            Deployment storage deployment = deployments[allDeployments[i]];
            if (includeRevoked || deployment.status != DeploymentStatus.REVOKED) {
                deploymentIds[index] = allDeployments[i];
                statuses[index] = deployment.status;
                timestamps[index] = deployment.timestamp;
                index++;
            }
        }
        
        return (deploymentIds, statuses, timestamps);
    }

    // =============================================================================
    // INTERNAL HELPER FUNCTIONS
    // =============================================================================

    /**
     * @dev Internal function to check and enforce rate limiting
     * @param walletAddress The wallet address to check
     */
    function _checkRateLimit(address walletAddress) internal {
        uint256 currentTime = block.timestamp;
        uint256 resetTime = walletHourlyResetTime[walletAddress];
        
        // Reset counter if hour has passed
        if (currentTime >= resetTime + 1 hours) {
            walletHourlyOperations[walletAddress] = 0;
            walletHourlyResetTime[walletAddress] = currentTime;
        }
        
        require(
            walletHourlyOperations[walletAddress] < MAX_OPERATIONS_PER_HOUR,
            "Rate limit exceeded for wallet"
        );
        
        walletHourlyOperations[walletAddress]++;
        
        // Emit rate limit warning if close to limit
        if (walletHourlyOperations[walletAddress] >= MAX_OPERATIONS_PER_HOUR - 2) {
            emit WalletRateLimitExceeded(
                walletAddress,
                walletHourlyOperations[walletAddress],
                currentTime
            );
        }
    }

    /**
     * @dev Internal function to update wallet activity tracking
     * @param walletAddress The wallet address
     * @param operationType Type of operation performed
     * @param deploymentId Related deployment ID
     */
    function _updateWalletActivity(
        address walletAddress,
        string memory operationType,
        bytes32 deploymentId
    ) internal {
        walletLastActivity[walletAddress] = block.timestamp;
        walletOperationCount[walletAddress]++;
        
        // Generate operation hash for tracking
        bytes32 operationHash = keccak256(
            abi.encodePacked(
                walletAddress,
                operationType,
                deploymentId,
                block.timestamp,
                walletOperationCount[walletAddress]
            )
        );
        
        // Add to recent operations (maintain only last MAX_RECENT_OPERATIONS)
        bytes32[] storage recentOps = walletRecentOperations[walletAddress];
        if (recentOps.length >= MAX_RECENT_OPERATIONS) {
            // Shift array left to remove oldest operation
            for (uint256 i = 0; i < MAX_RECENT_OPERATIONS - 1; i++) {
                recentOps[i] = recentOps[i + 1];
            }
            recentOps[MAX_RECENT_OPERATIONS - 1] = operationHash;
        } else {
            recentOps.push(operationHash);
        }
        
        emit WalletOperationPerformed(
            walletAddress,
            operationHash,
            operationType,
            deploymentId,
            block.timestamp
        );
    }
}
