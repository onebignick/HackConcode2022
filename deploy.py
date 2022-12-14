# file to deploy db.sol to the blockchain
import json
from web3 import Web3
from pathlib import Path
from solcx import compile_standard, install_solc
from web3.middleware import geth_poa_middleware
import wallet_details

p = Path(__file__).with_name("db.sol")

with p.open("r") as file:
    db_file = file.read()

print("Installing...")
install_solc("0.8.7")
print("py-solcx installed!")

# Solidity source code
compiled_sol = compile_standard(
    {
        "language": "Solidity",
        "sources": {"db.sol": {"content": db_file}},
        "settings": {
            "outputSelection": {
                "*": {
                    "*": ["abi", "metadata", "evm.bytecode", "evm.bytecode.sourceMap"]
                }
            }
        },
    },
    solc_version="0.8.7",
)

# with open("./project/welcome/compiled_code.json", "w") as file:
#    json.dump(compiled_sol, file)

# Bytecode
users_bytecode = compiled_sol["contracts"]["db.sol"]["Users"]["evm"]["bytecode"][
    "object"
]
session_bytecode = compiled_sol["contracts"]["db.sol"]["Session"]["evm"]["bytecode"][
    "object"
]
appointment_bytecode = compiled_sol["contracts"]["db.sol"]["Appointment"]["evm"][
    "bytecode"
]["object"]


# Abi
users_abi = json.loads(compiled_sol["contracts"]["db.sol"]["Users"]["metadata"])[
    "output"
]["abi"]
session_abi = json.loads(compiled_sol["contracts"]["db.sol"]["Session"]["metadata"])[
    "output"
]["abi"]
appointment_abi = json.loads(
    compiled_sol["contracts"]["db.sol"]["Appointment"]["metadata"]
)["output"]["abi"]
# For connecting to Sepolia
# w3 = Web3(Web3.HTTPProvider("https://rpc.sepolia.dev"))
# chain_id = 11155111

# For connecting to ganache
w3 = Web3(Web3.HTTPProvider("HTTP://127.0.0.1:7545"))
chain_id = 1337

if chain_id == 11155111:  # Sepolia chain ID is 11155111
    w3.middleware_onion.inject(geth_poa_middleware, layer=0)
    print(w3.clientVersion)

my_address = wallet_details.my_address
private_key = wallet_details.private_key

# Creating the users contract in python
db = w3.eth.contract(abi=users_abi, bytecode=users_bytecode)
# Get the latest transaction
nonce = w3.eth.getTransactionCount(my_address)
# Submit the transation that deploys the contract
transaction = db.constructor().buildTransaction(
    {
        "chainId": chain_id,
        "gasPrice": w3.eth.gas_price,
        "from": my_address,
        "nonce": nonce,
    }
)

# Signing the transaction
signed_txn = w3.eth.account.sign_transaction(transaction, private_key=private_key)
print("Deploying Contract!")
# Sending txn
tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
# Wait for the transaction to be mined, and get the transaction receipt
print("Waiting for transaction to finish...")
tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
print(f"Done! Contract deployed to {tx_receipt.contractAddress}")

data = {
    "contract_address": tx_receipt.contractAddress,
    "users_abi": users_abi,
    "users_bytecode": users_bytecode,
    "session_abi": session_abi,
    "session_bytecode": session_bytecode,
    "appointment_abi": appointment_abi,
    "appointment_bytecode": appointment_bytecode,
}

with open("data.json", "w") as f:
    json.dump(data, f, ensure_ascii=False)
