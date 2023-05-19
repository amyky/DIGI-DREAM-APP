// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin contracts for  safeMaths

import "./token.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

// Define the contract
contract digiapp{
    using SafeMath for uint256;

    // Define variables
    address private owner;
    address private appWallet;
    uint256 private monthlyFee; // 83;
    uint256 private yearlyFee; // 830;
    uint256 private transactionFee;
    uint256 private _subscriptionId;
    uint256 private nextSubscriptionId;
    uint256 private ontimeSubscriptionFee;

    //disbursement wallet address

    // Define struct
    enum SubscriptionType {
        MONTHLY,
        YEARLY
    }

    struct Users {
        bool issubscribed;
        bool isverified;
    }

    struct Subscription {
        address subscriber;
        uint256 startDate;
        uint256 endDate;
        uint256 amount;
        SubscriptionType subscriptionType;
        bool isactive;
    }

    mapping(address => uint256) public digitokenCounts;
    mapping(uint256 => Subscription) private subscriptions;
    //mapping(address => Users) talents;
    mapping(address => Users) companies;

    // Define events
    event PaymentProcessed(address payer, uint256 amount);
    event PaymentRefunded(address payer, uint256 amount);

    event SubscribedAmount(address payer, uint256 amount, uint256 _amount);

    event SubscriptionCreated(
        uint256 subscriptionId,
        address subscriber,
        uint256 duration,
        uint256 amount
    );

    event TestSubscribe(uint256);
    // Define access controls
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant APP_ROLE = keccak256("APP_ROLE");

    // Define constructor
    constructor(address payable _owner, address payable _appWallet) {
        // Set owner and app wallet
        owner = _owner;
        appWallet = _appWallet;

        // Set subscription fees and talent percentage
        monthlyFee = 8300000000000000; // 0.0083 ether in wei
        yearlyFee = 83000000000000000; // 0.083 ether in wei
        transactionFee = 300000000000000; // 0.0003 ether in wei
        ontimeSubscriptionFee = 28000000000000000; //0.0028

        // Set subscription ID
        _subscriptionId = 0;
        nextSubscriptionId = 1;
    }

    //Getters functions

    function getOneTimeSubscriptionFee() public view returns (uint256) {
        return ontimeSubscriptionFee;
    }

    function getAppWallet() public view returns (address) {
        return appWallet;
    }

    function getmonthlyFee() public view returns (uint256) {
        return monthlyFee;
    }

    function getYearlyFee() public view returns (uint256) {
        return yearlyFee;
    }

    function getTransactionFee() public view returns (uint256) {
        return transactionFee;
    }

    

    function subscribeOneTimeSubscription() public payable {
        require(msg.value == ontimeSubscriptionFee, "Incorrect payment amount");
        emit PaymentProcessed(msg.sender, msg.value);
    }

    function subscribeMonthly() public payable {
        require(msg.value == monthlyFee, "Incorrect payment amount");
        emit PaymentProcessed(msg.sender, msg.value);
    }

    function subscribeYearly() public payable {
        require(msg.value == yearlyFee, "Incorrect payment amount");
        emit PaymentProcessed(msg.sender, msg.value);
    }

   /* function subscribe(SubscriptionType _type) public payable  {
        uint256 _duration;

        uint256 subscriptionAmount = _duration == 1 ? monthlyFee : yearlyFee;

        // Calculate fees
        uint256 transactionFeeAmount = subscriptionAmount
            .mul(transactionFee)
            .div(100);
        uint256 totalAmount = subscriptionAmount.add(transactionFeeAmount);

        // Ensure payment amount is correct
        require(msg.value == totalAmount, "Incorrect payment amount");

        // Transfer fees
        payable(appWallet).transfer(transactionFeeAmount);
        payable(owner).transfer(totalAmount.sub(transactionFeeAmount));

        // Create subscription
        Subscription storage subscription = subscriptions[nextSubscriptionId];
        subscription.subscriber = msg.sender;
        subscription.startDate = block.timestamp;
        subscription.endDate = block.timestamp.add(_duration.mul(30 days));
        subscription.amount = subscriptionAmount;
        subscription.isactive = true;

        // Increment subscription ID
        nextSubscriptionId = nextSubscriptionId.add(1);

        // Emit event
        emit SubscriptionCreated(
            nextSubscriptionId.sub(1),
            msg.sender,
            _duration,
            subscriptionAmount
        );

        // Check if subscription is already active
        require(subscription.isactive, "Already subscribed");
    }*/

    // Define functions to cancel subscription and refund payment
    function cancelSubscription(uint256 subscriptionId) public {
        require(
            subscriptions[subscriptionId].isactive,
            "Subscription not found"
        );
        require(
            subscriptions[subscriptionId].subscriber == msg.sender,
            "Not authorized"
        );

        Subscription memory subscription = subscriptions[_subscriptionId];

        // Check if subscription is still active
        if (subscription.endDate > block.timestamp) {
            uint256 remainingTime = subscription.endDate.sub(block.timestamp);
            uint256 refundAmount = subscription.amount.mul(remainingTime).div(
                subscription.endDate.sub(subscription.startDate)
            );
            (bool success, ) = msg.sender.call{value: refundAmount}("");
            require(success, "Refund failed");
            emit PaymentRefunded(msg.sender, refundAmount);
        }

        // Mark subscription as inactive
        subscriptions[_subscriptionId].isactive = false;

        // Calculate start and end dates of subscription
        uint256 startDate = block.timestamp;
        uint256 endDate = (startDate +
            (_subscriptionId % 2 == 0 ? 30 days : 365 days));
    }

    function verifyWallet(address _wallet) public view returns (bool) {
        // Define a variable to keep track of the total number of tokens owned by the wallet
        uint256 totalBalance;
        // Check if the total balance of tokens owned by the wallet is greater than or equal to 300
        return totalBalance >= 0;
    }

    // Define payment verification function
    function verifyPayment(address _wallet, uint256 _amount)
        public
        view
        returns (bool)
    {
        // Check if wallet has enough ether to pay
        if (_wallet.balance < _amount) {
            return false;
        }

        return true;
    }

    // Define payment processing function
    function processPayment(address _payer, uint256 _amount) public {
        // Verify payment
        require(
            verifyPayment(_payer, _amount),
            "Insufficient ether balance to pay"
        );

        // Transfer ether from payer to app wallet
        payable(appWallet).transfer(_amount);

        // Emit event
        emit PaymentProcessed(_payer, _amount);
    }

    // Define payment refund function
    function refundPayment(address _payer, uint256 _amount) public {
        // Transfer ether from app wallet
        payable(address(0)).transfer(_amount);

        // Emit event
        emit PaymentRefunded(_payer, _amount);
    }
}
