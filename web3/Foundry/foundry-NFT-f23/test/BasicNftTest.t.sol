// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {DeployBasicNft} from '../script/DeployBasicNft.s.sol';
import {BasicNft} from '../src/BasicNft.sol';

contract BasicNftTest is Test {
    DeployBasicNft public deployer;
    BasicNft public basicNft;
    address public USER = makeAddr('user');
    string public constant hero = 'ipfs://QmfSp4fXCW3n47YJ5xCmcM3GPfsUW3ufkwxh22zsjJPWx5';

    function setUp() public {
        deployer = new DeployBasicNft() ;
        basicNft = deployer.run();
    }

    function testNameIsCorrect() public view  {
        string memory expectedName = "Daredevil";
        string memory actualName = basicNft.name();
        // assertEq(expectedName,actualName); -> this works for strings comparison, dont know why..
        assert(keccak256(abi.encodePacked(expectedName)) == keccak256(abi.encodePacked(actualName)) );
    }

    function testCanMintAndHaveBalance() public {
        vm.prank(USER);
        basicNft.mintNft(hero);
        assert(basicNft.balanceOf(USER) == 1);
        assert(keccak256(abi.encodePacked(hero)) == keccak256(abi.encodePacked(basicNft.tokenURI(0))));
        // basicNft.mintNft();
    }
}