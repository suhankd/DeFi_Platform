// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Platform {

    mapping(address => uint) public Balances;

    mapping(address => uint) public Borrower_Payout;
    mapping(address => bool) public isBorrower;
    
    mapping(address => uint) public FixedDeposits;
    mapping(address => uint) public DepositUnlockTime;

    uint public Total_Deposits;
    uint public Total_Borrowed;
    uint public Interest_Rate = 5; 

    event Deposit(address indexed user, uint amount);
    event Withdrawal(address indexed user, uint amount);
    event Borrow(address indexed user, uint amount);
    event Repay(address indexed user, uint amount);
    event Fixed_Deposit(address indexed  user, uint amount, uint Unlock_Time);
    event payout_event(address indexed user, uint amount);

    //Deposit into balance.

    function deposit() external payable {

        require(msg.value > 0);
        Balances[msg.sender] += msg.value;
        Total_Deposits += msg.value;

        emit Deposit(msg.sender, msg.value);

    }

    //Withdraw from balance.

    function withdraw(uint amount) external {

        require(amount > 0);
        require(amount <= Balances[msg.sender]);

        Balances[msg.sender] -= amount;
        Total_Deposits -= amount;
        
        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender,amount);

    }

    //Borrow from collected deposits in contract.

    function borrow(uint amount) external {

        require(amount > 0);
        require(amount <= Total_Deposits-Total_Borrowed);
        require(!isBorrower[msg.sender]);

        Borrower_Payout[msg.sender] += amount+(amount*Interest_Rate/100);
        isBorrower[msg.sender] = true;
        Total_Borrowed += amount;

        payable(msg.sender).transfer(amount);

        emit Borrow(msg.sender, amount);

    }

    //Repay borrowed amount.

    function repay() external payable {

        require(msg.value > 0);
        require(isBorrower[msg.sender]);
        require(msg.value <= Borrower_Payout[msg.sender]);

        Total_Borrowed -= msg.value;
        Borrower_Payout[msg.sender] -= msg.value;

        if(Borrower_Payout[msg.sender] == 0){

            isBorrower[msg.sender] = false;
            delete Borrower_Payout[msg.sender];

        }

        emit Repay(msg.sender,msg.value);

    }

    //Check current balance.

    function check_balance() external view returns(uint) {

        return Balances[msg.sender];

    }

    //A fixed-deposit function, i.e. the user is unable to withdraw the deposit for a period of time, in exchange for a payout of the deposit, plus interest.
    //The interest is linear, with the maximum being 25%, and the minimum being 2.5%.

    function fixed_deposit(uint duration) external payable {

        require(msg.value > 0);
        require(duration > 365);
        require(duration < 3650);

        uint unlockTime = block.timestamp + duration;
        uint Payout = payout(msg.value, duration); 
        FixedDeposits[msg.sender] += Payout;
        DepositUnlockTime[msg.sender] = unlockTime;
        emit Fixed_Deposit(msg.sender, msg.value, unlockTime);

    }

    //Payout occurs when user calls this function.

    function payout_df() external {

        if(block.timestamp >= DepositUnlockTime[msg.sender]){

            Balances[msg.sender] += FixedDeposits[msg.sender];
            emit payout_event(msg.sender, FixedDeposits[msg.sender]);
            
            delete FixedDeposits[msg.sender];
            delete DepositUnlockTime[msg.sender];
            
        }

    }

    function payout(uint principal, uint duration) public pure returns(uint){

        uint Payout = principal * (1 + (25 * duration)/100/3650);
        return Payout;

    }
}