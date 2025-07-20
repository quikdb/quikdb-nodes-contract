// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RateLimitingLibrary
 * @notice Comprehensive rate limiting and circuit breaker library for production security
 * @dev Provides circuit breakers, rate limiting, emergency pause mechanisms, and anomaly detection
 */
library RateLimitingLibrary {
    // ---------------------------------------------------------------------
    // Constants
    // ---------------------------------------------------------------------
    
    // Rate limiting windows (in seconds)
    uint256 public constant MINUTE_WINDOW = 60;
    uint256 public constant HOUR_WINDOW = 3600;
    uint256 public constant DAY_WINDOW = 86400;
    uint256 public constant WEEK_WINDOW = 604800;
    
    // Rate limits per operation type
    uint256 public constant MAX_CLUSTER_REGISTRATIONS_PER_HOUR = 10;
    uint256 public constant MAX_REWARD_DISTRIBUTIONS_PER_MINUTE = 5;
    uint256 public constant MAX_ALLOCATIONS_PER_REQUESTER_PER_DAY = 50;
    uint256 public constant MAX_NODE_UPDATES_PER_HOUR = 20;
    uint256 public constant MAX_STORAGE_OPERATIONS_PER_MINUTE = 10;
    
    // Circuit breaker thresholds
    uint256 public constant ANOMALY_THRESHOLD_PERCENTAGE = 300; // 300% increase triggers circuit breaker
    uint256 public constant CIRCUIT_BREAKER_COOLDOWN = 3600; // 1 hour cooldown
    uint256 public constant EMERGENCY_PAUSE_DURATION = 86400; // 24 hours max emergency pause
    
    // Time lock durations
    uint256 public constant CRITICAL_PARAM_TIMELOCK = 604800; // 7 days for critical parameters
    uint256 public constant ADMIN_OVERRIDE_TIMELOCK = 3600; // 1 hour for admin overrides
    
    // ---------------------------------------------------------------------
    // Structs
    // ---------------------------------------------------------------------
    
    struct RateLimit {
        uint256 count;
        uint256 windowStart;
        uint256 maxAllowed;
        uint256 windowDuration;
        bool isActive;
    }
    
    struct CircuitBreaker {
        bool isTripped;
        uint256 tripTime;
        uint256 cooldownDuration;
        uint256 failureCount;
        uint256 successCount;
        uint256 anomalyThreshold;
        string reason;
    }
    
    struct EmergencyPause {
        bool isPaused;
        uint256 pauseTime;
        uint256 maxDuration;
        address pausedBy;
        string reason;
    }
    
    struct TimeLockedOperation {
        bytes32 operationHash;
        uint256 proposalTime;
        uint256 executionTime;
        address proposedBy;
        bool executed;
        string description;
    }
    
    struct AnomalyDetection {
        uint256 baselineValue;
        uint256 currentValue;
        uint256 measurementWindow;
        uint256 lastMeasurement;
        uint256 anomalyCount;
    }
    
    // ---------------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------------
    
    event RateLimitExceeded(
        address indexed user,
        string indexed operation,
        uint256 attemptCount,
        uint256 maxAllowed
    );
    
    event CircuitBreakerTripped(
        string indexed contractName,
        string indexed operation,
        string reason,
        uint256 tripTime
    );
    
    event CircuitBreakerReset(
        string indexed contractName,
        string indexed operation,
        uint256 resetTime
    );
    
    event EmergencyPauseActivated(
        string indexed contractName,
        address indexed pausedBy,
        string reason,
        uint256 duration
    );
    
    event EmergencyPauseDeactivated(
        string indexed contractName,
        address indexed deactivatedBy,
        uint256 pauseDuration
    );
    
    event AnomalyDetected(
        string indexed contractName,
        string indexed metric,
        uint256 baselineValue,
        uint256 currentValue,
        uint256 percentageIncrease
    );
    
    event TimeLockedOperationProposed(
        bytes32 indexed operationHash,
        address indexed proposedBy,
        uint256 executionTime,
        string description
    );
    
    event TimeLockedOperationExecuted(
        bytes32 indexed operationHash,
        address indexed executedBy,
        uint256 executionTime
    );
    
    // ---------------------------------------------------------------------
    // Custom Errors
    // ---------------------------------------------------------------------
    
    error RateLimitExceededError(string operation, uint256 current, uint256 max);
    error CircuitBreakerTrippedError(string contractName, string reason);
    error EmergencyPauseActive(string contractName, string reason);
    error TimeLockedOperationNotReady(bytes32 operationHash, uint256 readyTime);
    error TimeLockedOperationExpired(bytes32 operationHash, uint256 expiredTime);
    error AnomalyThresholdExceeded(string metric, uint256 value, uint256 threshold);
    error InvalidRateLimitConfiguration(string parameter);
    error UnauthorizedEmergencyPause(address caller);
    error InvalidTimelock(uint256 proposedDuration, uint256 maxDuration);
    
    // ---------------------------------------------------------------------
    // Rate Limiting Functions
    // ---------------------------------------------------------------------
    
    /**
     * @dev Check and update rate limit for a specific operation
     */
    function checkRateLimit(
        mapping(address => mapping(string => RateLimit)) storage rateLimits,
        address user,
        string memory operation,
        uint256 maxAllowed,
        uint256 windowDuration
    ) internal {
        RateLimit storage limit = rateLimits[user][operation];
        
        // Initialize if first time or window expired
        if (limit.windowStart == 0 || block.timestamp >= limit.windowStart + windowDuration) {
            limit.windowStart = block.timestamp;
            limit.count = 1;
            limit.maxAllowed = maxAllowed;
            limit.windowDuration = windowDuration;
            limit.isActive = true;
            return;
        }
        
        // Check if within rate limit
        if (limit.count >= maxAllowed) {
            revert RateLimitExceededError(operation, limit.count, maxAllowed);
        }
        
        limit.count++;
    }
    
    /**
     * @dev Get current rate limit status for user and operation
     */
    function getRateLimitStatus(
        mapping(address => mapping(string => RateLimit)) storage rateLimits,
        address user,
        string memory operation
    ) internal view returns (uint256 currentCount, uint256 maxAllowed, uint256 resetTime) {
        RateLimit storage limit = rateLimits[user][operation];
        return (
            limit.count,
            limit.maxAllowed,
            limit.windowStart + limit.windowDuration
        );
    }
    
    // ---------------------------------------------------------------------
    // Circuit Breaker Functions
    // ---------------------------------------------------------------------
    
    /**
     * @dev Check circuit breaker status and trip if necessary
     */
    function checkCircuitBreaker(
        mapping(string => CircuitBreaker) storage circuitBreakers,
        string memory operation,
        bool operationSuccess
    ) internal {
        CircuitBreaker storage breaker = circuitBreakers[operation];
        
        // Reset if cooldown period has passed
        if (breaker.isTripped && block.timestamp >= breaker.tripTime + breaker.cooldownDuration) {
            breaker.isTripped = false;
            breaker.failureCount = 0;
            breaker.successCount = 0;
        }
        
        // Revert if circuit breaker is still tripped
        if (breaker.isTripped) {
            revert CircuitBreakerTrippedError(operation, breaker.reason);
        }
        
        // Update success/failure counts
        if (operationSuccess) {
            breaker.successCount++;
        } else {
            breaker.failureCount++;
        }
        
        // Check if we should trip the breaker
        uint256 totalOperations = breaker.successCount + breaker.failureCount;
        if (totalOperations >= 10) { // Minimum sample size
            uint256 failureRate = (breaker.failureCount * 100) / totalOperations;
            if (failureRate >= 50) { // 50% failure rate triggers breaker
                _tripCircuitBreaker(breaker, operation, "High failure rate detected");
            }
        }
    }
    
    /**
     * @dev Manually trip circuit breaker
     */
    function tripCircuitBreaker(
        mapping(string => CircuitBreaker) storage circuitBreakers,
        string memory operation,
        string memory reason
    ) internal {
        _tripCircuitBreaker(circuitBreakers[operation], operation, reason);
    }
    
    /**
     * @dev Internal function to trip circuit breaker
     */
    function _tripCircuitBreaker(
        CircuitBreaker storage breaker,
        string memory operation,
        string memory reason
    ) private {
        breaker.isTripped = true;
        breaker.tripTime = block.timestamp;
        breaker.cooldownDuration = CIRCUIT_BREAKER_COOLDOWN;
        breaker.reason = reason;
    }
    
    // ---------------------------------------------------------------------
    // Emergency Pause Functions
    // ---------------------------------------------------------------------
    
    /**
     * @dev Activate emergency pause for a contract
     */
    function activateEmergencyPause(
        mapping(string => EmergencyPause) storage emergencyPauses,
        string memory contractName,
        string memory reason,
        uint256 duration,
        address pausedBy
    ) internal {
        require(duration <= EMERGENCY_PAUSE_DURATION, "Duration exceeds maximum");
        
        EmergencyPause storage pause = emergencyPauses[contractName];
        pause.isPaused = true;
        pause.pauseTime = block.timestamp;
        pause.maxDuration = duration;
        pause.pausedBy = pausedBy;
        pause.reason = reason;
    }
    
    /**
     * @dev Check if emergency pause is active
     */
    function checkEmergencyPause(
        mapping(string => EmergencyPause) storage emergencyPauses,
        string memory contractName
    ) internal view {
        EmergencyPause storage pause = emergencyPauses[contractName];
        
        if (pause.isPaused) {
            // Check if pause has expired
            if (block.timestamp >= pause.pauseTime + pause.maxDuration) {
                // Pause has expired, but we can't modify storage in view function
                // This will be handled by the deactivateExpiredPause function
                return;
            }
            revert EmergencyPauseActive(contractName, pause.reason);
        }
    }
    
    /**
     * @dev Deactivate emergency pause
     */
    function deactivateEmergencyPause(
        mapping(string => EmergencyPause) storage emergencyPauses,
        string memory contractName
    ) internal {
        EmergencyPause storage pause = emergencyPauses[contractName];
        pause.isPaused = false;
    }
    
    // ---------------------------------------------------------------------
    // Time-Locked Operations
    // ---------------------------------------------------------------------
    
    /**
     * @dev Propose a time-locked operation
     */
    function proposeTimeLockedOperation(
        mapping(bytes32 => TimeLockedOperation) storage timeLockedOps,
        bytes32 operationHash,
        uint256 delay,
        string memory description,
        address proposer
    ) internal {
        require(delay >= ADMIN_OVERRIDE_TIMELOCK, "Delay too short");
        require(delay <= CRITICAL_PARAM_TIMELOCK, "Delay too long");
        
        TimeLockedOperation storage op = timeLockedOps[operationHash];
        require(!op.executed, "Operation already executed");
        
        op.operationHash = operationHash;
        op.proposalTime = block.timestamp;
        op.executionTime = block.timestamp + delay;
        op.proposedBy = proposer;
        op.executed = false;
        op.description = description;
    }
    
    /**
     * @dev Execute a time-locked operation
     */
    function executeTimeLockedOperation(
        mapping(bytes32 => TimeLockedOperation) storage timeLockedOps,
        bytes32 operationHash
    ) internal {
        TimeLockedOperation storage op = timeLockedOps[operationHash];
        require(op.proposalTime > 0, "Operation not found");
        require(!op.executed, "Operation already executed");
        require(block.timestamp >= op.executionTime, "Operation not ready");
        require(block.timestamp <= op.executionTime + DAY_WINDOW, "Operation expired");
        
        op.executed = true;
    }
    
    // ---------------------------------------------------------------------
    // Anomaly Detection Functions
    // ---------------------------------------------------------------------
    
    /**
     * @dev Update anomaly detection metric and check for anomalies
     */
    function updateAnomalyDetection(
        mapping(string => AnomalyDetection) storage anomalyDetectors,
        string memory metric,
        uint256 currentValue
    ) internal returns (bool anomalyDetected) {
        AnomalyDetection storage detector = anomalyDetectors[metric];
        
        // Initialize baseline if first measurement
        if (detector.lastMeasurement == 0) {
            detector.baselineValue = currentValue;
            detector.currentValue = currentValue;
            detector.lastMeasurement = block.timestamp;
            detector.measurementWindow = DAY_WINDOW;
            return false;
        }
        
        // Update baseline periodically (every week)
        if (block.timestamp >= detector.lastMeasurement + WEEK_WINDOW) {
            detector.baselineValue = detector.currentValue;
        }
        
        detector.currentValue = currentValue;
        detector.lastMeasurement = block.timestamp;
        
        // Check for anomaly (300% increase from baseline)
        if (currentValue > detector.baselineValue * 3) {
            detector.anomalyCount++;
            return true;
        }
        
        return false;
    }
    
    // ---------------------------------------------------------------------
    // Helper Functions
    // ---------------------------------------------------------------------
    
    /**
     * @dev Calculate percentage increase
     */
    function calculatePercentageIncrease(uint256 baseline, uint256 current) 
        internal 
        pure 
        returns (uint256) 
    {
        if (baseline == 0) return current > 0 ? type(uint256).max : 0;
        return ((current - baseline) * 100) / baseline;
    }
    
    /**
     * @dev Check if address has admin privileges (placeholder - implement based on your access control)
     */
    function validateAdminAccess(address caller) internal pure {
        // This should be implemented by the calling contract using their access control
        require(caller != address(0), "Invalid admin address");
    }
}
