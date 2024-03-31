// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/**
 * @title A library for mathematical calculations.
 */
library TradegenMath {
    /**
    * @dev Scales a value based on the ratio of time elapsed to period duration.
    * @dev scalar = (currentTimestamp - startTimestamp) / duration
    * @dev x = (currentValue * scalar) + (previousValue * (1 - scalar))
    * @param currentValue value of a metric for the current period.
    * @param previousValue value of a metric for the previous period.
    * @param currentTimestamp the current timestamp; most likely "block.timestamp".
    * @param startTimestamp the timestamp at the start of the current period.
    * @param duration length of the period.
    * @return time-scaled value.
    */
    function scaleByTime(uint256 currentValue, uint256 previousValue, uint256 currentTimestamp, uint256 startTimestamp, uint256 duration) internal pure returns (uint256) {
        // Prevent division by 0.
        if (duration == 0) {
            return 0;
        }

        // Prevent underflow.
        if (startTimestamp > currentTimestamp) {
            return 0;
        }

        // Prevent underflow.
        if (duration + startTimestamp < currentTimestamp) {
            return 0;
        }

        return ((currentValue * (currentTimestamp - startTimestamp)) + (previousValue * (duration + startTimestamp - currentTimestamp))) / duration;
    }
}