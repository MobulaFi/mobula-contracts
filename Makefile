# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

#
#	--- Scripts TESTs ---
#

unit-tests:
	forge test --fork-url ${MAINNET_RPC_URL} -vvv

coverage:
	forge coverage --fork-url ${MAINNET_RPC_URL} -vvv

coverage-report:
	forge coverage --fork-url ${MAINNET_RPC_URL} -vvv --report lcov