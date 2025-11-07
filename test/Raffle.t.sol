// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";

contract RaffleTest is Test {
    Raffle public raffle;

    function setUp() public {
        raffle = new Raffle(0x922dA3512e2BEBBe32bccE59adf7E6759fB8CEA2, 10299999);
    }

}
