-include .env

.PHONY: all test clean deploy deploy-sepolia fund help install snapshot format anvil

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

clean: ; forge clean

remove: ; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:
	rm -rf lib/forge-std lib/openzeppelin-contracts
	forge install foundry-rs/forge-std@v1.8.2 --no-git
	forge install OpenZeppelin/openzeppelin-contracts@v5.6.1 --no-git
	forge installCyfrin/foundry-devops@v0.4.0 --no-git

update: ; forge update
build: ; forge build
test: ; forge test
snapshot: ; forge snapshot
format: ; forge fmt

anvil:
	anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployBasicNft.s.sol:DeployBasicNft $(NETWORK_ARGS)

deploy-sepolia:
	@forge script script/DeployBasicNft.s.sol:DeployBasicNft --rpc-url $(SEPOLIA_RPC_URL) \
	--account mySepoliaAccount --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deployDynamicNft:
	@forge script script/DeployDynamicNft.s.sol:DeployDynamicNft $(NETWORK_ARGS)

mint:
	cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "mintNft()" --private-key $(LOC_PRIVATE_KEY) --rpc-url $(LOC_RPC_URL)

change-color:
	cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "changeColor(uint256)" 0 --private-key $(LOC_PRIVATE_KEY) --rpc-url $(LOC_RPC_URL)
