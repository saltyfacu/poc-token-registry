// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenRegistry
 * @dev This contract allows users to register tokens and a council to approve or reject them.
 */
contract TokenRegistry {
    /**
     * @dev Struct to store token information.
     */
    struct Token {
        string name; // Name of the token
        string description; // Description of the token
        string tokenLogoURL; // URL of the token's logo
        string symbol; // Symbol of the token
        uint8 decimals; // Number of decimals for the token
        bool isPending; // Status indicating whether the token is pending approval
        uint256 submissionTime; // Timestamp of when the token was submitted
    }

    // Mapping to store tokens by their contract address
    mapping(address => Token) public tokens;
    address[] public tokenAddresses; // Array to store all token addresses

    // Address of the council (admin) who can approve or reject tokens
    address public council;

    // Auto-approval time in seconds (configurable)
    uint256 public autoApprovalTime;

    // Event to be emitted when a new token is added
    event TokenAdded(
        address indexed contractAddress,
        string name,
        string symbol
    );

    // Event to be emitted when a token is approved or rejected
    event TokenApproved(address indexed contractAddress);
    event TokenRejected(address indexed contractAddress);

    // Event to be emitted when the council address is updated
    event CouncilUpdated(address indexed oldCouncil, address indexed newCouncil);

    /**
     * @dev Modifier to check if the token exists in the registry.
     * @param _contractAddress The address of the token to check.
     */
    modifier tokenExists(address _contractAddress) {
        require(bytes(tokens[_contractAddress].name).length != 0, "Token does not exist");
        _;
    }

    /**
     * @dev Modifier to check if the caller is the council.
     */
    modifier onlyCouncil() {
        require(msg.sender == council, "Caller is not the council");
        _;
    }

    /**
     * @dev Constructor to set the council address and auto-approval time.
     * @param _council The address of the initial council.
     * @param _autoApprovalTime The time after which pending tokens are automatically approved.
     */
    constructor(address _council, uint256 _autoApprovalTime) {
        council = _council;
        autoApprovalTime = _autoApprovalTime;
    }

    /**
     * @dev Function to update the council address.
     * @param _newCouncil The address of the new council.
     */
    function updateCouncil(address _newCouncil) public onlyCouncil {
        require(_newCouncil != address(0), "New council address cannot be zero");
        emit CouncilUpdated(council, _newCouncil);
        council = _newCouncil;
    }

    /**
     * @dev Function to submit a new token to the registry.
     * @param _name The name of the token.
     * @param _description The description of the token.
     * @param _tokenLogoURL The URL of the token's logo.
     * @param _symbol The symbol of the token.
     * @param _contractAddress The address of the token contract.
     * @param _decimals The number of decimals for the token.
     */
    function addToken(
        string memory _name,
        string memory _description,
        string memory _tokenLogoURL,
        string memory _symbol,
        address _contractAddress,
        uint8 _decimals
    ) public {
        require(bytes(tokens[_contractAddress].name).length == 0, "Token already exists");

        Token memory newToken = Token({
            name: _name,
            description: _description,
            tokenLogoURL: _tokenLogoURL,
            symbol: _symbol,
            decimals: _decimals,
            isPending: true,
            submissionTime: block.timestamp
        });

        tokens[_contractAddress] = newToken;
        tokenAddresses.push(_contractAddress);
        emit TokenAdded(_contractAddress, _name, _symbol);
    }

    /**
     * @dev Function for the council to approve a token.
     * @param _contractAddress The address of the token to approve.
     */
    function approveToken(address _contractAddress) public onlyCouncil tokenExists(_contractAddress) {
        Token storage token = tokens[_contractAddress];
        require(token.isPending, "Token is already approved or rejected");
        token.isPending = false;
        emit TokenApproved(_contractAddress);
    }

    /**
     * @dev Function for the council to reject a token.
     * @param _contractAddress The address of the token to reject.
     */
    function rejectToken(address _contractAddress) public onlyCouncil tokenExists(_contractAddress) {
        require(tokens[_contractAddress].isPending, "Token is already approved or rejected");
        delete tokens[_contractAddress];

        // Remove the token address from the list of token addresses
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == _contractAddress) {
                tokenAddresses[i] = tokenAddresses[tokenAddresses.length - 1];
                tokenAddresses.pop();
                break;
            }
        }

        emit TokenRejected(_contractAddress);
    }

    /**
     * @dev Function to retrieve a token's details by its address.
     * @param _contractAddress The address of the token.
     * @return The details of the token.
     */
    function getToken(address _contractAddress)
        public
        view
        tokenExists(_contractAddress)
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            uint8,
            bool
        )
    {
        Token storage token = tokens[_contractAddress];
        return (
            token.name,
            token.description,
            token.tokenLogoURL,
            token.symbol,
            token.decimals,
            token.isPending
        );
    }

    /**
     * @dev Function to auto-approve tokens if they are pending for longer than the auto-approval time.
     */
    function autoApproveTokens() public {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            Token storage token = tokens[tokenAddresses[i]];
            if (token.isPending && (block.timestamp >= token.submissionTime + autoApprovalTime)) {
                token.isPending = false;
                emit TokenApproved(tokenAddresses[i]);
            }
        }
    }

    /**
     * @dev Function to list token details using pagination.
     * @param _page The page number to retrieve.
     * @param _pageSize The number of tokens per page.
     * @return An array of token structs for the specified page.
     */
    function listTokens(uint256 _page, uint256 _pageSize)
        public
        view
        returns (Token[] memory)
    {
        require(_pageSize > 0, "Page size must be greater than zero");
        uint256 startIndex = _page * _pageSize;
        uint256 endIndex = startIndex + _pageSize;
        if (endIndex > tokenAddresses.length) {
            endIndex = tokenAddresses.length;
        }
        require(startIndex < tokenAddresses.length, "Page out of range");

        Token[] memory pageTokens = new Token[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            pageTokens[i - startIndex] = tokens[tokenAddresses[i]];
        }
        return pageTokens;
    }

    /**
     * @dev Function to get the latest index for pagination.
     * @return The latest index of the token list.
     */
    function getLatestIndex() public view returns (uint256) {
        return tokenAddresses.length;
    }
}
