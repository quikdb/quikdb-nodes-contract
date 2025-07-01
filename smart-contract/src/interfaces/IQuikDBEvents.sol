// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IResourceTypes.sol";

interface IQuikDBEvents is IResourceTypes {
    // Contract Events
    event LogicUpgraded(address indexed newLogic, uint256 version);
    event StorageContractUpdated(string contractType, address newAddress);

    // Node Events
    event NodeRegistered(
        string indexed nodeId,
        address indexed nodeAddress,
        ComputeTier tier,
        uint8 providerType
    );
    event NodeStatusUpdated(string indexed nodeId, ListingStatus status);
    event NodeListed(
        string indexed nodeId,
        uint96 hourlyRate,
        uint32 availability
    );

    // User Events
    event UserRegistered(
        address indexed userAddress,
        bytes32 profileHash,
        uint8 userType,
        uint32 timestamp
    );
    event UserProfileUpdated(
        address indexed userAddress,
        bytes32 profileHash,
        uint32 timestamp
    );

    // Resource Events
    event ComputeListingCreated(
        bytes32 indexed listingId,
        string indexed nodeId,
        ComputeTier tier,
        uint96 hourlyRate
    );
    event StorageListingCreated(
        bytes32 indexed listingId,
        string indexed nodeId,
        StorageTier tier,
        uint96 hourlyRate
    );
    event ComputeResourceAllocated(
        bytes32 indexed allocationId,
        address indexed buyer,
        bytes32 indexed listingId,
        uint32 duration
    );

    // Extended Node Events
    event NodeExtendedInfoUpdated(string indexed nodeId);
    event NodeAttributeUpdated(string indexed nodeId, string key, string value);
    event NodeCertificationAdded(
        string indexed nodeId,
        bytes32 indexed certificationId
    );
    event NodeVerificationUpdated(
        string indexed nodeId,
        bool isVerified,
        uint32 expiryDate
    );
    event NodeSecurityBondSet(string indexed nodeId, uint96 bondAmount);

    // Resource Status Events
    event ResourceDataUpdated(bytes32 indexed id, string action);
}
