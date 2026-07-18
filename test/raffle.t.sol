//SPDX License-Identifier: MIT;
pragma solidity ^0.8.35;

import {project_raffle} from "../src/Raffle.sol";
import {deploy_raffle} from "../script/deploy_raffle.s.sol";
import {Test,console} from "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract test_raffle is Test{
    event new_players(
        address indexed player
    );  // you have to define the event in the test bcz youc an not access it directly bcz it is not a type

    event winner_decided(
        address indexed winner
    );
    
    deploy_raffle DeployRaffle;
    project_raffle ProjectRaffle;
    VRFCoordinatorV2Mock VRF_Mock;

    address Aadi;
    address sarthak; // this is the only way to give the access of the variable to the other functions 
    address divyansh;


    function setUp() external{ 
        DeployRaffle = new deploy_raffle();
        ProjectRaffle = DeployRaffle.run(); 
        VRF_Mock = VRFCoordinatorV2Mock(DeployRaffle.helper_config().VRF_Mock());


        /* this is one of the way to access the constructors arguments, 
           the values and the code in deployment script copies as it as in test scipt 
        */

       Aadi = makeAddr("Aadi");
       sarthak = makeAddr("sarthak"); // this does not give access of these variables to the other fuctions 
       divyansh = makeAddr("divyansh");
       vm.deal(Aadi,10 ether);
       vm.deal(sarthak, 10 ether);
       vm.deal(divyansh, 10 ether);

    }

    function test_enterance_fees() public{
        vm.expectRevert();
        ProjectRaffle.buy_ticket{value:0.005 ether}();
    }

    function test_player_address() public{

        vm.startPrank(Aadi);
        ProjectRaffle.buy_ticket{value:0.01 ether}();
        vm.stopPrank();

        vm.startPrank(sarthak);
        ProjectRaffle.buy_ticket{value:0.02 ether}();
        vm.stopPrank();

        vm.startPrank(divyansh);
        ProjectRaffle.buy_ticket{value:0.01 ether}();
        vm.stopPrank();

        // so the address of third one should not be stored in the array and of first two should
        // so we will check this 

        assertEq(ProjectRaffle.store_players(0), address(Aadi));
        assertEq(ProjectRaffle.store_players(1), address(sarthak));

        // assertEq(ProjectRaffle.store_players(2), address(0)); // this fails bcz there is no index 2 in the array, since it is a dynamic array

        assertEq(Aadi.balance,9.99 ether);
        assertEq(address(ProjectRaffle).balance, 0.04 ether);

        /* assertEq(ProjectRaffle.store_players.length, 3);  this syntax is wrong bcz to this test contract store_player is a function not an array, 
        to solve this, create an another func in the main contract which returns the length of the array * 
        */

    //    assertEq(ProjectRaffle.raffle_state(), RaffleState.Open);

        vm.startPrank(Aadi);
        ProjectRaffle.buy_ticket{value:0.1 ether}();
        vm.stopPrank();

// address of 0th equal 3rd, balance 
        assertEq(ProjectRaffle.store_players(0), ProjectRaffle.store_players(3));
        assertEq(address(ProjectRaffle).balance, 0.14 ether); 
    }

    function test_checkState() public {
        
        assertEq(uint(ProjectRaffle.raffle_state()), 0); // this is one way to compare it with the integer 

        assertNotEq(uint(ProjectRaffle.raffle_state()), 1); // since at time of deployment, raffle state is open, it will not be equal to 1, but 0;
    }

    function test_event_emit() public{
        vm.startPrank(Aadi);
        vm.expectEmit(true, false, false, false, address(ProjectRaffle));
        emit new_players(Aadi);        
        ProjectRaffle.buy_ticket{value:0.01 ether}();
        vm.stopPrank();
    } //

    function test_interval_value() public{
        assertEq(ProjectRaffle.interval(), 30);
    }

    /* now we will use vm.warp() for the intervals test 
       1. raffle_state should be calculating after time has passed and atleast two player has been entered 
       2. so make enter two player and then check some logs 
       3. then pass the deadline and then 
       - check the raffle state 
       - if somebody is able to enter the raffle 
       - isn't the balance is increased 
       - time of deploy matches
       - check the edge case when the time has just touched deadline, if a player is able to enter ?
    
    */

   function test_deadline() public{
        vm.startPrank(Aadi);
        ProjectRaffle.buy_ticket{value: 0.01 ether}();
        vm.stopPrank();

        vm.startPrank(divyansh);
        ProjectRaffle.buy_ticket{value: 0.01 ether}();
        vm.stopPrank();

        assertEq(ProjectRaffle.get_array_length(), 2);
        assertEq(address(ProjectRaffle).balance, 0.02 ether);

        // TRANSITING THE TIME NOW 

        vm.warp(ProjectRaffle.time_of_deploy() + ( (ProjectRaffle.interval()) /2 ) ); // HALF OF THE INTERVAL IS PASSED

        vm.startPrank(sarthak);
        ProjectRaffle.buy_ticket{value: 0.01 ether}();
        vm.stopPrank();

        assertEq(ProjectRaffle.get_array_length(), 3);
        assertEq(address(ProjectRaffle).balance, 0.03 ether);
        assertEq(uint(ProjectRaffle.raffle_state()), 0);
        assertEq(block.timestamp, ProjectRaffle.time_of_deploy() + ProjectRaffle.interval()/2);


        // NOW LET'S TRANSIT THE INTERVAL TO DEADLINE 
        vm.warp(ProjectRaffle.time_of_deploy() + ProjectRaffle.interval() + 1); // when the deadline is cleanly passed
        (bool output_checkup,) = ProjectRaffle.checkUpkeep("");
        assertEq(output_checkup, true);


        ProjectRaffle.performUpkeep("");      // performUpkeep() FREAKING WORKED 😭😭
        assertEq(uint(ProjectRaffle.raffle_state()), 1); 
        

        vm.startPrank(Aadi);
        vm.expectRevert();
        ProjectRaffle.buy_ticket{value:0.02 ether}();
        vm.stopPrank();

        assertEq(ProjectRaffle.get_array_length(), 3);
        assertEq(address(ProjectRaffle).balance, 0.03 ether);

        assertEq(block.timestamp, ProjectRaffle.time_of_deploy() + ProjectRaffle.interval() + 1);

        /* 
            - No player should be able to enter the raffle 
            - raffle state is changed 
            - deadline has been crossed 
            - 
        */


   }


    function test_winner() public{

        vm.startPrank(Aadi);
        ProjectRaffle.buy_ticket{value:0.01 ether}();
        vm.stopPrank();

        vm.startPrank(sarthak);
        ProjectRaffle.buy_ticket{value:0.01 ether}();
        vm.stopPrank();

        vm.startPrank(divyansh);
        ProjectRaffle.buy_ticket{value:0.01 ether}();
        vm.stopPrank();

        // So three players have entered the raffle and now let's pass the deadline 

        vm.warp(ProjectRaffle.time_of_deploy() + ProjectRaffle.interval() + 1); // no boundry condn for now 

        // now we will call performUpkeep() which auto calls, checkUpkeep()

        ProjectRaffle.performUpkeep("");

        // Now we have deployed mock contract in the name of VRF_Mock which remember takes two inputs /// 
        // hence we can call the request random words thorugh the mock coordinator 

        // vm.expectEmit(true, false, false, false, address(ProjectRaffle));
        // emit winner_decided(ProjectRaffle.winner());

        VRF_Mock.fulfillRandomWords(ProjectRaffle.requestId(), address(ProjectRaffle));

        console.log("winner_index", ProjectRaffle.winner_index());
        console.log("winner_Addr",ProjectRaffle.winner());

        // assertEq((ProjectRaffle.winner()), (ProjectRaffle.get_player_address(ProjectRaffle.winner_index())));

        assertEq(address(ProjectRaffle).balance, 0 ether);
        assertEq(address(divyansh).balance, 10.02 ether);
        assertEq(address(sarthak).balance, 9.99 ether);
        assertEq(address(Aadi).balance, 9.99 ether);
        assertEq(ProjectRaffle.get_array_length(), 0);
 
    }

    function test_Zero() public{
        vm.expectRevert();
        ProjectRaffle.performUpkeep("");

        (bool isUpkeepNeeded,) = ProjectRaffle.checkUpkeep("");
        assertEq(isUpkeepNeeded, false);

    }

    function test_boundary_cond() public{

// at the exact interval, the player should not be able to enter the raffle, also the state should be cal

        vm.warp(ProjectRaffle.time_of_deploy() + ProjectRaffle.interval()); // edge case
        vm.startPrank(Aadi);
        // vm.expectRevert();
        ProjectRaffle.buy_ticket{value: 0.01 ether}();
        vm.stopPrank();

        // (bool isUpkeepNeeded,) = ProjectRaffle.checkUpkeep("");
        // assertEq(isUpkeepNeeded, false);

        assertEq(ProjectRaffle.get_array_length(), 1);
        assertEq(address(ProjectRaffle).balance, 0.01 ether);







    }    










}

