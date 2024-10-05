//SPDX-License-Identifier:MIT

pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {WrappedEmpressToken} from "../src/WrappedEmpressToken.sol";
import {EmpressToken} from "../src/EmpressToken.sol";

contract DeployWET is Script {
    function run() external {
        vm.startBroadcast();
        EmpressToken emp = new EmpressToken();
        WrappedEmpressToken wemp = new WrappedEmpressToken(address(emp));
        vm.stopBroadcast();
    }
}
