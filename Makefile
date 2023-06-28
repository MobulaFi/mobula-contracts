# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env


#
#	--- Scripts Axelar ---
#

script-axelar-sendtomany:
	forge script script/AxelarSendToMany.s.sol:AxelarSendToMany --rpc-url ${ARBITRUM_RPC_URL} --broadcast -vvvv

script-deploy-axelar-sender:
	forge script script/DeployAxelarSender.s.sol:DeployAxelarSender --rpc-url ${ARBITRUM_RPC_URL} --broadcast --verify --chain-id 42161 --etherscan-api-key ${ARBISCAN_API_KEY} -vvvv

script-deploy-axelar-receiver:
	forge script script/DeployAxelarReceiver.s.sol:DeployAxelarReceiver --rpc-url ${BNB_RPC_URL} --broadcast --verify --chain-id 56 --etherscan-api-key ${BSCSCAN_API_KEY} -vvvv

#
#	--- Scripts TESTs ---
#

unit-tests:
	forge test --fork-url ${MAINNET_RPC_URL} -vvv

coverage:
	forge coverage --fork-url ${MAINNET_RPC_URL} -vvv

coverage-report:
	forge coverage --fork-url ${MAINNET_RPC_URL} -vvv --report lcov