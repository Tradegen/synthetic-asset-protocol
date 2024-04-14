// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";
import './openzeppelin-solidity/contracts/ERC20/SafeERC20.sol';
import './openzeppelin-solidity/contracts/ERC20/IERC20.sol';
import "./openzeppelin-solidity/contracts/SafeMath.sol";

// Interfaces.
import './interfaces/IOracle.sol';
import './interfaces/IProtocolSettings.sol';

// Libraries.
import "./libraries/TradegenMath.sol";
import "./libraries/Strings.sol";

// Inheritance.
import './interfaces/IOrderbook.sol';

contract Orderbook is IOrderbook, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct CancelledOrder {
        uint256 amountCancelled;
        uint256 timestamp;
        uint256 previous;
        uint256 next;
    }

    struct LookupValue {
        bool isLastDigit;
        uint8 previousDigit;
    }

    struct FilledOrder {
        uint256 numberOfTokensFilled;
        uint256 executionPrice;
        uint256 timestamp;
        uint256 previous;
        uint256 next;
    }

    address public immutable router;
    IOracle public immutable oracle;
    IProtocolSettings public immutable protocolSettings;
    IERC20 public immutable stablecoin;

    address public immutable syntheticAsset;
    bool public immutable representsBuyOrders;

    bool public tradingIsPaused;

    uint256 public numberOfOrders;
    uint256 public end;
    uint256 public current;
    uint256 public lastFilledOrderKey;

    // (order index => user address).
    mapping (uint256 => address) public orderIndexToUser;
    // (user address => order index).
    mapping (address => uint256) public userToOrderIndex;

    // Used to get the nearest index in the cancelled order ledger to a given index.
    // Keys are in the format "<magnitude>/<prefix>/<metadata/digit>".
    mapping (string => LookupValue) public cancelledOrderLookup;

    // Keys represent order index.
    mapping (uint256 => CancelledOrder) public cancelledOrders;

    // (order index => value of 'current' at which the order will be considered 'filled').
    // Starts at index 1.
    mapping (uint256 => uint256) public orders;

    // Used to get the nearest index in the filled order ledger to a given index.
    // Keys are in the format "<magnitude>/<prefix>/<metadata/digit>".
    mapping (string => LookupValue) public filledOrderLookup;

    // Keys represent the new value of 'current' at the time the order was filled.
    mapping (uint256 => FilledOrder) public filledOrders;

    constructor(address _router, address _oracle, address _protocolSettings, address _stablecoin, address _syntheticAsset, bool _representsBuyOrders) Ownable() {
        router = _router;
        oracle = IOracle(_oracle);
        protocolSettings = IProtocolSettings(_protocolSettings);
        stablecoin = IERC20(_stablecoin);
        syntheticAsset = _syntheticAsset;
        representsBuyOrders = _representsBuyOrders;
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the info for the order at the given index.
    * @param _orderIndex Index of the order.
    * @return uint256, uint256, uint256, uint256 The order size, number of tokens filled, execution price, and timestamp at which the order was filled.
    */
    function getOrderInfo(uint256 _orderIndex) public view override returns (uint256, uint256, uint256, uint256) {
        if (_orderIndex == 0 || _orderIndex > numberOfOrders) {
            return (0, 0, 0, 0);
        }

        FilledOrder memory filledOrder = filledOrders[_orderIndex];
        uint256 orderSize = orders[_orderIndex].sub(orders[_orderIndex.sub(1)]);

        return (orderSize, filledOrder.numberOfTokensFilled, filledOrder.executionPrice, filledOrder.timestamp);
    }

    /**
    * @notice Returns the order info for the given user's pending order.
    * @dev Returns (0, 0, 0, 0) if the user does not have an order.
    * @param _user Address of the user.
    * @return uint256, uint256, uint256, uint256 The order size, number of tokens filled, execution price, and timestamp at which the order was filled.
    */
    function getPendingOrderInfo(address _user) external view override returns (uint256, uint256, uint256, uint256) {
        return getOrderInfo(userToOrderIndex[_user]);
    }

    /**
    * @notice Returns the number of tokens that the given user can claim.
    * @param _user Address of the user.
    */
    function getAvailableTokensForUser(address _user) public view override returns (uint256) {
        // The index is set to 0 when the user claims tokens.
        // Since the indicies start at 1, index 0 is guaranteed to have a value of 0 for each variable in the struct.
        uint256 orderIndex = userToOrderIndex[_user];

        return filledOrders[orderIndex].numberOfTokensFilled;
    }

    /**
    * @notice Returns the dollar value of the given user's available tokens.
    * @param _user Address of the user.
    */
    function getAvailableDollarAmount(address _user) external view override returns (uint256) {
        uint256 orderIndex = userToOrderIndex[_user];
        uint256 executionPrice = filledOrders[orderIndex].executionPrice;

        return getAvailableTokensForUser(_user).mul(executionPrice).div(10 ** 18);
    }

    /**
    * @notice Returns the total size of open orders.
    */
    function getAvailableTokensInOrderbook() public view override returns (uint256) {
        return end - current;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Places an order for the given number of tokens.
    * @dev Transaction will revert if _numberOfTokens exceeds the user's balance.
    * @param _isBuy Whether the order represents a 'buy'.
    * @param _numberOfTokens The number of tokens to buy/sell.
    */
    function placeOrder(bool _isBuy, uint256 _numberOfTokens) external override {
        require(!tradingIsPaused, "Orderbook: Cannot place orders when trading is paused.");

        bool isSameDirectionAsOrderbook = _isBuy && representsBuyOrders;

        require(userToOrderIndex[msg.sender] == 0 || (userToOrderIndex[msg.sender] > 0 && !isSameDirectionAsOrderbook), "Orderbook: User already has an open order.");

        if (isSameDirectionAsOrderbook) {
            if (_isBuy) {
                stablecoin.safeTransferFrom(msg.sender, address(this), _numberOfTokens);
            } else {
                IERC20(syntheticAsset).safeTransferFrom(msg.sender, address(this), _numberOfTokens);
            }

            uint256 orderIndex = numberOfOrders.add(1);
            uint256 currentEnd = end;
            uint256 newEnd = currentEnd.add(_numberOfTokens);
            numberOfOrders = orderIndex;
            orderIndexToUser[orderIndex] = msg.sender;
            userToOrderIndex[msg.sender] = orderIndex;
            end = newEnd;
            orders[orderIndex] = newEnd;

            emit PlacedOrder(msg.sender, _numberOfTokens, orderIndex, 0);
        } else {
            {
            address feeToken;
            uint256 usageFee;
            (feeToken, usageFee) = oracle.getUsageFeeInfo(syntheticAsset);

            IERC20(feeToken).safeTransferFrom(msg.sender, address(this), usageFee);
            IERC20(feeToken).approve(address(oracle), usageFee);
            }
            uint256 oraclePrice = oracle.getLatestPrice(syntheticAsset);

            // Amounts are in the pending orders' token.
            (uint256 adjustedOrderSize, uint256 remainder) = _computeAdjustedOrderSizeAndRemainder(_numberOfTokens);

            // Pending orders are in synthetic asset tokens for the "sell" version of the orderbook.
            // In the "buy" version of the orderbook, pending orders are in stablecoin.
            if (_isBuy) {
                stablecoin.safeTransferFrom(msg.sender, address(this), adjustedOrderSize.mul(oraclePrice).div(10 ** 18));
                IERC20(syntheticAsset).safeTransfer(msg.sender, adjustedOrderSize);
            } else {
                IERC20(syntheticAsset).safeTransferFrom(msg.sender, address(this), adjustedOrderSize.mul(10 ** 18).div(oraclePrice));
                stablecoin.safeTransfer(msg.sender, adjustedOrderSize);
            }

            {
            // Gas savings.
            uint256 newCurrent = current.add(adjustedOrderSize);
            uint256 lastKey = lastFilledOrderKey;

            current = newCurrent;
            FilledOrder memory lastFilledOrder = filledOrders[lastKey];
            if (lastFilledOrder.executionPrice > 0) {
                filledOrders[lastKey].next = newCurrent;
            }
            filledOrders[newCurrent] = FilledOrder({
                numberOfTokensFilled: adjustedOrderSize,
                executionPrice: oraclePrice,
                timestamp: block.timestamp,
                previous: lastFilledOrder.executionPrice > 0 ? lastKey : 0,
                next: 0
            });
            lastFilledOrderKey = newCurrent;
            _addToFilledOrdersLookupStructure(newCurrent);
            }

            emit ExecutedOrder(msg.sender, adjustedOrderSize, oraclePrice, remainder);
        }
    }

    /**
    * @notice Cancels the pending order for the user.
    * @dev If _cancelFullOrder is set to true, _numberOfTokens is ignored.
    * @dev This function also claims all available tokens for the user.
    * @dev Transaction will revert if _numberOfTokens exceeds the user's order size.
    * @param _numberOfTokens The number of tokens to cancel.
    * @param _cancelFullOrder Whether to fully cancel the order.
    */
    function cancelOrder(uint256 _numberOfTokens, bool _cancelFullOrder) external override {
        uint256 orderIndex = userToOrderIndex[msg.sender];
        require(orderIndex > 0, "Orderbook: User does not have an order.");

        uint256 orderSize = orders[orderIndex].sub(orders[orderIndex.sub(1)]);
        require(_numberOfTokens.add(cancelledOrders[orderIndex].amountCancelled) <= orderSize, "Orderbook: Amount cancelled exceeds the order size.");

        // Prevent users from cancelling orders that are already considered "filled".
        uint256 totalAmountCancelled = _calculateTotalAmountCancelled(orderIndex);
        require(current.add(totalAmountCancelled) < orders[orderIndex], "Orderbook: Order is already filled.");

        _addToCancelledOrdersLookupStructure(orderIndex);

        uint256 nearestCancelledOrderIndex = _findNearestCancelledOrder(orderIndex);

        // Update the pointers.
        uint256 nextOrderIndex = cancelledOrders[nearestCancelledOrderIndex].next;
        cancelledOrders[nextOrderIndex].previous = orderIndex;
        cancelledOrders[nearestCancelledOrderIndex].next = orderIndex;

        // User does not have a cancelled order yet.
        if (cancelledOrders[orderIndex].amountCancelled == 0) {
            cancelledOrders[orderIndex] = CancelledOrder({
                amountCancelled: _numberOfTokens,
                timestamp: block.timestamp,
                previous: nearestCancelledOrderIndex,
                next: nextOrderIndex
            });
        } else {
            cancelledOrders[orderIndex].amountCancelled = cancelledOrders[orderIndex].amountCancelled.add(_numberOfTokens);
            cancelledOrders[orderIndex].timestamp = block.timestamp;

            if (representsBuyOrders) {
                stablecoin.safeTransfer(msg.sender, cancelledOrders[orderIndex].amountCancelled);
            } else {
                IERC20(syntheticAsset).safeTransfer(msg.sender, cancelledOrders[orderIndex].amountCancelled);
            }
        }

        // Clear the user's order index if the order is considered fully cancelled.
        if (_cancelFullOrder || _numberOfTokens.add(cancelledOrders[orderIndex].amountCancelled) == orderSize) {
            userToOrderIndex[msg.sender] = 0;
            orderIndexToUser[orderIndex] = address(0);
        }
    }

    /**
    * @notice Claims all available tokens for the user.
    */
    function claimTokens() external override {
        uint256 orderIndex = userToOrderIndex[msg.sender];
        require(orderIndex > 0, "Orderbook: User does not have an order.");

        uint256 orderSize = orders[orderIndex].sub(orders[orderIndex.sub(1)]);
        uint256 totalAmountCancelled = _calculateTotalAmountCancelled(orderIndex);
        uint256 adjustedCurrent = current.add(totalAmountCancelled);
        require(adjustedCurrent > orders[orderIndex.sub(1)], "Orderbook: User has no tokens to claim.");

        uint256 averageExecutionPrice = _calculateAverageExecutionPrice(orders[orderIndex.sub(1)].sub(totalAmountCancelled), orders[orderIndex].sub(totalAmountCancelled));
        require(averageExecutionPrice > 0, "Orderbook: Average execution price is 0.");

        uint256 amountFilled = (adjustedCurrent >= orders[orderIndex]) ? orderSize : orders[orderIndex].sub(adjustedCurrent);

        if (representsBuyOrders) {
            IERC20(syntheticAsset).safeTransfer(msg.sender, amountFilled.mul(10 ** 18).div(averageExecutionPrice));
        } else {
            stablecoin.safeTransfer(msg.sender, amountFilled.mul(averageExecutionPrice).div(10 ** 18));
        }

        if (amountFilled == orderSize) {
            userToOrderIndex[msg.sender] = 0;
            orderIndexToUser[orderIndex] = address(0);
        }

        emit ClaimedTokens(msg.sender, amountFilled, averageExecutionPrice);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @notice Calculates the average execution price of filled orders that overlap with the user's order range.
    * @param _start The value of "current" at the start of the user's order range.
    * @param _end The value of "current" at the end of the user's order range.
    */
    function _calculateAverageExecutionPrice(uint256 _start, uint256 _end) internal view returns (uint256) {
        uint256 totalPriceAndQuantity;
        uint256 totalQuantity;
        uint256 filledOrderKey = _findNearestFilledOrder(_start);

        if (filledOrderKey == 0) {
            return 0;
        }

        while (filledOrderKey <= _end) {
            FilledOrder memory filledOrder = filledOrders[filledOrderKey];
            // min(order's end, user's end).
            uint256 adjustedEnd = (filledOrderKey.add(filledOrder.numberOfTokensFilled) > _end) ? _end : filledOrderKey.add(filledOrder.numberOfTokensFilled);
            // max(order's start, user's start).
            uint256 adjustedStart = (filledOrderKey > _start) ? filledOrderKey : _start;
            uint256 overlap = adjustedEnd.sub(adjustedStart);
            totalQuantity = totalQuantity.add(overlap);
            totalPriceAndQuantity = totalPriceAndQuantity.add(overlap.mul(filledOrder.executionPrice).div(10 ** 18));
            filledOrderKey = filledOrder.next;
        }

        return totalPriceAndQuantity.mul(10 ** 18).div(totalQuantity);
    }

    /**
    * @notice Calculates the total number of tokens cancelled between "current" and the user's value of "current".
    * @param _orderIndex The order index to calculate from.
    */
    function _calculateTotalAmountCancelled(uint256 _orderIndex) internal view returns (uint256 totalAmountCancelled) {
        _orderIndex = _findNearestCancelledOrder(_orderIndex);

        while (orders[_orderIndex] > current) {
            totalAmountCancelled = totalAmountCancelled.add(cancelledOrders[_orderIndex].amountCancelled);
            _orderIndex = cancelledOrders[_orderIndex].previous;
        }
    }

    /**
    * @notice Finds the nearest entry in cancelledOrderLookup that has a value <= _orderIndex.
    * @dev Returns 0 if there are no entries in cancelledOrderLookup that satisfy the condition.
    * @param _orderIndex The order index to query.
    */
    function _findNearestCancelledOrder(uint256 _orderIndex) internal view returns (uint256) {
        uint256 magnitude = TradegenMath.log10(_orderIndex);
        uint256 prefix;

        while (_orderIndex > 0) {
            string memory metadataKey = string.concat(Strings.toString(magnitude), "/", (prefix == 0) ? "" : Strings.toString(prefix), "/m");
            LookupValue memory value = cancelledOrderLookup[metadataKey];
            
            // Metadata exists.
            if (value.isLastDigit) {
                while (value.previousDigit > _orderIndex % 10) {
                    string memory entryKey = string.concat(Strings.toString(magnitude), "/", (prefix == 0) ? "" : Strings.toString(prefix), "/", Strings.toString(_orderIndex % (10 ** magnitude)));
                    value.previousDigit = cancelledOrderLookup[entryKey].previousDigit;
                }
            }

            prefix = prefix.add(_orderIndex % (10 ** magnitude));
            magnitude = magnitude.sub(1);
            _orderIndex = _orderIndex.div(10);
        }

        return prefix;
    }

    /**
    * @notice Finds the nearest entry in filledOrderLookup that has a value <= _current.
    * @dev Returns 0 if there are no entries in filledOrderLookup that satisfy the condition.
    * @param _current The value of "current" at which the user's order is considered filled.
    */
    function _findNearestFilledOrder(uint256 _current) internal view returns (uint256) {
        uint256 magnitude = TradegenMath.log10(_current);
        uint256 prefix;

        while (_current > 0) {
            string memory metadataKey = string.concat(Strings.toString(magnitude), "/", (prefix == 0) ? "" : Strings.toString(prefix), "/m");
            LookupValue memory value = filledOrderLookup[metadataKey];
            
            // Metadata exists.
            if (value.isLastDigit) {
                while (value.previousDigit > _current % 10) {
                    string memory entryKey = string.concat(Strings.toString(magnitude), "/", (prefix == 0) ? "" : Strings.toString(prefix), "/", Strings.toString(_current % (10 ** magnitude)));
                    value.previousDigit = filledOrderLookup[entryKey].previousDigit;
                }
            }

            prefix = prefix.add(_current % (10 ** magnitude));
            magnitude = magnitude.sub(1);
            _current = _current.div(10);
        }

        return prefix;
    }

    /**
    * @notice Adds a new entry to filledOrderLookup.
    * @param _current The value of 'current' at which the order was filled.
    */
    function _addToFilledOrdersLookupStructure(uint256 _current) internal {
        uint256 magnitude = TradegenMath.log10(_current);
        string memory prefix;

        while (_current > 0) {
            string memory metadataKey = string.concat(Strings.toString(magnitude), "/", prefix, "/m");
            LookupValue memory value = filledOrderLookup[metadataKey];
            
            // Metadata does not exist.
            if (!value.isLastDigit) {
                filledOrderLookup[metadataKey] = LookupValue({
                    isLastDigit: true,
                    previousDigit: uint8(_current % (10 ** magnitude))
                });

                string memory entryKey = string.concat(Strings.toString(magnitude), "/", prefix, "/", Strings.toString(_current % (10 ** magnitude)));
                filledOrderLookup[entryKey] = LookupValue({
                    isLastDigit: false,
                    previousDigit: 0
                });
            } else {
                filledOrderLookup[metadataKey].previousDigit = value.previousDigit;

                string memory entryKey = string.concat(Strings.toString(magnitude), "/", prefix, "/", Strings.toString(_current % (10 ** magnitude)));
                filledOrderLookup[entryKey] = LookupValue({
                    isLastDigit: false,
                    previousDigit: value.previousDigit
                });
            }

            prefix = string.concat(prefix, Strings.toString(_current % (10 ** magnitude)));
            magnitude = magnitude.sub(1);
            _current = _current.div(10);
        }
    }

    /**
    * @notice Adds a new entry to cancelledOrderLookup.
    * @param _orderIndex The user's order index.
    */
    function _addToCancelledOrdersLookupStructure(uint256 _orderIndex) internal {
        uint256 magnitude = TradegenMath.log10(_orderIndex);
        string memory prefix;

        while (_orderIndex > 0) {
            string memory metadataKey = string.concat(Strings.toString(magnitude), "/", prefix, "/m");
            LookupValue memory value = cancelledOrderLookup[metadataKey];
            
            // Metadata does not exist.
            if (!value.isLastDigit) {
                cancelledOrderLookup[metadataKey] = LookupValue({
                    isLastDigit: true,
                    previousDigit: uint8(_orderIndex % (10 ** magnitude))
                });

                string memory entryKey = string.concat(Strings.toString(magnitude), "/", prefix, "/", Strings.toString(_orderIndex % (10 ** magnitude)));
                cancelledOrderLookup[entryKey] = LookupValue({
                    isLastDigit: false,
                    previousDigit: 0
                });
            } else {
                cancelledOrderLookup[metadataKey].previousDigit = value.previousDigit;

                string memory entryKey = string.concat(Strings.toString(magnitude), "/", prefix, "/", Strings.toString(_orderIndex % (10 ** magnitude)));
                cancelledOrderLookup[entryKey] = LookupValue({
                    isLastDigit: false,
                    previousDigit: value.previousDigit
                });
            }

            prefix = string.concat(prefix, Strings.toString(_orderIndex % (10 ** magnitude)));
            magnitude = magnitude.sub(1);
            _orderIndex = _orderIndex.div(10);
        }
    }

    /**
    * @notice Returns the adjusted order size and the remaining amount.
    * @dev The remaining amount is the number of tokens that exceeds the available number of tokens in the orderbook.
    * @param _numberOfTokens Desired order size.
    */
    function _computeAdjustedOrderSizeAndRemainder(uint256 _numberOfTokens) internal view returns (uint256, uint256) {
        // Gas savings.
        uint256 availableTokens = getAvailableTokensInOrderbook();

        if (_numberOfTokens <= availableTokens) {
            return (_numberOfTokens, _numberOfTokens);
        }

        return (availableTokens, availableTokens.sub(_numberOfTokens));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Pauses trading for this asset.
    * @dev Only the Router contract can call this function.
    * @dev This function is meant to be used to protect the protocol from Black Swan events.
    * @param _pauseTrading Whether to pause trading. Set this value to false to resume trading.
    */
    function pauseTrading(bool _pauseTrading) external override onlyRouter {
        tradingIsPaused = _pauseTrading;

        emit PausedTrading(_pauseTrading);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRouter() {
        require(msg.sender == router, "SyntheticAssetTokenRegistry: Only the Router contract can call this function.");
        _;
    }

    modifier tradingIsNotPaused() {
        require(!tradingIsPaused, "SyntheticAssetTokenRegistry: This function can only be called when trading is not paused.");
        _;
    }

    /* ========== EVENTS ========== */

    event PlacedOrder(address user, uint256 numberOfTokens, uint256 orderIndex, uint256 remainder);
    event ExecutedOrder(address user, uint256 numberOfTokens, uint256 executionPrice, uint256 remainder);
    event ClaimedTokens(address user, uint256 numberOfTokens, uint256 averageExecutionPrice);
    event CancelledAnOrder(address user, uint256 numberOfTokens, uint256 orderIndex);
    event PausedTrading(bool tradingStatus);
}