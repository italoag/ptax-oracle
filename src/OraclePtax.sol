// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {FunctionsClient} from "chainlink-brownie-contracts/contracts/src/v0.8/functions/dev/v1_X/FunctionsClient.sol";
import {FunctionsRequest} from
    "chainlink-brownie-contracts/contracts/src/v0.8/functions/dev/v1_X/libraries/FunctionsRequest.sol";

contract OraclePtax is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    uint32 private constant GAS_LIMIT = 300000;
    bytes32 private constant DON_ID = 0x66756e2d6f7074696d69736d2d7365706f6c69612d3100000000000000000000;

    bytes32 public lastRequestId;
    bytes public lastResponse;
    bytes public lastError;

    function donID() public pure returns (bytes32) {
        return DON_ID;
    }

    function gasLimit() public pure returns (uint32) {
        return GAS_LIMIT;
    }

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        bytes response;
        bytes err;
    }

    mapping(bytes32 => RequestStatus) public requests;
    bytes32[] public requestIds;

    event Response(bytes32 indexed requestId, string data, bytes response, bytes err);

    address public router;
    uint64 public subscriptionId;

    string public source = string(
        abi.encodePacked(
            "const dateString = args[0];",
            "const url = `https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoDolarDia(dataCotacao=@dataCotacao)?@dataCotacao='${dateString}'&$top=100&$format=json&$select=cotacaoCompra,cotacaoVenda,dataHoraCotacao`;",
            "const apiResponse = await Functions.makeHttpRequest({",
            "url: url,",
            "responseType: 'json'",
            "});",
            "if (apiResponse.error) {",
            "throw Error('Request failed');",
            "}",
            "const { data } = apiResponse;",
            "const value = data.value[0]?.cotacaoCompra || '0';",
            "return Functions.encodeString(value.toString());"
        )
    );

    string public lastURL;
    string public lastPath;
    string public lastData;
    address public lastSender;

    struct RequestStruct {
        address sender;
        uint256 timestamp;
        string url;
        string path;
        string data;
    }

    RequestStruct[] public requestsList;
    mapping(string => uint256) public requestIndex;
    mapping(bytes32 => string) public request_url_path;

    constructor(address _router, uint64 functionsSubscriptionId) FunctionsClient(_router) {
        router = _router;
        subscriptionId = functionsSubscriptionId;
    }

    function requestData(string memory dateString) external virtual returns (bytes32 requestId) {
        string[] memory args = new string[](1);
        args[0] = dateString;

        FunctionsRequest.Request memory req;

        req._initializeRequestForInlineJavaScript(source);
        if (args.length > 0) req._setArgs(args);

        lastRequestId = _sendRequest(req._encodeCBOR(), subscriptionId, gasLimit(), donID());
        lastURL = "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoDolarDia";
        lastPath = "cotacaoCompra";
        request_url_path[lastRequestId] = string(abi.encodePacked(lastURL, "|", lastPath));

        RequestStruct memory auxRequestStruct =
            RequestStruct({sender: msg.sender, timestamp: 0, url: lastURL, path: lastPath, data: ""});
        requestsList.push(auxRequestStruct);
        requestIndex[lastURL] = requestsList.length - 1;

        requests[lastRequestId] = RequestStatus({exists: true, fulfilled: false, response: "", err: ""});
        requestIds.push(lastRequestId);

        return lastRequestId;
    }

    function _fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual override {
        require(requests[requestId].exists, "request not found");

        lastError = err;
        lastResponse = response;

        requests[requestId].fulfilled = true;
        requests[requestId].response = response;
        requests[requestId].err = err;

        string memory auxRequest = request_url_path[requestId];
        lastData = string(response);
        requestsList[requestIndex[auxRequest]].data = lastData;
        requestsList[requestIndex[auxRequest]].timestamp = block.timestamp;

        emit Response(requestId, lastData, lastResponse, lastError);
    }

    function getRequest(string memory url) public view returns (RequestStruct memory) {
        return requestsList[requestIndex[url]];
    }

    function listAllRequests() public view returns (RequestStruct[] memory) {
        return requestsList;
    }

    function listRequests(uint256 start, uint256 end) public view returns (RequestStruct[] memory) {
        if (end > requestsList.length) {
            end = requestsList.length - 1;
        }
        require(start <= end, "start must be <= end");
        uint256 requestCount = end - start + 1;
        RequestStruct[] memory requestsAux = new RequestStruct[](requestCount);

        for (uint256 i = start; i < (end + 1); i++) {
            requestsAux[i - start] = requestsList[i];
        }
        return requestsAux;
    }
}
