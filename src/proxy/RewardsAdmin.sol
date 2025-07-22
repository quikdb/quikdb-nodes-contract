// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BaseLogic.sol";
import "../storage/RewardsStorage.sol";
import "../tokens/QuiksToken.sol";
import "../libraries/ValidationLibrary.sol";

/**
 * @title RewardsAdmin - Administrative operations for rewards management
 * @dev Handles all admin-only functions including configuration, emergency operations, 
 *      and contract management with comprehensive access controls and safety features
 */
contract RewardsAdmin is BaseLogic {
    using ValidationLibrary for address;

    // Storage contract reference
    RewardsStorage public rewardsStorage;
    
    // Main RewardsLogic contract reference
    address public rewardsLogic;
    
    // External contract references
    address public batchProcessor;
    address public slashingProcessor;
    address public queryHelper;
    
    // Reward token contracts
    IERC20 public rewardToken;
    QuiksToken public quiksToken;
    
    // Node ID to address mapping for administrative management
    mapping(string => address) public nodeIdToAddress;
    mapping(address => string) public addressToNodeId;
    
    // Emergency configuration
    bool public emergencyMode;
    uint256 public emergencyTimestamp;
    address public emergencyOperator;
    
    // Configuration limits and parameters
    uint256 public maxWithdrawalAmount;
    uint256 public withdrawalCooldown;
    mapping(address => uint256) public lastWithdrawal;

    // =============================================================================
    // EVENTS
    // =============================================================================

    event RewardTokenUpdated(
        address indexed oldToken,
        address indexed newToken,
        address indexed updatedBy
    );

    event WithdrawalExecuted(
        address indexed recipient,
        uint256 amount,
        address indexed token,
        address indexed executedBy
    );

    event NodeMappingUpdated(
        string indexed nodeId,
        address indexed oldAddress,
        address indexed newAddress
    );

    event ProcessorUpdated(
        string indexed processorType,
        address indexed oldProcessor,
        address indexed newProcessor
    );

    event EmergencyModeToggled(
        bool enabled,
        address indexed operator,
        uint256 timestamp
    );

    event EmergencyWithdrawal(
        address indexed recipient,
        uint256 amount,
        address indexed token,
        string reason
    );

    event ConfigurationUpdated(
        string indexed parameter,
        uint256 oldValue,
        uint256 newValue
    );

    // =============================================================================
    // CUSTOM ERRORS
    // =============================================================================

    error UnauthorizedAccess(address caller);
    error EmergencyModeActive();
    error EmergencyModeInactive();
    error WithdrawalCooldownActive(uint256 remainingTime);
    error ExcessiveWithdrawalAmount(uint256 requested, uint256 maximum);
    error InvalidConfiguration(string parameter, uint256 value);
    error ContractNotSet(string contractName);
    error TransferFailed(address recipient, uint256 amount);

    // =============================================================================
    // CONSTRUCTOR AND INITIALIZATION
    // =============================================================================

    constructor() {
        emergencyMode = false;
        maxWithdrawalAmount = 1000000 * 10**18; // 1M tokens default
        withdrawalCooldown = 24 hours;
    }

    /**
     * @dev Initialize the admin contract
     */
    function initialize(
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage,
        address _admin,
        address _rewardsStorage,
        address _rewardsLogic,
        address _quiksToken
    ) external {
        // Initialize base first to set up role system
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, _admin);
        
        require(_rewardsStorage != address(0), "Invalid rewards storage address");
        require(_rewardsLogic != address(0), "Invalid rewards logic address");
        require(_quiksToken != address(0), "Invalid quiks token address");
        
        rewardsStorage = RewardsStorage(_rewardsStorage);
        rewardsLogic = _rewardsLogic;
        quiksToken = QuiksToken(_quiksToken);
    }

    // =============================================================================
    // CORE ADMINISTRATIVE FUNCTIONS
    // =============================================================================

    /**
     * @dev Set reward token for ERC20 distributions
     */
    function setRewardToken(address _rewardToken) external onlyRole(ADMIN_ROLE) whenNotPaused {
        ValidationLibrary.validateAddress(_rewardToken);
        
        address oldToken = address(rewardToken);
        rewardToken = IERC20(_rewardToken);
        
        emit RewardTokenUpdated(oldToken, _rewardToken, msg.sender);
    }

    /**
     * @dev Withdraw contract balance with enhanced security
     */
    function withdrawBalance(
        address recipient, 
        uint256 amount, 
        string calldata reason
    ) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        ValidationLibrary.validateAddress(recipient);
        require(bytes(reason).length > 0, "Withdrawal reason required");
        require(amount > 0, "Amount must be greater than 0");
        
        // Check withdrawal cooldown
        if (lastWithdrawal[msg.sender] + withdrawalCooldown > block.timestamp) {
            revert WithdrawalCooldownActive(
                lastWithdrawal[msg.sender] + withdrawalCooldown - block.timestamp
            );
        }
        
        // Check withdrawal limits (unless emergency mode)
        if (!emergencyMode && amount > maxWithdrawalAmount) {
            revert ExcessiveWithdrawalAmount(amount, maxWithdrawalAmount);
        }
        
        // Update withdrawal tracking
        lastWithdrawal[msg.sender] = block.timestamp;
        
        // Execute withdrawal
        address tokenAddress = address(0);
        if (address(rewardToken) != address(0)) {
            tokenAddress = address(rewardToken);
            require(rewardToken.balanceOf(address(this)) >= amount, "Insufficient token balance");
            require(rewardToken.transfer(recipient, amount), "Token transfer failed");
        } else {
            require(address(this).balance >= amount, "Insufficient ETH balance");
            (bool success, ) = recipient.call{value: amount}("");
            if (!success) revert TransferFailed(recipient, amount);
        }
        
        emit WithdrawalExecuted(recipient, amount, tokenAddress, msg.sender);
    }

    /**
     * @dev Set node address mapping with comprehensive validation
     */
    function setNodeMapping(
        string calldata nodeId, 
        address nodeAddress
    ) external onlyRole(ADMIN_ROLE) whenNotPaused {
        ValidationLibrary.validateId(nodeId);
        ValidationLibrary.validateAddress(nodeAddress);
        
        address oldAddress = nodeIdToAddress[nodeId];
        
        // Update mappings
        nodeIdToAddress[nodeId] = nodeAddress;
        addressToNodeId[nodeAddress] = nodeId;
        
        // Clear old reverse mapping if it exists
        if (oldAddress != address(0)) {
            delete addressToNodeId[oldAddress];
        }
        
        emit NodeMappingUpdated(nodeId, oldAddress, nodeAddress);
    }

    /**
     * @dev Batch update multiple node mappings
     */
    function batchSetNodeMappings(
        string[] calldata nodeIds,
        address[] calldata nodeAddresses
    ) external onlyRole(ADMIN_ROLE) whenNotPaused {
        require(nodeIds.length == nodeAddresses.length, "Array length mismatch");
        require(nodeIds.length <= 50, "Too many mappings (max 50)");
        
        for (uint256 i = 0; i < nodeIds.length; i++) {
            ValidationLibrary.validateId(nodeIds[i]);
            ValidationLibrary.validateAddress(nodeAddresses[i]);
            
            address oldAddress = nodeIdToAddress[nodeIds[i]];
            
            nodeIdToAddress[nodeIds[i]] = nodeAddresses[i];
            addressToNodeId[nodeAddresses[i]] = nodeIds[i];
            
            if (oldAddress != address(0)) {
                delete addressToNodeId[oldAddress];
            }
            
            emit NodeMappingUpdated(nodeIds[i], oldAddress, nodeAddresses[i]);
        }
    }

    // =============================================================================
    // PROCESSOR MANAGEMENT
    // =============================================================================

    /**
     * @dev Set batch processor address
     */
    function setBatchProcessor(address _batchProcessor) external onlyRole(ADMIN_ROLE) whenNotPaused {
        ValidationLibrary.validateAddress(_batchProcessor);
        
        address oldProcessor = batchProcessor;
        batchProcessor = _batchProcessor;
        
        // Update the main RewardsLogic contract if set
        if (rewardsLogic != address(0)) {
            (bool success, ) = rewardsLogic.call(
                abi.encodeWithSignature("updateProcessorFromAdmin(string,address)", "BatchProcessor", _batchProcessor)
            );
            require(success, "Failed to update RewardsLogic processor");
        }
        
        emit ProcessorUpdated("BatchProcessor", oldProcessor, _batchProcessor);
    }

    /**
     * @dev Set slashing processor address
     */
    function setSlashingProcessor(address _slashingProcessor) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        ValidationLibrary.validateAddress(_slashingProcessor);
        
        address oldProcessor = slashingProcessor;
        slashingProcessor = _slashingProcessor;
        
        // Update the main RewardsLogic contract if set
        if (rewardsLogic != address(0)) {
            (bool success, ) = rewardsLogic.call(
                abi.encodeWithSignature("updateProcessorFromAdmin(string,address)", "SlashingProcessor", _slashingProcessor)
            );
            require(success, "Failed to update RewardsLogic processor");
        }
        
        emit ProcessorUpdated("SlashingProcessor", oldProcessor, _slashingProcessor);
    }

    /**
     * @dev Set query helper address
     */
    function setQueryHelper(address _queryHelper) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        ValidationLibrary.validateAddress(_queryHelper);
        
        address oldProcessor = queryHelper;
        queryHelper = _queryHelper;
        
        // Update the main RewardsLogic contract if set
        if (rewardsLogic != address(0)) {
            (bool success, ) = rewardsLogic.call(
                abi.encodeWithSignature("updateProcessorFromAdmin(string,address)", "QueryHelper", _queryHelper)
            );
            require(success, "Failed to update RewardsLogic processor");
        }
        
        emit ProcessorUpdated("QueryHelper", oldProcessor, _queryHelper);
    }

    // =============================================================================
    // EMERGENCY OPERATIONS
    // =============================================================================

    /**
     * @dev Toggle emergency mode (DEFAULT_ADMIN_ROLE only)
     */
    function toggleEmergencyMode(string calldata reason) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(reason).length > 0, "Emergency reason required");
        
        emergencyMode = !emergencyMode;
        emergencyTimestamp = block.timestamp;
        emergencyOperator = msg.sender;
        
        if (emergencyMode) {
            _pause();
        } else {
            _unpause();
        }
        
        emit EmergencyModeToggled(emergencyMode, msg.sender, block.timestamp);
    }

    /**
     * @dev Emergency withdrawal (bypasses normal limits and cooldowns)
     */
    function emergencyWithdraw(
        address recipient,
        uint256 amount,
        string calldata reason
    ) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        if (!emergencyMode) revert EmergencyModeInactive();
        
        ValidationLibrary.validateAddress(recipient);
        require(bytes(reason).length > 0, "Emergency reason required");
        require(amount > 0, "Amount must be greater than 0");
        
        address tokenAddress = address(0);
        if (address(rewardToken) != address(0)) {
            tokenAddress = address(rewardToken);
            require(rewardToken.balanceOf(address(this)) >= amount, "Insufficient token balance");
            require(rewardToken.transfer(recipient, amount), "Token transfer failed");
        } else {
            require(address(this).balance >= amount, "Insufficient ETH balance");
            (bool success, ) = recipient.call{value: amount}("");
            if (!success) revert TransferFailed(recipient, amount);
        }
        
        emit EmergencyWithdrawal(recipient, amount, tokenAddress, reason);
    }

    /**
     * @dev Emergency pause (can be called by ADMIN_ROLE in emergencies)
     */
    function emergencyPause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause (only DEFAULT_ADMIN_ROLE can unpause)
     */
    function unpauseAdmin() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // =============================================================================
    // CONFIGURATION MANAGEMENT
    // =============================================================================

    /**
     * @dev Update maximum withdrawal amount
     */
    function setMaxWithdrawalAmount(uint256 _maxAmount) external onlyRole(ADMIN_ROLE) {
        if (_maxAmount == 0) revert InvalidConfiguration("maxWithdrawalAmount", _maxAmount);
        
        uint256 oldAmount = maxWithdrawalAmount;
        maxWithdrawalAmount = _maxAmount;
        
        emit ConfigurationUpdated("maxWithdrawalAmount", oldAmount, _maxAmount);
    }

    /**
     * @dev Update withdrawal cooldown period
     */
    function setWithdrawalCooldown(uint256 _cooldown) external onlyRole(ADMIN_ROLE) {
        if (_cooldown > 7 days) revert InvalidConfiguration("withdrawalCooldown", _cooldown);
        
        uint256 oldCooldown = withdrawalCooldown;
        withdrawalCooldown = _cooldown;
        
        emit ConfigurationUpdated("withdrawalCooldown", oldCooldown, _cooldown);
    }

    /**
     * @dev Set QuiksToken contract address
     */
    function setQuiksToken(address _quiksToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ValidationLibrary.validateAddress(_quiksToken);
        quiksToken = QuiksToken(_quiksToken);
    }

    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get contract configuration
     */
    function getConfiguration() external view returns (
        uint256 maxWithdrawal,
        uint256 cooldown,
        bool emergency,
        uint256 emergencyTime,
        address emergencyOp
    ) {
        return (
            maxWithdrawalAmount,
            withdrawalCooldown,
            emergencyMode,
            emergencyTimestamp,
            emergencyOperator
        );
    }

    /**
     * @dev Get all processor addresses
     */
    function getProcessors() external view returns (
        address batch,
        address slashing,
        address query
    ) {
        return (batchProcessor, slashingProcessor, queryHelper);
    }

    /**
     * @dev Get node mapping for a node ID
     */
    function getNodeMapping(string calldata nodeId) external view returns (address) {
        return nodeIdToAddress[nodeId];
    }

    /**
     * @dev Get reverse node mapping for an address
     */
    function getReverseNodeMapping(address nodeAddress) external view returns (string memory) {
        return addressToNodeId[nodeAddress];
    }

    /**
     * @dev Check withdrawal eligibility
     */
    function getWithdrawalStatus(address admin) external view returns (
        bool eligible,
        uint256 remainingCooldown,
        uint256 maxAmount
    ) {
        uint256 nextWithdrawal = lastWithdrawal[admin] + withdrawalCooldown;
        eligible = block.timestamp >= nextWithdrawal;
        remainingCooldown = eligible ? 0 : nextWithdrawal - block.timestamp;
        maxAmount = emergencyMode ? type(uint256).max : maxWithdrawalAmount;
    }

    /**
     * @dev Get contract balances
     */
    function getBalances() external view returns (
        uint256 ethBalance,
        uint256 tokenBalance,
        address tokenAddress
    ) {
        ethBalance = address(this).balance;
        tokenAddress = address(rewardToken);
        tokenBalance = tokenAddress != address(0) ? rewardToken.balanceOf(address(this)) : 0;
    }

    // =============================================================================
    // ADMINISTRATIVE OVERSIGHT
    // =============================================================================

    /**
     * @dev Get administrative activity summary
     */
    function getAdminActivity() external view returns (
        uint256 totalWithdrawals,
        uint256 totalNodeMappings,
        uint256 lastConfigUpdate,
        bool systemHealthy
    ) {
        // This would need to be implemented with proper tracking
        // For now, return basic information
        totalNodeMappings = 0; // Would need counter
        lastConfigUpdate = block.timestamp;
        systemHealthy = !emergencyMode && !paused();
    }

    /**
     * @dev Administrative health check
     */
    function healthCheck() external view returns (
        bool allProcessorsSet,
        bool tokensConfigured,
        bool emergencyReady,
        string[] memory issues
    ) {
        string[] memory tempIssues = new string[](10);
        uint256 issueCount = 0;
        
        allProcessorsSet = (batchProcessor != address(0) && 
                          slashingProcessor != address(0) && 
                          queryHelper != address(0));
        
        tokensConfigured = (address(quiksToken) != address(0));
        
        emergencyReady = hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        if (!allProcessorsSet) {
            tempIssues[issueCount++] = "Missing processor contracts";
        }
        if (!tokensConfigured) {
            tempIssues[issueCount++] = "QuiksToken not configured";
        }
        if (emergencyMode) {
            tempIssues[issueCount++] = "Emergency mode active";
        }
        
        // Create properly sized array
        issues = new string[](issueCount);
        for (uint256 i = 0; i < issueCount; i++) {
            issues[i] = tempIssues[i];
        }
    }

    // =============================================================================
    // UTILITY FUNCTIONS
    // =============================================================================

    /**
     * @dev Get contract name for identification
     */
    function _getContractName() internal pure override returns (string memory) {
        return "RewardsAdmin";
    }
}
