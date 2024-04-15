// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Interfaces.
import './interfaces/IProtocolSettings.sol';

// Inheritance.
import './interfaces/IUserSettings.sol';

contract UserSettings is IUserSettings {
    IProtocolSettings public immutable protocolSettings;

    mapping (address => uint256) public override minimumTimeUntilDiscountStarts;
    mapping (address => uint256) public override timeUntilMaxDiscount;
    mapping (address => uint256) public override maximumDiscount;

    constructor(address _protocolSettings) {
        protocolSettings = IProtocolSettings(_protocolSettings);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Registers a user with the given values for the user's settings.
    * @dev This transaction will revert if the user has already been registered.
    */
    function registerUser(uint256 _minimumTimeUntilDiscountStarts, uint256 _timeUntilMaxDiscount, uint256 _maximumDiscount) external override {
        require(minimumTimeUntilDiscountStarts[msg.sender] == 0, "UserSettings: User is already registered.");
        require(_minimumTimeUntilDiscountStarts >= protocolSettings.minimumMinimumTimeUntilDiscountStarts()
                && _minimumTimeUntilDiscountStarts <= protocolSettings.maximumMinimumTimeUntilDiscountStarts(),
                "UserSettings: Minimum time until discount starts is out of range.");
        require(_timeUntilMaxDiscount >= protocolSettings.minimumTimeUntilMaxDiscount()
                && _timeUntilMaxDiscount <= protocolSettings.maximumTimeUntilMaxDiscount(),
                "UserSettings: Time until max discount is out of range.");
        require(_maximumDiscount <= protocolSettings.maxDiscount()
                && _maximumDiscount > 0,
                "UserSettings: Maximum discount is out of range.");

        minimumTimeUntilDiscountStarts[msg.sender] = _minimumTimeUntilDiscountStarts;
        timeUntilMaxDiscount[msg.sender] = _timeUntilMaxDiscount;
        maximumDiscount[msg.sender] = _maximumDiscount;
        
        emit RegisteredUser(msg.sender, _minimumTimeUntilDiscountStarts, _timeUntilMaxDiscount, _maximumDiscount);
    }

    /**
    * @notice Sets the user's minimumTimeUntilDiscountStarts to the given value.
    */
    function updateMinimumTimeUntilDiscountStarts(uint256 _newValue) external override {
        require(_newValue >= protocolSettings.minimumMinimumTimeUntilDiscountStarts()
                && _newValue <= protocolSettings.maximumMinimumTimeUntilDiscountStarts(),
                "UserSettings: Minimum time until discount starts is out of range.");

        uint256 oldValue = minimumTimeUntilDiscountStarts[msg.sender];
        minimumTimeUntilDiscountStarts[msg.sender] = _newValue;

        emit UpdateMinimumTimeUntilDiscountStarts(msg.sender, oldValue, _newValue);
    }

    /**
    * @notice Sets the user's timeUntilMaxDiscount to the given value.
    */
    function updateTimeUntilMaxDiscount(uint256 _newValue) external override {
        require(_newValue >= protocolSettings.minimumTimeUntilMaxDiscount()
                && _newValue <= protocolSettings.maximumTimeUntilMaxDiscount(),
                "UserSettings: Time until max discount is out of range.");

        uint256 oldValue = timeUntilMaxDiscount[msg.sender];
        timeUntilMaxDiscount[msg.sender] = _newValue;

        emit UpdateTimeUntilMaxDiscount(msg.sender, oldValue, _newValue);
    }

    /**
    * @notice Sets the user's maximumDiscount to the given value.
    */
    function updateMaximumDiscount(uint256 _newValue) external override {
        require(_newValue <= protocolSettings.maxDiscount()
                && _newValue > 0,
                "UserSettings: Maximum discount is out of range.");

        uint256 oldValue = maximumDiscount[msg.sender];
        maximumDiscount[msg.sender] = _newValue;

        emit UpdateMaximumDiscount(msg.sender, oldValue, _newValue);
    }

    /* ========== EVENTS ========== */

    event RegisteredUser(address user, uint256 minimumTimeUntilDiscountStarts, uint256 timeUntilMaxDiscount, uint256 maximumDiscount);
    event UpdateMinimumTimeUntilDiscountStarts(address user, uint256 oldValue, uint256 newValue);
    event UpdateTimeUntilMaxDiscount(address user, uint256 oldValue, uint256 newValue);
    event UpdateMaximumDiscount(address user, uint256 oldValue, uint256 newValue);
}