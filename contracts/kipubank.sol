// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KipuBank
 * @notice A simple bank contract that allows users to deposit and withdraw ETH
 * @dev Implements secure deposit and withdrawal mechanisms with limits
 */
contract KipuBank {
    /// @notice Maximum amount that can be withdrawn in a single transaction
    /// @dev This value is immutable and set during contract deployment
    uint256 public immutable withdrawalLimit;

    /// @notice Maximum total amount that can be deposited in the bank
    /// @dev This value is immutable and set during contract deployment
    uint256 public immutable bankCap;

    /// @notice Current total balance of all deposits in the bank
    uint256 public totalDeposits;

    /// @notice Total number of deposit transactions processed
    uint256 public depositCount;

    /// @notice Total number of withdrawal transactions processed
    uint256 public withdrawalCount;

    /// @notice Mapping of user addresses to their vault balances
    mapping(address => uint256) private userBalances;

    /// @notice Event emitted when a user deposits ETH
    /// @param user Address of the user who made the deposit
    /// @param amount Amount of ETH deposited
    event Deposit(address indexed user, uint256 amount);

    /// @notice Event emitted when a user withdraws ETH
    /// @param user Address of the user who made the withdrawal
    /// @param amount Amount of ETH withdrawn
    event Withdrawal(address indexed user, uint256 amount);

    /// @notice Error thrown when deposit would exceed bank capacity
    error BankCapExceeded(uint256 attempted, uint256 available);

    /// @notice Error thrown when withdrawal amount exceeds the limit
    error WithdrawalLimitExceeded(uint256 requested, uint256 limit);

    /// @notice Error thrown when user tries to withdraw more than their balance
    error InsufficientBalance(uint256 requested, uint256 available);

    /// @notice Error thrown when a transfer fails
    error TransferFailed();

    /// @notice Error thrown when zero amount is provided
    error ZeroAmount();

    /**
     * @notice Constructor to initialize the bank with limits
     * @param _withdrawalLimit Maximum amount that can be withdrawn in a single transaction
     * @param _bankCap Maximum total amount that can be deposited in the bank
     */
    constructor(uint256 _withdrawalLimit, uint256 _bankCap) {
        withdrawalLimit = _withdrawalLimit;
        bankCap = _bankCap;
    }

    /**
     * @notice Modifier to check if an amount is greater than zero
     * @param _amount The amount to check
     */
    modifier nonZeroAmount(uint256 _amount) {
        if (_amount == 0) revert ZeroAmount();
        _;
    }

    /**
     * @notice Allows users to deposit ETH into their personal vault
     * @dev Emits a Deposit event on success
     */
    function deposit() external payable nonZeroAmount(msg.value) {
        // Check if deposit would exceed bank capacity
        if (totalDeposits + msg.value > bankCap) {
            revert BankCapExceeded(msg.value, bankCap - totalDeposits);
        }

        // Update state variables (effects)
        userBalances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        depositCount++;

        // Emit event
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to withdraw ETH from their personal vault
     * @param _amount Amount of ETH to withdraw
     * @dev Follows checks-effects-interactions pattern and emits a Withdrawal event on success
     */
    function withdraw(uint256 _amount) external nonZeroAmount(_amount) {
        // Checks
        if (_amount > withdrawalLimit) {
            revert WithdrawalLimitExceeded(_amount, withdrawalLimit);
        }

        if (_amount > userBalances[msg.sender]) {
            revert InsufficientBalance(_amount, userBalances[msg.sender]);
        }

        // Effects
        userBalances[msg.sender] -= _amount;
        totalDeposits -= _amount;
        withdrawalCount++;

        // Interactions
        (bool success, ) = msg.sender.call{value: _amount}("");
        if (!success) revert TransferFailed();

        // Emit event
        emit Withdrawal(msg.sender, _amount);
    }

    /**
     * @notice Get the balance of a specific user
     * @param _user Address of the user
     * @return The balance of the specified user
     */
    function getBalance(address _user) external view returns (uint256) {
        return userBalances[_user];
    }

    /**
     * @notice Get the available capacity in the bank
     * @return The remaining capacity that can be deposited
     */
    function getAvailableCapacity() external view returns (uint256) {
        return bankCap - totalDeposits;
    }

    /**
     * @notice Private function to validate a user's balance
     * @param _user Address of the user
     * @param _amount Amount to validate against
     * @return True if the user has sufficient balance, false otherwise
     */
    function _hasEnoughBalance(address _user, uint256 _amount) private view returns (bool) {
        return userBalances[_user] >= _amount;
    }
}