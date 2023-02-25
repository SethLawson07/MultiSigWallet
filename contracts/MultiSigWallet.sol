// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

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
    event ExecuteTransaction(address indexed owner,uint txIndex);
    event Deposit(address indexed sender, uint amount, uint balance);

    address public deployer;
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
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
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
        deployer=msg.sender;       
    }

    receive() external payable{
        emit Deposit(msg.sender,msg.value,address(this).balance);        
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) external payable onlyOwner{
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

    function executeTransaction(
            uint _txIndex
        ) external onlyOwner txExists(_txIndex) notExecuted( _txIndex)  {
            Transaction storage transaction = transactions[_txIndex];
 
            require(transaction.numConfirmations >= required,"cannot execute tx");
            (bool success, ) = transaction.to.call{value: transaction.value}(
                transaction.data
            );   
            require(success, "tx failed");
            transaction.executed=true;
            
            emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeTransaction(
        uint _txIndex
        ) external onlyOwner txExists(_txIndex) notExecuted( _txIndex)  {
            Transaction storage transaction = transactions[_txIndex];

            require(isConfirmed[_txIndex][msg.sender],"tx not confirmed");

            transaction.numConfirmations-=1;
            isConfirmed[_txIndex][msg.sender]=false;

            emit RevokeTransaction(msg.sender, _txIndex);

        }

    function getOwners() external view returns(address [] memory){
        return owners;
    }

    function getTransactionCount() external view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint _txIndex
        ) external view returns(
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
    ){

        Transaction storage transaction = transactions[_txIndex];

        return(
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations

        );
    }

    function getBalance(address _address) external view returns(uint256){
        return address(_address).balance;
    }

}