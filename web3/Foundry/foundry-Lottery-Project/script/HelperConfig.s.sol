// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from '../test/mocks/LinkToken.sol';
// This is a helper contract to get the config values from the script


abstract contract CodeConstants {
    /* VRF Mock constants */
    uint96 public MOCK_BASE_FEE = 0.25 ether; // 0.25 LINK
    uint96 public MOCK_GAS_PRICE_LINK = 1e9; // 1 GWEI
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15; // 1 LINK = 1 GWEI

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
contract HelperConfig is CodeConstants,Script {
    error HelperConfig__InvalidChainId();
    struct NetworkConfig { // The struct of NetworkConfig has all those variables that are present in the constructor of Raffle.sol
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        address account;
    }
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs; 

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }
    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if(networkConfigs[chainId].vrfCoordinator != address(0) ){ // means checking if networkConfigs is non empty
            return networkConfigs[chainId];
        }
        else if(chainId == LOCAL_CHAIN_ID){
            return getOrCreateAnvilConfig();
        }
        else
        {
            revert HelperConfig__InvalidChainId();
        }
    }
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig ({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x34c3E3b2Fe2e12D9D76bc4685AA02ca4e5ba6213
        });
    }
    function getOrCreateAnvilConfig() public returns(NetworkConfig memory) {
        if(localNetworkConfig.vrfCoordinator != address(0) ){
            return localNetworkConfig;
        }

        // Deploy the mocks and return the config
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_GAS_PRICE_LINK,MOCK_BASE_FEE,MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, // 30 seconds
                vrfCoordinator: address(vrfCoordinatorMock),
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                callbackGasLimit: 500000,
                subscriptionId: 0,
                link: address(linkToken),
                account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });
        return localNetworkConfig;
    }

}