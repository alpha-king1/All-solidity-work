// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {Test} from "forge-std/Test.sol";
import {Hello} from "../src/Hello.sol";

contract HelloTest is Test {
    Hello public hello;

    function setUp() public {
        hello = new Hello();
    }

    function testGreet() public {
        assertEq(hello.greet(), 'hello');
    }

    // function testFuzz_SetNumber(uint256 x) public {
    //     Hello.setNumber(x);
    //     assertEq(Hello.number(), x);
    // }
}
