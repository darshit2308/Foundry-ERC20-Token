// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from '../lib/forge-std/src/Test.sol';
import {DeployOurToken} from '../script/DeployOurToken.s.sol';
import {OurToken} from '../src/OurToken.sol';
import {console2} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract OurTokenTest is StdCheats,Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address alice = makeAddr('alice');
    address bob = makeAddr("bob");

    uint256 public constant STARTING_BALANCE = 100 ether;
    
    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);  // It means next transaction (next line) will be performed by the one who called this funciton(transfer)
        ourToken.transfer(bob, STARTING_BALANCE);

    }
    function testBobBalance() public view {
        assertEq(STARTING_BALANCE,ourToken.balanceOf(bob));
    }

    function testAllowancesWork() public {
        // We need to approve the contract if our tokens are been transfeered to someone else. We cant allow someone to just takeaway our token w.o permission. 
        // Thats what we will be testing here .
        uint256 initialAllowance = 1000 ;
        // Bob approoves Alice, and allows her to use his(Bob's) tokens.
        vm.prank(bob);
        ourToken.approve(alice,initialAllowance); // Bob approoved Alice to do the following transaction on his behalf.
        
        // Now alice has got the approoval, so she will spend his token now 😊 😊 

        uint256 transferAmount = 500;
        vm.prank(alice);
        ourToken.transferFrom(bob,alice,transferAmount); // Transfer tokens from alice to bob
        assertEq(ourToken.balanceOf(alice) , transferAmount); // Initial balance of alice is 0, since we funded balance of Bob only
        // ourToken.balance(alice) -> Returns how many our tokens are present with alice
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE-transferAmount);
        
    }
    

    /*                  TESTS GENERATED FROM CHATGPT                */

    function testInitialSupply() public {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testMintNotAccessibleExternally() public {
    // Try to call a non-existent mint function (should revert due to no selector)
    // Note: This tests that _mint is NOT exposed externally
    (bool success, ) = address(ourToken).call(
        abi.encodeWithSignature("mint(address,uint256)", address(this), 100)
    );
    assertFalse(success, "mint() should not be accessible externally");
}

    // function testTransferWorks() public {
    //     uint256 amount = 100 * 1e18;
    //     ourToken.transfer(alice, amount);
    //     assertEq(ourToken.balanceOf(alice), amount);
    // }

    function testTransferFailsIfNotEnoughBalance() public {
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transfer(bob, 1);
    }

    function testApproveAndAllowance() public {
        uint256 allowanceAmount = 200 * 1e18;
        bool success = ourToken.approve(alice, allowanceAmount);
        assertTrue(success);
        assertEq(ourToken.allowance(address(this), alice), allowanceAmount);
    }

    // function testTransferFromWorks() public {
    //     uint256 allowanceAmount = 300 * 1e18;

    //     ourToken.approve(alice, allowanceAmount);
    //     vm.prank(alice);
    //     ourToken.transferFrom(address(this), bob, allowanceAmount);

    //     assertEq(ourToken.balanceOf(bob), allowanceAmount);
    //     assertEq(ourToken.allowance(address(this), alice), 0); // Fully used
    // }

    function testTransferFromFailsWithoutApproval() public {
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(address(this), bob, 100);
    }

    function testTransferFromFailsIfOverApprovedAmount() public {
        ourToken.approve(alice, 100);
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(address(this), bob, 200);
    }

    // function testIncreaseDecreaseAllowance() public {
    //     ourToken.approve(alice, 100);
    //     ourToken.increaseAllowance(alice, 50);
    //     assertEq(ourToken.allowance(address(this), alice), 150);

    //     ourToken.decreaseAllowance(alice, 30);
    //     assertEq(ourToken.allowance(address(this), alice), 120);
    // }

    // function testDecreaseAllowanceBelowZero() public {
    //     ourToken.approve(alice, 10);
    //     vm.expectRevert();
    //     ourToken.decreaseAllowance(alice, 20);
    // }

    // function testEmitTransferEvent() public {
    //     vm.expectEmit(true, true, false, true);
    //     emit Transfer(address(this), alice, 100);
    //     ourToken.transfer(alice, 100);
    // }

    function testEmitApprovalEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Approval(address(this), alice, 100);
        ourToken.approve(alice, 100);
    }

    // Needed for the event expectation test
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
}