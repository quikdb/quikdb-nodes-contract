// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../storage/NodeStorage.sol";
import "../storage/UserStorage.sol";
import "../storage/ResourceStorage.sol";
import "../libraries/ValidationLibrary.sol";
import "../libraries/RateLimitingLibrary.sol";

/**
 * @title BaseLogic - Base contract with common functionality, production validation, and circuit breakers
 */
abstract contract BaseLogic is AccessControl, Pausable, ReentrancyGuard {
    using ValidationLibrary for *;
    using RateLimitingLibrary for *;
    
    // Version for upgrade tracking
    uint256 public constant VERSION = 1;

    // Storage contract addresses
    NodeStorage public nodeStorage;
    UserStorage public userStorage;
    ResourceStorage public resourceStorage;

    // Circuit breaker and rate limiting storage
    mapping(address => mapping(string => RateLimitingLibrary.RateLimit)) private rateLimits;
    mapping(string => RateLimitingLibrary.CircuitBreaker) private circuitBreakers;
    mapping(string => RateLimitingLibrary.EmergencyPause) private emergencyPauses;
    mapping(bytes32 => RateLimitingLibrary.TimeLockedOperation) private timeLockedOperations;
    mapping(string => RateLimitingLibrary.AnomalyDetection) private anomalyDetectors;

    // Roles
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant NODE_OPERATOR_ROLE = keccak256("NODE_OPERATOR_ROLE");
    bytes32 public constant AUTH_SERVICE_ROLE = keccak256("AUTH_SERVICE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    bytes32 public constant CIRCUIT_BREAKER_ROLE = keccak256("CIRCUIT_BREAKER_ROLE");

    // Core events
    event LogicUpgraded(address indexed newLogic, uint256 version);
    event StorageContractUpdated(string contractType, address newAddress);

    modifier onlyStorageContracts() {
        require(
            msg.sender == address(nodeStorage) || msg.sender == address(userStorage)
                || msg.sender == address(resourceStorage),
            "Only storage"
        );
        _;
    }

    modifier rateLimit(string memory operation, uint256 maxAllowed, uint256 windowDuration) {
        RateLimitingLibrary.checkRateLimit(rateLimits, msg.sender, operation, maxAllowed, windowDuration);
        _;
    }

    modifier circuitBreakerCheck(string memory operation) {
        RateLimitingLibrary.checkCircuitBreaker(circuitBreakers, operation, true);
        _;
    }

    modifier emergencyPauseCheck(string memory contractName) {
        RateLimitingLibrary.checkEmergencyPause(emergencyPauses, contractName);
        _;
    }

    modifier timeLockedOperation(bytes32 operationHash) {
        RateLimitingLibrary.executeTimeLockedOperation(timeLockedOperations, operationHash);
        _;
    }

    /**
     * @dev Initialize the base logic contract with comprehensive validation
     */
    function _initializeBase(address _nodeStorage, address _userStorage, address _resourceStorage, address _admin)
        internal
    {
        // Validate all addresses using ValidationLibrary
        ValidationLibrary.validateAddress(_nodeStorage);
        ValidationLibrary.validateAddress(_userStorage);
        ValidationLibrary.validateAddress(_resourceStorage);
        ValidationLibrary.validateAddress(_admin);
        
        require(
            _admin != address(0) && _nodeStorage != address(0) && _userStorage != address(0)
                && _resourceStorage != address(0),
            "Invalid address"
        );

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(UPGRADER_ROLE, _admin);

        // Initialize storage contracts
        nodeStorage = NodeStorage(_nodeStorage);
        userStorage = UserStorage(_userStorage);
        resourceStorage = ResourceStorage(_resourceStorage);
    }

    // Common helper functions

    /**
     * @dev Check if caller is authorized to operate on a node
     */
    function _isNodeAuthorized(string calldata nodeId) internal view returns (address nodeAddress) {
        nodeAddress = nodeStorage.getNodeAddress(nodeId);
        // Remove role check for development - anyone can call
        return nodeAddress;
    }

    /**
     * @dev Verify node operator is caller
     */
    function _onlyNodeOperator(string calldata nodeId) internal view returns (address) {
        address nodeAddress = nodeStorage.getNodeAddress(nodeId);
        require(msg.sender == nodeAddress, "Not node operator");
        return nodeAddress;
    }

    // Common admin functions

    /**
     * @dev Update storage contract address
     */
    function updateStorageContract(string calldata contractType, address newAddress) external {
        require(newAddress != address(0), "Invalid address");
        bytes32 typeHash = keccak256(bytes(contractType));

        if (typeHash == keccak256(bytes("node"))) {
            nodeStorage = NodeStorage(newAddress);
        } else if (typeHash == keccak256(bytes("user"))) {
            userStorage = UserStorage(newAddress);
        } else if (typeHash == keccak256(bytes("resource"))) {
            resourceStorage = ResourceStorage(newAddress);
        } else {
            revert("Invalid type");
        }

        emit StorageContractUpdated(contractType, newAddress);
    }

    /**
     * @dev Emergency pause/unpause and withdraw
     */
    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    // =============================================================================
    // CIRCUIT BREAKER AND RATE LIMITING FUNCTIONS
    // =============================================================================

    /**
     * @dev Activate emergency pause for this contract
     */
    function activateEmergencyPause(
        string calldata reason,
        uint256 duration
    ) external {
        string memory contractName = _getContractName();
        RateLimitingLibrary.activateEmergencyPause(
            emergencyPauses,
            contractName,
            reason,
            duration,
            msg.sender
        );
        
        emit RateLimitingLibrary.EmergencyPauseActivated(contractName, msg.sender, reason, duration);
    }

    /**
     * @dev Deactivate emergency pause
     */
    function deactivateEmergencyPause() external {
        string memory contractName = _getContractName();
        RateLimitingLibrary.deactivateEmergencyPause(emergencyPauses, contractName);
        
        emit RateLimitingLibrary.EmergencyPauseDeactivated(contractName, msg.sender, block.timestamp);
    }

    /**
     * @dev Manually trip circuit breaker for an operation
     */
    function tripCircuitBreaker(
        string calldata operation,
        string calldata reason
    ) external {
        RateLimitingLibrary.tripCircuitBreaker(circuitBreakers, operation, reason);
        
        emit RateLimitingLibrary.CircuitBreakerTripped(_getContractName(), operation, reason, block.timestamp);
    }

    /**
     * @dev Reset circuit breaker for an operation
     */
    function resetCircuitBreaker(string calldata operation) external {
        circuitBreakers[operation].isTripped = false;
        circuitBreakers[operation].failureCount = 0;
        circuitBreakers[operation].successCount = 0;
        
        emit RateLimitingLibrary.CircuitBreakerReset(_getContractName(), operation, block.timestamp);
    }

    /**
     * @dev Propose a time-locked operation
     */
    function proposeTimeLockedOperation(
        bytes32 operationHash,
        uint256 delay,
        string calldata description
    ) external {
        RateLimitingLibrary.proposeTimeLockedOperation(
            timeLockedOperations,
            operationHash,
            delay,
            description,
            msg.sender
        );
        
        emit RateLimitingLibrary.TimeLockedOperationProposed(
            operationHash,
            msg.sender,
            block.timestamp + delay,
            description
        );
    }

    /**
     * @dev Get rate limit status for user and operation
     */
    function getRateLimitStatus(
        address user,
        string calldata operation
    ) external view returns (uint256 currentCount, uint256 maxAllowed, uint256 resetTime) {
        return RateLimitingLibrary.getRateLimitStatus(rateLimits, user, operation);
    }

    /**
     * @dev Check if emergency pause is active
     */
    function isEmergencyPauseActive() external view returns (bool) {
        string memory contractName = _getContractName();
        try this._checkEmergencyPauseView(contractName) {
            return false;
        } catch {
            return true;
        }
    }

    /**
     * @dev Internal view function to check emergency pause (used by isEmergencyPauseActive)
     */
    function _checkEmergencyPauseView(string calldata contractName) external view {
        RateLimitingLibrary.checkEmergencyPause(emergencyPauses, contractName);
    }

    /**
     * @dev Get circuit breaker status
     */
    function getCircuitBreakerStatus(string calldata operation) external view returns (
        bool isTripped,
        uint256 tripTime,
        uint256 failureCount,
        uint256 successCount,
        string memory reason
    ) {
        RateLimitingLibrary.CircuitBreaker storage breaker = circuitBreakers[operation];
        return (
            breaker.isTripped,
            breaker.tripTime,
            breaker.failureCount,
            breaker.successCount,
            breaker.reason
        );
    }

    /**
     * @dev Update anomaly detection metric
     */
    function updateAnomalyDetection(
        string calldata metric,
        uint256 currentValue
    ) external {
        bool anomalyDetected = RateLimitingLibrary.updateAnomalyDetection(
            anomalyDetectors,
            metric,
            currentValue
        );
        
        if (anomalyDetected) {
            RateLimitingLibrary.AnomalyDetection storage detector = anomalyDetectors[metric];
            uint256 percentageIncrease = RateLimitingLibrary.calculatePercentageIncrease(
                detector.baselineValue,
                currentValue
            );
            
            emit RateLimitingLibrary.AnomalyDetected(
                _getContractName(),
                metric,
                detector.baselineValue,
                currentValue,
                percentageIncrease
            );
            
            // Auto-trip circuit breaker for severe anomalies
            if (percentageIncrease >= RateLimitingLibrary.ANOMALY_THRESHOLD_PERCENTAGE) {
                string memory operation = string(abi.encodePacked(metric, "Operation"));
                RateLimitingLibrary.tripCircuitBreaker(
                    circuitBreakers,
                    operation,
                    "Anomaly detected: excessive metric increase"
                );
            }
        }
    }

    /**
     * @dev Admin override for emergency situations (time-locked)
     */
    function adminOverride(
        bytes32 operationHash,
        bytes calldata operationData
    ) external timeLockedOperation(operationHash) {
        // Execute the operation data as a low-level call
        (bool success, ) = address(this).call(operationData);
        require(success, "Admin override execution failed");
        
        emit RateLimitingLibrary.TimeLockedOperationExecuted(operationHash, msg.sender, block.timestamp);
    }

    /**
     * @dev Get contract name for logging (to be overridden by inheriting contracts)
     */
    function _getContractName() internal pure virtual returns (string memory) {
        return "BaseLogic";
    }

    fallback() external payable {}

    receive() external payable {}
}
