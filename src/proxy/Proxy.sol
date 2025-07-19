// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title QuikProxy
 * @dev Upgradeable proxy for the QUIK platform logic contract
 * @notice This proxy allows upgrading the logic contract while preserving storage
 */
contract QuikProxy is TransparentUpgradeableProxy {
    /**
     * @dev Constructor for QuikProxy
     * @param _logic Address of the initial logic contract
     * @param _admin Address of the proxy admin
     * @param _data Initialization data for the logic contract
     */
    constructor(address _logic, address _admin, bytes memory _data)
        TransparentUpgradeableProxy(_logic, _admin, _data)
    {}
}

/**
 * @title QuikProxyAdmin
 * @dev Admin contract for managing QuikProxy upgrades
 * @notice This contract controls proxy upgrades with role-based access
 */
contract QuikProxyAdmin is ProxyAdmin, AccessControl {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Events
    event LogicUpgraded(address indexed proxy, address indexed oldLogic, address indexed newLogic);
    event AdminChanged(address indexed proxy, address indexed oldAdmin, address indexed newAdmin);

    modifier onlyUpgrader() {
        require(
            hasRole(UPGRADER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized to upgrade"
        );
        _;
    }

    constructor(address admin) ProxyAdmin(admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    /**
     * @dev Upgrade the logic contract of a proxy
     * @param proxy Address of the proxy contract
     * @param newLogic Address of the new logic contract
     */
    function upgradeLogic(ITransparentUpgradeableProxy proxy, address newLogic) external onlyUpgrader {
        // Store old implementation (not directly accessible in this version)
        address oldLogic = address(0); // We can't access the implementation directly

        // In OpenZeppelin v5, only the owner can call upgradeToAndCall
        // The onlyUpgrader check already verified the caller has permission
        // so we can proceed with the upgrade using direct ProxyAdmin's method
        upgradeAndCall(proxy, newLogic, "");

        emit LogicUpgraded(address(proxy), oldLogic, newLogic);
    }

    /**
     * @dev Upgrade the logic contract and call a function
     * @param proxy Address of the proxy contract
     * @param newLogic Address of the new logic contract
     * @param data Calldata for the function to call after upgrade
     */
    function upgradeLogicAndCall(ITransparentUpgradeableProxy proxy, address newLogic, bytes calldata data)
        external
        onlyUpgrader
    {
        // Store old implementation (not directly accessible in this version)
        address oldLogic = address(0); // We can't access the implementation directly

        // In OpenZeppelin v5, only the owner can call upgradeToAndCall
        // The onlyUpgrader check already verified the caller has permission
        upgradeAndCall(proxy, newLogic, data);

        emit LogicUpgraded(address(proxy), oldLogic, newLogic);
    }

    /**
     * @dev Change the admin of a proxy
     * @param proxy Address of the proxy contract
     * @param newAdmin Address of the new admin
     */
    function changeProxyAdmin(ITransparentUpgradeableProxy proxy, address newAdmin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // We can't directly access the old admin with current API
        address oldAdmin = address(0);

        // In OpenZeppelin v5, we need to transfer ownership of the ProxyAdmin
        // and not directly change the admin of the proxy
        transferOwnership(newAdmin);

        emit AdminChanged(address(proxy), oldAdmin, newAdmin);
    }

    /**
     * @dev Grant upgrader role to an address
     * @param account Address to grant upgrader role
     */
    function grantUpgraderRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(UPGRADER_ROLE, account);
    }

    /**
     * @dev Revoke upgrader role from an address
     * @param account Address to revoke upgrader role
     */
    function revokeUpgraderRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(UPGRADER_ROLE, account);
    }
}
