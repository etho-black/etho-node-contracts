// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NodeTracking {
    
    address internal owner; // owner of the contract
    address internal operator; // operator or control contract
    
    mapping (uint => nodeType) public nodeTypes;
    uint public nodeTypeCount;
    
    mapping(uint => address) public indexNodeMapping;
    mapping(address => collateralizedNode) public addressNodeMapping;
    uint public nodeCount;
    
    struct nodeType {
        uint nodeTypeIndex;
        string name;
        uint requiredCollateral;
        uint nodeCount;
    }
    
    struct collateralizedNode {
        uint nodeIndex;
        address nodeOperator;
        uint collateralAmount;
        uint collateralizedNodeType;
        bool isActive;
    }
    
    function AddNode(uint newNodeType) public payable {
        require(msg.value == nodeTypes[newNodeType].requiredCollateral);
        require(!addressNodeMapping[msg.sender].isActive);
        collateralizedNode memory newCollateralizedNode = collateralizedNode({nodeIndex: nodeCount, nodeOperator: msg.sender, collateralAmount: nodeTypes[newNodeType].requiredCollateral, collateralizedNodeType: newNodeType, isActive: true});
        addressNodeMapping[msg.sender] = newCollateralizedNode;
        indexNodeMapping[nodeCount] = msg.sender;
        nodeTypes[newNodeType].nodeCount++;
        nodeCount++;
    }
    
    function RemoveNode() public {
        require(addressNodeMapping[msg.sender].isActive);
        address payable operatorAddress = payable(msg.sender);
        operatorAddress.transfer(addressNodeMapping[msg.sender].collateralAmount);
        addressNodeMapping[msg.sender].collateralAmount = 0;
        addressNodeMapping[msg.sender].isActive = false;
        
        nodeTypes[addressNodeMapping[msg.sender].collateralizedNodeType].nodeCount--;
        
        indexNodeMapping[addressNodeMapping[msg.sender].nodeIndex] = indexNodeMapping[nodeCount - 1]; // Re-index address mapping
        addressNodeMapping[indexNodeMapping[nodeCount - 1]].nodeIndex = addressNodeMapping[msg.sender].nodeIndex; // Re-index node mapping
        addressNodeMapping[msg.sender].nodeIndex = 0;
        
        
        delete indexNodeMapping[nodeCount - 1]; // Remove last indexed address
        delete addressNodeMapping[msg.sender]; // Remove collateralized node
        nodeCount--;
    }
    
    function AddNodeType(string memory name, uint requiredCollateral) public restrictedOperator {
        nodeType memory newNodeType = nodeType({nodeTypeIndex: nodeTypeCount, name: name, requiredCollateral: requiredCollateral, nodeCount: 0});
        nodeTypes[nodeTypeCount] = newNodeType;
        nodeTypeCount++;
    }
    
    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    
    modifier restrictedOperator {
        require(msg.sender == operator || msg.sender == owner, "This function is restricted to owner or operator");
        _;
    }
    
     constructor() {
        owner = msg.sender;
        operator = msg.sender;
        nodeCount = 0;
        nodeTypeCount = 0;
    }
}
