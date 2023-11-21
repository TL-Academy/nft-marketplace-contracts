// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {NFT} from "../src/NFT.sol";

/**
 * @title DeployNft Script
 * @dev This script deploys a Nft contract.
 *  How to run the script:
 *  1. make sure you have created the .env file and set the variables
 *  2. in the project root directory run source .env
 *  3. to deploy and verify run forge script script/DeployNft.s.sol:DeployNft --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
 */
contract DeployNft is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new NFT("BoringToken", "BRT");
        vm.stopBroadcast();
    }
}
