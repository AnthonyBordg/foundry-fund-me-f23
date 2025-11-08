// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");

    uint256 STARTING_BALANCE = 10e18;
    uint256 SEND_VALUE = 0.1 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOnlyOwnerIsMsgSender() public view {
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // with this command the test will succeed if the next call reverts
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    /** 
    function testWithdrawIsZero() public {
        fundMe.withdraw();
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 funderBalance = fundMe.getAddressToAmountFunded(USER);
        assertEq(funderBalance, 0);
    }
    */
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startFunderIndex = 1;
        for (uint160 i = startFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.prank(address(i));
            // vm.deal new adress
            // vm.deal(address(i), STARTING_BALANCE);
            // Can use hoax to do vm.prank and vm.deal in one shot
            hoax(address(i), STARTING_BALANCE);
            // funder funds fundMe
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        // Assert
        assert(endingFundMeBalance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance == endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startFunderIndex = 1;
        for (uint160 i = startFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.prank(address(i));
            // vm.deal new adress
            // vm.deal(address(i), STARTING_BALANCE);
            // Can use hoax to do vm.prank and vm.deal in one shot
            hoax(address(i), STARTING_BALANCE);
            // funder funds fundMe
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        // Assert
        assert(endingFundMeBalance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance == endingOwnerBalance
        );
    }
}
