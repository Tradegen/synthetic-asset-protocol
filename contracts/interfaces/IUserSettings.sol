// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IUserSettings {
    /**
    * @notice Returns the minimum amount of time after the user's order has been placed until the order can be filled at a discount.
    */
    function minimumTimeUntilDiscountStarts(address _user) external view returns (uint256);

    /**
    * @notice Returns the amount of time after minimumTimeUntilDiscountStarts until the discount reaches the user's maximum discount.
    */
    function timeUntilMaxDiscount(address _user) external view returns (uint256);

    /**
    * @notice Returns the maximum discount at which the user's order can be filled.
    */
    function maximumDiscount(address _user) external view returns (uint256);

    /**
    * @notice Returns the starting discount at which the user's order can be filled.
    * @dev The discount increases linearly to maximumDiscount over timeUntilMaxDiscount.
    */
    function startingDiscount(address _user) external view returns (uint256);

    /**
    * @notice Registers a user with the given values for the user's settings.
    * @dev This transaction will revert if the user has already been registered.
    */
    function registerUser(uint256 _minimumTimeUntilDiscountStarts, uint256 _timeUntilMaxDiscount, uint256 _maximumDiscount, uint256 _startingDiscount) external;

    /**
    * @notice Sets the user's minimumTimeUntilDiscountStarts to the given value.
    */
    function updateMinimumTimeUntilDiscountStarts(uint256 _newValue) external;

    /**
    * @notice Sets the user's timeUntilMaxDiscount to the given value.
    */
    function updateTimeUntilMaxDiscount(uint256 _newValue) external;

    /**
    * @notice Sets the user's maximumDiscount to the given value.
    */
    function updateMaximumDiscount(uint256 _newValue) external;

    /**
    * @notice Sets the user's startingDiscount to the given value.
    */
    function updateStartingDiscount(uint256 _newValue) external;
}