// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    function run() external {
        // Load from .env or hardcode for now
        vm.startBroadcast();
        new Raffle(0x922dA3512e2BEBBe32bccE59adf7E6759fB8CEA2, 1000000);
        vm.stopBroadcast();
    }
}
