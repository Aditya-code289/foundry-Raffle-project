//SPDX License-Identifier:MIT;
pragma solidity ^0.8.35;

import {Script,console} from "forge-std/Script.sol";
import {project_raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";



contract deploy_raffle is Script{

    HelperConfig public helper_config;

    function run() external returns(project_raffle){

        // VRFCoordinatorV2Mock VRF_Mock = new VRFCoordinatorV2Mock(0.25 ether, 1e9);
        

        helper_config = new HelperConfig();

        helper_config.AnvilHelperConfig();

       (
            uint set_price,
            uint i_interval,
            address i_vrf_coordinator,
            bytes32 i_keyhash,
            uint256 i_subsId,
            uint32 i_gas_limit

       ) = helper_config.network_config();


       vm.startBroadcast(); 

       project_raffle ProjectRaffle = new project_raffle(
        set_price,
        i_interval,
        i_vrf_coordinator, 
        i_keyhash, 
        i_subsId, 
        i_gas_limit );

        console.log("subId:", i_subsId);
        console.log("VRF_addr_dep", address(helper_config.VRF_Mock()));
        helper_config.VRF_Mock().addConsumer(i_subsId, address(ProjectRaffle));

       vm.stopBroadcast();

       return ProjectRaffle;
    }
}
