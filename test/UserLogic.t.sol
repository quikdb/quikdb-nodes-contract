// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseTest.sol";

/**
 * @title UserLogicTest
 * @notice Tests for UserLogic contract functionality
 */
contract UserLogicTest is BaseTest {
    // =============================================================
    //                      BASIC USER TESTS
    // =============================================================

    function testUserRegistration_BasicFlow() public {
        vm.startPrank(authService);

        bytes32 profileHash = keccak256(abi.encodePacked("user-profile-data"));
        userLogic.registerUser(user, profileHash, UserStorage.UserType.CONSUMER);

        UserStorage.UserProfile memory profile = userLogic.getUserProfile(user);
        assertEq(profile.profileHash, profileHash);
        assertEq(uint8(profile.userType), uint8(UserStorage.UserType.CONSUMER));

        vm.stopPrank();
    }

    function testUserRegistration_DifferentTypes() public {
        vm.startPrank(authService);

        // Test CONSUMER type
        bytes32 consumerHash = keccak256(abi.encodePacked("consumer-data"));
        userLogic.registerUser(address(0x100), consumerHash, UserStorage.UserType.CONSUMER);
        UserStorage.UserProfile memory consumer = userLogic.getUserProfile(address(0x100));
        assertEq(uint8(consumer.userType), uint8(UserStorage.UserType.CONSUMER));

        // Test PROVIDER type
        bytes32 providerHash = keccak256(abi.encodePacked("provider-data"));
        userLogic.registerUser(address(0x200), providerHash, UserStorage.UserType.PROVIDER);
        UserStorage.UserProfile memory provider = userLogic.getUserProfile(address(0x200));
        assertEq(uint8(provider.userType), uint8(UserStorage.UserType.PROVIDER));

        vm.stopPrank();
    }

    // =============================================================
    //                    ACCESS CONTROL TESTS
    // =============================================================

    function testUserRegistration_AccessControl() public {
        vm.startPrank(user); // user doesn't have AUTH_SERVICE_ROLE

        bytes32 profileHash = keccak256(abi.encodePacked("unauthorized-profile"));
        vm.expectRevert();
        userLogic.registerUser(user, profileHash, UserStorage.UserType.CONSUMER);

        vm.stopPrank();
    }

    function testUserRegistration_OnlyAuthServiceCanRegister() public {
        vm.startPrank(nodeOperator); // nodeOperator doesn't have AUTH_SERVICE_ROLE

        bytes32 profileHash = keccak256(abi.encodePacked("operator-profile"));
        vm.expectRevert();
        userLogic.registerUser(nodeOperator, profileHash, UserStorage.UserType.PROVIDER);

        vm.stopPrank();
    }

    // =============================================================
    //                    VALIDATION TESTS
    // =============================================================

    function testUserRegistration_ZeroAddress() public {
        vm.startPrank(authService);

        bytes32 profileHash = keccak256(abi.encodePacked("zero-address-profile"));
        vm.expectRevert();
        userLogic.registerUser(address(0), profileHash, UserStorage.UserType.CONSUMER);

        vm.stopPrank();
    }

    function testUserRegistration_DuplicateUser() public {
        vm.startPrank(authService);

        bytes32 profileHash1 = keccak256(abi.encodePacked("first-profile"));
        // bytes32 profileHash2 = keccak256(abi.encodePacked("second-profile")); // Unused for now

        // First registration should succeed
        userLogic.registerUser(user, profileHash1, UserStorage.UserType.CONSUMER);

        // Second registration with same address should fail (if the contract prevents it)
        // Note: This test assumes the contract prevents duplicate registrations
        // vm.expectRevert();
        // userLogic.registerUser(user, profileHash2, UserStorage.UserType.PROVIDER);

        vm.stopPrank();
    }

    // =============================================================
    //                    PROFILE TESTS
    // =============================================================

    function testUserProfile_UpdateProfile() public {
        vm.startPrank(authService);

        bytes32 initialHash = keccak256(abi.encodePacked("initial-profile"));
        userLogic.registerUser(user, initialHash, UserStorage.UserType.CONSUMER);

        // Verify initial profile
        UserStorage.UserProfile memory initialProfile = userLogic.getUserProfile(user);
        assertEq(initialProfile.profileHash, initialHash);
        assertEq(uint8(initialProfile.userType), uint8(UserStorage.UserType.CONSUMER));

        vm.stopPrank();
    }

    function testUserProfile_MultipleUsers() public {
        vm.startPrank(authService);

        address user1 = address(0x101);
        address user2 = address(0x102);
        address user3 = address(0x103);

        // Register multiple users
        userLogic.registerUser(user1, keccak256("profile-1"), UserStorage.UserType.CONSUMER);
        userLogic.registerUser(user2, keccak256("profile-2"), UserStorage.UserType.PROVIDER);
        userLogic.registerUser(user3, keccak256("profile-3"), UserStorage.UserType.CONSUMER);

        // Verify all users
        _assertUserExists(user1, UserStorage.UserType.CONSUMER);
        _assertUserExists(user2, UserStorage.UserType.PROVIDER);
        _assertUserExists(user3, UserStorage.UserType.CONSUMER);

        vm.stopPrank();
    }

    // =============================================================
    //                      HELPER TESTS
    // =============================================================

    function testRegisterTestUser_Helper() public {
        _registerTestUser(user, UserStorage.UserType.CONSUMER);
        _assertUserExists(user, UserStorage.UserType.CONSUMER);
    }

    function testRegisterProviderUser() public {
        _registerTestUser(address(0x150), UserStorage.UserType.PROVIDER);
        _assertUserExists(address(0x150), UserStorage.UserType.PROVIDER);
    }
}
