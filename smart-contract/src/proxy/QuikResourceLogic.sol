// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./QuikBaseLogic.sol";
import "../interfaces/IResourceTrackingEvents.sol";

/**
 * @title QuikResourceLogic - Resource management logic
 */
contract QuikResourceLogic is QuikBaseLogic, IResourceTrackingEvents {
    // Resource events
    event ComputeListingCreated(
        bytes32 indexed listingId,
        string indexed nodeId,
        uint8 tier,
        uint256 hourlyRate
    );
    event StorageListingCreated(
        bytes32 indexed listingId,
        string indexed nodeId,
        uint8 tier,
        uint256 hourlyRate
    );
    event ComputeResourceAllocated(
        bytes32 indexed allocationId,
        address indexed buyer,
        bytes32 indexed listingId,
        uint256 duration
    );

    /**
     * @dev Initialize the resource logic contract
     */
    function initialize(
        address _nodeStorage,
        address _userStorage,
        address _resourceStorage,
        address _admin
    ) external {
        _initializeBase(_nodeStorage, _userStorage, _resourceStorage, _admin);
    }

    // =============================================================================
    // RESOURCE MANAGEMENT FUNCTIONS
    // =============================================================================

    /**
     * @dev Create a compute listing
     */
    function createComputeListing(
        string calldata nodeId,
        ResourceStorage.ComputeTier tier,
        uint256 cpuCores,
        uint256 memoryGB,
        uint256 storageGB,
        uint256 hourlyRate,
        string calldata region
    ) external whenNotPaused returns (bytes32 listingId) {
        address nodeAddress = _onlyNodeOperator(nodeId);

        listingId = resourceStorage.createComputeListing(
            nodeId,
            nodeAddress,
            tier,
            cpuCores,
            memoryGB,
            storageGB,
            hourlyRate,
            region
        );

        emit ComputeListingCreated(listingId, nodeId, uint8(tier), hourlyRate);
        return listingId;
    }

    /**
     * @dev Create a storage listing
     */
    function createStorageListing(
        string calldata nodeId,
        ResourceStorage.StorageTier tier,
        uint256 storageGB,
        uint256 hourlyRate,
        string calldata region
    ) external whenNotPaused returns (bytes32 listingId) {
        address nodeAddress = _onlyNodeOperator(nodeId);

        listingId = resourceStorage.createStorageListing(
            nodeId,
            nodeAddress,
            tier,
            storageGB,
            hourlyRate,
            region
        );

        emit StorageListingCreated(listingId, nodeId, uint8(tier), hourlyRate);
        return listingId;
    }

    /**
     * @dev Purchase compute resources
     */
    function purchaseCompute(
        bytes32 listingId,
        uint256 duration
    )
        external
        payable
        whenNotPaused
        nonReentrant
        returns (bytes32 allocationId)
    {
        ResourceStorage.ComputeListing memory listing = resourceStorage
            .getComputeListing(listingId);
        require(listing.isActive, "Listing not active");

        uint256 totalCost = listing.hourlyRate * duration;
        require(msg.value >= totalCost, "Insufficient payment");

        allocationId = resourceStorage.allocateCompute(
            listingId,
            msg.sender,
            duration,
            totalCost
        );

        // Refund excess payment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        emit ComputeResourceAllocated(
            allocationId,
            msg.sender,
            listingId,
            duration
        );
        return allocationId;
    }

    /**
     * @dev Get compute listing details
     */
    function getComputeListing(
        bytes32 listingId
    ) external view returns (ResourceStorage.ComputeListing memory) {
        return resourceStorage.getComputeListing(listingId);
    }

    /**
     * @dev Get storage listing details
     */
    function getStorageListing(
        bytes32 listingId
    ) external view returns (ResourceStorage.StorageListing memory) {
        return resourceStorage.getStorageListing(listingId);
    }

    /**
     * @dev Get allocation details
     */
    function getResourceAllocation(
        bytes32 allocationId
    ) external view returns (ResourceStorage.ResourceAllocation memory) {
        return resourceStorage.getAllocation(allocationId);
    }

    /**
     * @dev Get total allocations
     */
    function getResourceStats()
        external
        view
        returns (uint256 totalAllocations)
    {
        return resourceStorage.getTotalAllocations();
    }
}
