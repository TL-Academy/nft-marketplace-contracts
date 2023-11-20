// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Marketplace} from "../src/Marketplace.sol";

/**
 * @title DeployMarketplace Script
 * @dev This script deploys a Marketplace contract.
 *  How to run the script:
 *  1. make sure you have created the .env file and set the variables
 *  2. in the project root directory run source .env
 *  3. to deploy and verify run forge script script/DeployMarkeplace.s.sol:DeployMarketplace --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
 */
contract DeployMarketplace is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new Marketplace();
        vm.stopBroadcast();
    }
}
