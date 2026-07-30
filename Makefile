include .env 
export 

deploy:
	forge script script/deploy_raffle.s.sol:deploy_raffle \
	--rpc-url $$SEPOLIA_RPC_URL \
	--private-key $$SEPOLIA_PRV_KEY \
	--broadcast 	

ContrAddr:= $(shell jq -r '.transactions[-1].contractAddress' broadcast/deploy_raffle.s.sol/11155111/run-latest.json)

buy_1 : 
	cast send $(ContrAddr) \
	"buy_ticket()" \
	--value 2000000000000000 \
	--rpc-url $$SEPOLIA_RPC_URL \
	--private-key $$SEPOLIA_PRV_KEY 

buy_2 : 
	cast send $(ContrAddr) \
	"buy_ticket()" \
	--value 2000000000000000 \
	--rpc-url $$SEPOLIA_RPC_URL \
	--private-key $$SEPOLIA_PRV_KEY_2 

buy_3 : 
	cast send $(ContrAddr) \
	"buy_ticket()" \
	--value 2000000000000000 \
	--rpc-url $$SEPOLIA_RPC_URL \
	--private-key $$SEPOLIA_PRV_KEY_3

buy_4 : 
	cast send $(ContrAddr) \
	"buy_ticket()" \
	--value 2000000000000001 \
	--rpc-url $$SEPOLIA_RPC_URL \
	--private-key $$SEPOLIA_PRV_KEY_4

checkUp:
	cast call $(ContrAddr) \
	"checkUpkeep(bytes)(bool,bytes)" \
	0x \
	--rpc-url $$SEPOLIA_RPC_URL 

performUp: 
	cast send $(ContrAddr) \
	"performUpkeep(bytes)" \
	0x \
	--rpc-url $$SEPOLIA_RPC_URL \
	--private-key $$SEPOLIA_PRV_KEY 
	
balance: 
	cast balance $(ContrAddr) \
	--rpc-url $$SEPOLIA_RPC_URL 

winner_index:
	cast call $(ContrAddr) \
	"winner_index()(uint)" \
	--rpc-url $$SEPOLIA_RPC_URL 

winner:
	cast call $(ContrAddr) \
	"winner()(address)" \
	--rpc-url $$SEPOLIA_RPC_URL 





