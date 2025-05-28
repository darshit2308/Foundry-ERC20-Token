// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription , FundSubscription , AddConsumer} from "../script/Interactions.s.sol"; // Importing the CreateSubscription script to create a subscription;

contract DeployRaffle is Script {
    function run() public {
        deployContract();

    }
    function deployContract() public returns (Raffle,HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deployes the mocks, and get local config
        // sepolia -> gets the config from the sepolia chain
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();// This returns the config based on the chainId
/* what actually haappening here is, we need to share data to constructor of Raffle.sol for it to function,so this passing of data to Raffle.sol
hapens here. We first store all the data in a memory called config.(All the data to config has arrived from HelperConfig.sol) 
Now from here, we pass the data from config to raffle constructor and thats how, Raffle.sol gets the data.
*/
        if(config.subscriptionId == 0) {
            // Create a subscription if it doesn't exist
            CreateSubscription createSubscription =  new CreateSubscription();
            (config.subscriptionId , config.vrfCoordinator ) = createSubscription.createSubscription(config.vrfCoordinator);
            // Now, the subscriptionId wont't be zero, and we can use it to deploy the Raffle contract.

            // Now Fund it !
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator,config.subscriptionId,config.link);

        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        // No need to broadcast since we already broadcasted on addConsumer.
        addConsumer.addConsumer(address(raffle),config.vrfCoordinator,config.subscriptionId);
        return (raffle, helperConfig);
    }
}