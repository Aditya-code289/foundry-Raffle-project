//SPDX License-Identifier:MIT;
pragma solidity ^0.8.35;

import {Script,console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";


contract HelperConfig is Script{

    input_parameters public network_config;
    VRFCoordinatorV2Mock public VRF_Mock;

    struct input_parameters{
        uint set_price;
        uint i_interval;
        address i_vrf_coordinator;
        bytes32 i_keyhash;
        uint256 i_subsId;
        uint32 i_gas_limit;
    }

    constructor(){
        if(block.chainid == 11155111){
            network_config = SepoliaHelperConfig();
        }

        else{
            network_config = AnvilHelperConfig();
        }
    }


    function SepoliaHelperConfig() public view returns(input_parameters memory){

        return input_parameters({
            set_price: 0.01 ether,
            i_interval: 30, 
            i_vrf_coordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            i_keyhash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            i_subsId: 84878976044547458740815139561977445788418858650218731706540408119919111200452,
            i_gas_limit: 2500000
        });    

    }

    function AnvilHelperConfig() public returns(input_parameters memory){

        if(network_config.i_vrf_coordinator != address(0)){
            return network_config;                          // this line will solve all the fuckinnn problemmmmmm 
        }

        vm.startBroadcast();
        VRF_Mock = new VRFCoordinatorV2Mock(0.25 ether, 1e9); // base fees and gas price 
        uint subId = VRF_Mock.createSubscription();
        VRF_Mock.fundSubscription(subId, 100 ether);
        vm.stopBroadcast();

        return input_parameters({
            set_price: 0.01 ether,  
            i_interval: 30, 
            i_vrf_coordinator: address(VRF_Mock),
            i_keyhash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            i_subsId: subId,
            i_gas_limit: 2500000
        }); 


    }


}