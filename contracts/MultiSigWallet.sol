// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

contract MultiSigWallet {

    event SubmitTransaction(
        address indexed owner,
        address indexed to,
        uint value,
        uint txIndex,
        bytes data
        
    
    );

    event ConfirmTransaction(address indexed owner,uint txIndex);
    event RevokeTransaction(address indexed owner,uint txIndex);

    address [] public owners;
    mapping (address => bool) public isOwner;
    uint public required;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    Transaction [] public transactions;
    mapping (uint => mapping (address => bool) ) isConfirmed;

    modifier onlyOwner() {
        require(isOwner[msg.sender],"not owner");
        _;
    }

    modifier txExists(uint _txIndex)  {
        require(transactions[_txIndex],"tx does not exists");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed,"tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender],"tx already confirmed");
        _;
    }
    
    constructor(address [] memory _owners,uint _required) {
        require(_owners.length>0,"owners required");
        require(_required>0 && _required<_owners.length,"invalid number of required confirmations");
        
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner!=address(0),"invalid owner");
            require(!isOwner[owner],"owner not unique");

            isOwner[owner]=true;
            owners.push(owner);
        }
        required=_required;
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner{
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to:_to,
                value: _value,
                data: _data, 
                executed: false, 
                numConfirmations:0
            })
        );

        emit SubmitTransaction(msg.sender,_to,_value,txIndex,_data);
    

    }

    function confirmTransaction(
        uint _txIndex
        ) public onlyOwner txExists(_txIndex) notExecuted( _txIndex) notConfirmed( _txIndex) {
            Transaction storage transaction = transactions[_txIndex];
            transaction.numConfirmations+=1;
            isConfirmed[_txIndex][msg.sender]=true;

            emit ConfirmTransaction(msg.sender, _txIndex);

        }

     function revokeTransaction(
        uint _txIndex
        ) public onlyOwner txExists(_txIndex) notExecuted( _txIndex)  {
            Transaction storage transaction = transactions[_txIndex];

            require(isConfirmed[_txIndex][msg.sender],"tx not confirmed");

            transaction.numConfirmations-=1;
            isConfirmed[_txIndex][msg.sender]=false;

            emit RevokeTransaction(msg.sender, _txIndex);

        }

}