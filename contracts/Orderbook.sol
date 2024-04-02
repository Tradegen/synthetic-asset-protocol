// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";
import './openzeppelin-solidity/contracts/ERC20/SafeERC20.sol';
import './openzeppelin-solidity/contracts/ERC20/IERC20.sol';
import "./openzeppelin-solidity/contracts/SafeMath.sol";

// Interfaces.
import './interfaces/IOracle.sol';
import './interfaces/IProtocolSettings.sol';

// Inheritance.
import './interfaces/IOrderbook.sol';

contract Orderbook is IOrderbook, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct CancelledOrder {
        uint256 amountCancelled;
        uint256 previous;
        uint256 next;
    }

    struct LookupValue {
        bool isLastDigit;
        uint8 previousDigit;
    }

    struct FilledOrder {
        uint256 numberOfTokensFilled;
        uint256 averageExecutionPrice;
        uint256 timestamp;
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

    // Keys represent order index.
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

        return (orderSize, filledOrder.numberOfTokensFilled, filledOrder.averageExecutionPrice, filledOrder.timestamp);
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
    function getAvailableTokens(address _user) public view override returns (uint256) {
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
        uint256 executionPrice = filledOrders[orderIndex].averageExecutionPrice;

        return getAvailableTokens(_user).mul(executionPrice).div(10 ** 18);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Places an order for the given number of tokens.
    * @dev Transaction will revert if _numberOfTokens exceeds msg.sender's balance.
    * @param _numberOfTokens The number of tokens to buy/sell.
    */
    function placeOrder(uint256 _numberOfTokens) external override {
        // TODO.
    }

    /**
    * @notice Cancels the pending order for msg.sender.
    * @dev If _cancelFullOrder is set to true, _numberOfTokens is ignored.
    * @dev This function also claims all available tokens for msg.sender.
    * @dev Transaction will revert if _numberOfTokens exceeds msg.sender's order size.
    * @param _numberOfTokens The number of tokens to cancel.
    * @param _cancelFullOrder Whether to fully cancel the order.
    */
    function cancelOrder(uint256 _numberOfTokens, bool _cancelFullOrder) external override {
        // TODO.
    }

    /**
    * @notice Claims all available tokens for msg.sender.
    */
    function claimTokens() external override {
        // TODO.
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Pauses trading for this asset.
    * @dev Only the operator of the Router contract can call this function.
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

    event PlacedOrder(address user, uint256 numberOfTokens, uint256 orderIndex);
    event ClaimedTokens(address user, uint256 numberOfTokens, uint256 dollarValue);
    event CancelledAnOrder(address user, uint256 numberOfTokens, uint256 orderIndex);
    event PausedTrading(bool tradingStatus);
}