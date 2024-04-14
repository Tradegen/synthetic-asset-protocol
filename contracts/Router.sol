// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";
import './openzeppelin-solidity/contracts/ERC20/SafeERC20.sol';
import './openzeppelin-solidity/contracts/ERC20/IERC20.sol';
import "./openzeppelin-solidity/contracts/SafeMath.sol";

// Interfaces.
import './interfaces/IOrderbook.sol';
import './interfaces/IOrderbookFactory.sol';

// Inheritance.
import './interfaces/IRouter.sol';

contract Router is IRouter, Ownable {
    IOrderbookFactory public immutable factory;
    address public immutable registry;
    address public operator;

    struct OrderbookAddresses {
        address buyAddress;
        address sellAddress;
    }

    // (synthetic asset address => address of the asset's 'buy' and 'sell' versions of the orderbook).
    mapping (address => OrderbookAddresses) public assetToOrderbookAddresses;

    constructor(address _factory, address _registry) Ownable() {
        factory = IOrderbookFactory(_factory);
        registry = _registry;
        operator = msg.sender;
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the info for the order at the given index.
    * @dev Returns (0, 0, 0, 0) if the asset is not found or the order index is out of bounds.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _isBuy Whether to use the 'buy' version of the asset's orderbook.
    * @param _orderIndex Index of the order.
    * @return uint256, uint256, uint256, uint256 The order size, number of tokens filled, execution price, and timestamp at which the order was filled.
    */
    function getOrderInfo(address _syntheticAsset, bool _isBuy, uint256 _orderIndex) external view override returns (uint256, uint256, uint256, uint256) {
        OrderbookAddresses memory orderbooks = assetToOrderbookAddresses[_syntheticAsset];

        if (orderbooks.buyAddress == address(0)) {
            return (0, 0, 0, 0);
        }

        if (_isBuy) {
            return IOrderbook(orderbooks.buyAddress).getOrderInfo(_orderIndex);
        }

        return IOrderbook(orderbooks.sellAddress).getOrderInfo(_orderIndex);
    }

    /**
    * @notice Returns the order info for the given user's pending order.
    * @dev Returns (0, 0, 0, 0) if the asset is not found or the user does not have an order.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _isBuy Whether to use the 'buy' version of the asset's orderbook.
    * @param _user Address of the user.
    * @return uint256, uint256, uint256, uint256 The order size, number of tokens filled, execution price, and timestamp at which the order was filled.
    */
    function getPendingOrderInfo(address _syntheticAsset, bool _isBuy, address _user) external view override returns (uint256, uint256, uint256, uint256) {
        OrderbookAddresses memory orderbooks = assetToOrderbookAddresses[_syntheticAsset];

        if (orderbooks.buyAddress == address(0)) {
            return (0, 0, 0, 0);
        }

        if (_isBuy) {
            return IOrderbook(orderbooks.buyAddress).getPendingOrderInfo(_user);
        }

        return IOrderbook(orderbooks.sellAddress).getPendingOrderInfo(_user);
    }

    /**
    * @notice Returns the number of tokens that the given user can claim.
    * @dev Returns 0 if the asset is not found.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _isBuy Whether to use the 'buy' version of the asset's orderbook.
    * @param _user Address of the user.
    */
    function getAvailableTokens(address _syntheticAsset, bool _isBuy, address _user) external view override returns (uint256) {
        OrderbookAddresses memory orderbooks = assetToOrderbookAddresses[_syntheticAsset];

        if (orderbooks.buyAddress == address(0)) {
            return 0;
        }

        if (_isBuy) {
            return IOrderbook(orderbooks.buyAddress).getAvailableTokensForUser(_user);
        }

        return IOrderbook(orderbooks.sellAddress).getAvailableTokensForUser(_user);
    }

    /**
    * @notice Returns the dollar value of the given user's available tokens.
    * @dev Returns 0 if the asset is not found.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _isBuy Whether to use the 'buy' version of the asset's orderbook.
    * @param _user Address of the user.
    */
    function getAvailableDollarAmount(address _syntheticAsset, bool _isBuy, address _user) external view override returns (uint256) {
        OrderbookAddresses memory orderbooks = assetToOrderbookAddresses[_syntheticAsset];

        if (orderbooks.buyAddress == address(0)) {
            return 0;
        }

        if (_isBuy) {
            return IOrderbook(orderbooks.buyAddress).getAvailableDollarAmount(_user);
        }

        return IOrderbook(orderbooks.sellAddress).getAvailableDollarAmount(_user);
    }

    /**
    * @notice Returns the two orderbook addresses for the given asset.
    * @dev Returns (address(0), address(0)) if the asset is not found.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return address, address The address of the 'buy' version of the orderbook and the address of the 'sell' version.
    */
    function getOrderbookAddresses(address _syntheticAsset) external view override returns (address, address) {
        OrderbookAddresses memory orderbooks = assetToOrderbookAddresses[_syntheticAsset];

        return (orderbooks.buyAddress, orderbooks.sellAddress);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Pauses trading for this asset.
    * @dev Only the operator of the Router contract can call this function.
    * @dev Pauses trading for both the 'buy' and 'sell' versions of the asset's orderbook.
    * @dev This function is meant to be used to protect the protocol from Black Swan events.
    * @param _pauseTrading Whether to pause trading. Set this value to false to resume trading.
    */
    function pauseTrading(address _syntheticAsset, bool _pauseTrading) external override onlyOperator {
        OrderbookAddresses memory orderbooks = assetToOrderbookAddresses[_syntheticAsset];

        IOrderbook(orderbooks.buyAddress).pauseTrading(_pauseTrading);
        IOrderbook(orderbooks.sellAddress).pauseTrading(_pauseTrading);

        emit PausedTrading(_syntheticAsset, _pauseTrading);
    }

    /**
    * @notice Deploys the 'buy' and 'sell' version of the orderbook for the given asset.
    * @dev Only the SyntheticAssetTokenRegistry contract can call this function.
    * @dev Transaction will revert if the orderbooks have already been created for the asset.
    * @param _syntheticAsset Address of the asset.
    */
    function createOrderbooks(address _syntheticAsset) external override onlyRegistry {
        require(assetToOrderbookAddresses[_syntheticAsset].buyAddress == address(0), "Router: Already created orderbooks for this asset.");

        address buyAddress = factory.createOrderbook(_syntheticAsset, true);
        address sellAddress = factory.createOrderbook(_syntheticAsset, false);

        assetToOrderbookAddresses[_syntheticAsset] = OrderbookAddresses({
            buyAddress: buyAddress,
            sellAddress: sellAddress
        });

        emit CreatedOrderbooks(_syntheticAsset, buyAddress, sellAddress);
    }

    /**
     * @notice Updates the address of the operator.
     * @dev This function can only be called by the Router contract owner.
     * @param _newOperator Address of the new operator.
     */
    function setOperator(address _newOperator) external onlyOwner {
        operator = _newOperator;

        emit SetOperator(_newOperator);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOperator() {
        require(msg.sender == operator, "Router: Only the operator can call this function.");
        _;
    }

    modifier onlyRegistry() {
        require(msg.sender == registry, "Router: Only the SyntheticAssetTokenRegistry contract can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event SetOperator(address newOperator);
    event CreatedOrderbooks(address _syntheticAsset, address _buyAddress, address _sellAddress);
    event PausedTrading(address _syntheticAsset, bool _tradingIsPaused);
}