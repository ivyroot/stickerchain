pragma solidity ^0.8.24;

import {IStickerObjective} from "./IStickerObjective.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";


contract StickerObjectives is Ownable {
    address public immutable stickerChain;
    address public operator;
    bool public publicCreationEnabled;
    mapping (uint => IStickerObjective) private objectives;
    mapping (address => uint) private objectivesLookup;
    mapping (address => bool) public bannedObjectives;
    mapping (address => bool) public bannedAddresses;
    uint public objectiveCount;
    uint public addNewObjectiveFee;
    address public adminFeeRecipient;

    event AdminTransferFailure(address indexed recipient, uint amount);
    event NewObjective(address indexed objective, uint indexed objectiveId, address indexed dev);
    event ObjectiveBanned(address indexed objective, uint indexed objectiveId);
    event ObjectiveUnbanned(address indexed objective, uint indexed objectiveId);

    error ObjectiveNotAllowed();
    error AddressNotAllowed();
    error IncorrectFeePayment();
    error ObjectiveAlreadyExists();
    error PublicCreationDisabled();

    constructor(address _stickerChain, address _initialAdmin, uint _addNewObjectiveFee) Ownable(_initialAdmin) {
        stickerChain = _stickerChain;
        adminFeeRecipient = _initialAdmin;
        operator = _initialAdmin;
        addNewObjectiveFee = _addNewObjectiveFee;
    }

    function getObjective(uint _objectiveId) public view returns (IStickerObjective objective) {
        IStickerObjective loadedObjective = objectives[_objectiveId];
        if (bannedObjectives[address(loadedObjective)]) {
            return objective;
        }
        objective = loadedObjective;
    }

    function getObjectives(uint _offset, uint _count) external view returns (IStickerObjective[] memory) {
        if (_offset >= objectiveCount) {
            return new IStickerObjective[](0);
        }
        uint max = _offset + _count;
        if (max > objectiveCount) {
            max = objectiveCount;
        }
        IStickerObjective[] memory _objectives = new IStickerObjective[](max - _offset);
        for (uint i = _offset; i < max; i++) {
            _objectives[i - _offset] = getObjective(i);
        }
        return _objectives;
    }

    function getIdOfObjective(address _objectiveAddress) public view returns (uint) {
        if (bannedObjectives[_objectiveAddress]) {
            return 0;
        }
        return objectivesLookup[_objectiveAddress];
    }

    function addNewObjective(IStickerObjective _objective)
        external payable
        returns (uint) {

        if (msg.sender != operator) {
            if (!publicCreationEnabled) {
                revert PublicCreationDisabled();
            }
            if (msg.value != addNewObjectiveFee) {
                revert IncorrectFeePayment();
            }
        }
        if (bannedAddresses[msg.sender] || address(_objective) == address(0)) {
            revert AddressNotAllowed();
        }
        if (objectivesLookup[address(_objective)] != 0) {
            revert ObjectiveAlreadyExists();
        }
        address _objectiveOwner = _objective.owner();
        if (bannedAddresses[_objectiveOwner] || _objectiveOwner == address(0) || _objectiveOwner != msg.sender){
            revert AddressNotAllowed();
        }
        if (_objective.stickerChain() != stickerChain) {
            revert AddressNotAllowed();
        }
        objectiveCount++;
        uint _objectiveId = objectiveCount;
        objectives[_objectiveId] = _objective;
        objectivesLookup[address(_objective)] = _objectiveId;
        emit NewObjective(address(_objective), _objectiveId, _objectiveOwner);
        return _objectiveId;
    }

    // admin function to change fee
    function setAddNewObjectiveFee(uint _fee) public onlyOwner() {
        addNewObjectiveFee = _fee;
    }

    // admin function to set admin fee recipient. cannot be zero address
    function setAdminFeeRecipient(address _recipient) public onlyOwner() {
        if (_recipient == address(0)) {
            revert AddressNotAllowed();
        }
        adminFeeRecipient = _recipient;
    }

    // admin function to set operator
    function setOperator(address _operator) public onlyOwner() {
        operator = _operator;
    }

    function enablePublicCreation() public onlyOwner() {
        publicCreationEnabled = true;
    }

    // admin function to set banned objectives
    function banObjectives(address[] memory _objectives, bool _undoBan) public onlyOwner() {
        for (uint i = 0; i < _objectives.length; i++) {
            bannedObjectives[_objectives[i]] = !_undoBan;
            if (_undoBan) {
                emit ObjectiveUnbanned(_objectives[i], objectivesLookup[_objectives[i]]);
            } else {
                emit ObjectiveBanned(_objectives[i], objectivesLookup[_objectives[i]]);
            }
        }
    }

    // admin function set and unset banned addresses
    function banAddresses(address[] memory _addresses, bool _undoBan) public onlyOwner() {
        for (uint i = 0; i < _addresses.length; i++) {
            bannedAddresses[_addresses[i]] = !_undoBan;
        }
    }

}