// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "src/TokenRegistry.sol";

contract DeployTokenRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Set the initial council address and auto-approval time
        address initialCouncil = vm.envAddress("INITIAL_COUNCIL");
        uint256 autoApprovalTime = vm.envUint("AUTO_APPROVAL_TIME");

        // Deploy the TokenRegistry contract
        TokenRegistry tokenRegistry = new TokenRegistry(initialCouncil, autoApprovalTime);

        console.log("TokenRegistry deployed at:", address(tokenRegistry));

        vm.stopBroadcast();
    }
}