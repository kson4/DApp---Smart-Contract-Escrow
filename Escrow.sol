// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Escrow {
    
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, CONFIRMED_DELIVERY, COMPLETE, DISPUTE }
    
    State public currState;
    
    address payable buyer;
    address payable seller;
    address public arbitrator;
    uint256 amount;

    // custom modifiers that will be called before the other functions
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can call this method");
        _;
    }
    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can call this method");
        _;
    }
    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Only the arbitrator can call this method");
        _;
    }

    // constructor function must be declared to deploy smart contracts
    constructor(address payable _buyer, address payable _seller, address _arbitrator, uint256 _amount) {
        buyer = _buyer;
        seller = _seller;
        arbitrator = _arbitrator;
        amount = _amount;
    }

    function getState() public view returns (string memory) {
        if (currState == State.AWAITING_PAYMENT) return "Awaiting Payment";
        if (currState == State.AWAITING_DELIVERY) return "Awaiting Delivery";
        if (currState == State.CONFIRMED_DELIVERY) return "Confirmed Delivery";
        if (currState == State.COMPLETE) return "Complete";
        if (currState == State.DISPUTE) return "Dispute";
    }
    function getAmount() public view returns (uint256) {
        return amount;
    }
    function getParties() public view returns (address payable, address payable, address) {
        return (buyer, seller, arbitrator);
    }

    function deposit() onlyBuyer external payable {
        require(currState == State.AWAITING_PAYMENT, "Already paid in full");
        if (address(this).balance == amount) {
            currState = State.AWAITING_DELIVERY;
        }
    }
    function confirmDelivery() onlyBuyer external {
        require(currState == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        currState = State.CONFIRMED_DELIVERY;
    }
    function dispute() onlyBuyer external {
        currState = State.DISPUTE;
    }

    function withdraw() onlySeller external {
        require(currState == State.CONFIRMED_DELIVERY, "Cannot withdraw funds");
        seller.transfer(address(this).balance);
        currState = State.COMPLETE;
    }
    function refund() onlySeller external {
        buyer.transfer(address(this).balance);
        currState = State.COMPLETE;
    }

    function awardDispute() onlyArbitrator external {
        require(currState == State.DISPUTE, "Transaction is not in dispute");
        buyer.transfer(address(this).balance);
        currState = State.COMPLETE;
    }
    function declineDispute() onlyArbitrator external {
        require(currState == State.DISPUTE, "Transaction is not in dispute");
        seller.transfer(address(this).balance);
        currState = State.COMPLETE;
    }
}
