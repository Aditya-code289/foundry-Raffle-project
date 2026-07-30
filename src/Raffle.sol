//SPDX License-Identifier: MIT;
pragma solidity ^0.8.35;

// import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

error ticket_price_is_more(); 
error payment_failed();
error Raffle_is_closed();
error deadline_is_passed();

contract project_raffle is VRFConsumerBaseV2Plus{

    enum RaffleState{   
        Open, //0
        Calculating   //1
    } 

    uint256 public winner_index;

    address payable public winner;

    uint public immutable ticket_price;
    
    address payable[] public store_players ;
    
    uint public immutable interval; 
    
    uint public immutable time_of_deploy; 
    
    uint256 public requestId;


    IVRFCoordinatorV2Plus private immutable vrfCoordinator;

    bytes32 private immutable keyhash;  

    uint256 private immutable subsId;

    uint32 private immutable gas_limit;

    uint8 public constant req_conf = 3;
    uint8 public constant num_words = 1;

    RaffleState public raffle_state;


    event new_players(
        address indexed player
    ); 
   
    event winner_decided(
        address indexed winner
    );   

    constructor(uint set_price,
                uint i_interval, 
                address i_vrf_coordinator,
                bytes32 i_keyhash,
                uint256 i_subsId,
                uint32 i_gas_limit)
                VRFConsumerBaseV2Plus(i_vrf_coordinator)

    {
        ticket_price = set_price;
        interval = i_interval;
        vrfCoordinator = IVRFCoordinatorV2Plus(i_vrf_coordinator);
        keyhash = i_keyhash;
        subsId = i_subsId;
        gas_limit = i_gas_limit;
        time_of_deploy = block.timestamp;
        raffle_state = RaffleState.Open; 
    }


    function buy_ticket() external payable{ 

        (bool isupkeepneeded,) = checkUpkeep("");
        
        if(msg.value < ticket_price){
            revert ticket_price_is_more();
        }
        
        if(raffle_state != RaffleState.Open){
            revert Raffle_is_closed();
        }

        if (isupkeepneeded){
            revert deadline_is_passed();
        }

        store_players.push(payable(msg.sender)); 

        emit new_players(msg.sender); 
    } 


    function checkUpkeep(bytes memory /* checkData*/) 
            public view returns (bool upKeepNeeded, bytes memory /* checkdata */)
            {
                // we will write 5 conditions which should be true to proceed further 

                bool istimePassed = interval <= (block.timestamp - time_of_deploy);
                bool isPlayers = (store_players.length) > 0;
                bool isBalance = address(this).balance >0;
                bool isRaffleOpen = raffle_state == RaffleState.Open;

                upKeepNeeded = (istimePassed && isPlayers && isBalance && isRaffleOpen );

                return (upKeepNeeded, "0x0");
        }


    function performUpkeep (bytes memory /* performdata*/) external { 
        
        (bool isUpkeepNeeded,) = checkUpkeep("");

        if(!isUpkeepNeeded){
            revert();
        }
        // Now when deadline is reached we want the raffle state to be at 1;

        raffle_state = RaffleState.Calculating;

        // ELSE: Now we need to generate a random number 

       requestId = vrfCoordinator.requestRandomWords(
    VRFV2PlusClient.RandomWordsRequest({
        keyHash: keyhash,
        subId: subsId,
        requestConfirmations: req_conf,
        callbackGasLimit: gas_limit,
        numWords: num_words,
        extraArgs: VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({
                nativePayment: false
            })
        )
    })
);

    }


    function fulfillRandomWords(
        uint256 requestID,
        uint256[] calldata randomWords
    ) internal override{

        winner_index = randomWords[0] % (store_players.length);
        winner = store_players[winner_index];

        store_players = new address payable[](0);  
        
        emit winner_decided(winner);
    

        (bool success,) = payable(winner).call{value:address(this).balance}("");

        if(success != true){
            revert payment_failed();
        }
    }
    





    function get_array_length() external view returns(uint){
        return store_players.length;
    }


    // function get_ticket_price() external view returns(uint){
    //     return ticket_price;
    // }

    function get_player_address(uint index) public view returns(address){
        return store_players[index];
    }

}