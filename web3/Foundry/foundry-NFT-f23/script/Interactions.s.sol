// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from 'lib/foundry-devops/src/DevOpsTools.sol';
import {BasicNft} from '../src/BasicNft.sol';

contract MintBasicNft is Script{
    string public constant hero = "ipfs://QmfSp4fXCW3n47YJ5xCmcM3GPfsUW3ufkwxh22zsjJPWx5";
    function run() external {
        address mostRecetlyDeployed = DevOpsTools.get_most_recent_deployment("BasicNft",block.chainid);
        mintNftOnContract(mostRecetlyDeployed) ;
    }

    function mintNftOnContract(address contractAddress) public {
        vm.startBroadcast();
        BasicNft(contractAddress).mintNft(hero);
        vm.stopBroadcast();

    }


}