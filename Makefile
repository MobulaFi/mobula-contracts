# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

#
#	--- Deployments Scripts ---
#

deploy-tokens-protocol:
	forge script script/polygon/DeployMobulaTokensProtocol.s.sol:DeployMobulaTokensProtocol --rpc-url ${POLYGON_RPC_URL} --broadcast --verify --chain-id 137 --etherscan-api-key ${POLYGONSCAN_API_KEY} -vvvv

deploy-protocol-api:
	forge script script/polygon/DeployProtocolAPI.s.sol:DeployProtocolAPI --rpc-url ${POLYGON_RPC_URL} --broadcast --verify --chain-id 137 --etherscan-api-key ${POLYGONSCAN_API_KEY} -vvvv

deploy-axelar-bnb-sender:
	forge script script/axelar/DeployMobulaCrosschainSender.s.sol:DeployMobulaCrosschainSenderBNB --rpc-url ${BNB_RPC_URL} --broadcast --verify --chain-id 56 --etherscan-api-key ${BSCSCAN_API_KEY} -vvvv

#
#	--- Update Scripts ---
#

update-protocol-api:
	forge script script/polygon/UpdateProtocolAPIAddress.s.sol:UpdateProtocolAPIAddress --rpc-url ${POLYGON_RPC_URL} --broadcast

whitelist-axelar-contracts:
	forge script script/polygon/WhitelistAxelarContracts.s.sol:WhitelistAxelarContracts --rpc-url ${POLYGON_RPC_URL} --broadcast

#
#	--- Scripts Axelar ---
#

script-axelar-bnb-updatetoken:
	forge script script/axelar/MobulaCrosschainSenderCalls.s.sol:MobulaCrosschainSenderUpdateToken --rpc-url ${BNB_RPC_URL} --broadcast -vvvv

script-axelar-bnb-submittoken:
	forge script script/axelar/MobulaCrosschainSenderCalls.s.sol:MobulaCrosschainSenderSubmitToken --rpc-url ${BNB_RPC_URL} --broadcast -vvvv

script-axelar-bnb-topuptoken:
	forge script script/axelar/MobulaCrosschainSenderCalls.s.sol:MobulaCrosschainSenderTopUpToken --rpc-url ${BNB_RPC_URL} --broadcast -vvvv

script-deploy-axelar-bnb-sender:
	forge script script/axelar/DeployMobulaCrosschainSender.s.sol:DeployMobulaCrosschainSenderBNB --rpc-url ${BNB_RPC_URL} --broadcast --verify --chain-id 56 --etherscan-api-key ${BSCSCAN_API_KEY} -vvvv

script-deploy-axelar-polygon-sender:
	forge script script/axelar/DeployMobulaCrosschainSender.s.sol:DeployMobulaCrosschainSenderPolygon --rpc-url ${POLYGON_RPC_URL} --broadcast --verify --chain-id 137 --etherscan-api-key ${POLYGONSCAN_API_KEY} -vvvv

script-deploy-axelar-arbitrum-sender:
	forge script script/axelar/DeployMobulaCrosschainSender.s.sol:DeployMobulaCrosschainSenderArbitrum --rpc-url ${ARBITRUM_RPC_URL} --broadcast --verify --chain-id 42161 --etherscan-api-key ${ARBISCAN_API_KEY} -vvvv

script-deploy-axelar-bnb-receiver:
	forge script script/axelar/DeployAxelarReceiver.s.sol:DeployAxelarReceiverBNB --rpc-url ${BNB_RPC_URL} --broadcast --verify --chain-id 56 --etherscan-api-key ${BSCSCAN_API_KEY} -vvvv

script-deploy-axelar-polygon-receiver:
	forge script script/axelar/DeployAxelarReceiver.s.sol:DeployAxelarReceiverPolygon --rpc-url ${POLYGON_RPC_URL} --legacy --broadcast --verify --chain-id 137 --etherscan-api-key ${POLYGONSCAN_API_KEY} -vvvv

#
#	--- Scripts TESTs ---
#

unit-tests:
	forge test --fork-url ${MAINNET_RPC_URL} -vvv

coverage:
	forge coverage --fork-url ${MAINNET_RPC_URL} -vvv

coverage-report:
	forge coverage --fork-url ${MAINNET_RPC_URL} -vvv --report lcov