// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {OraclePtax} from "../src/OraclePtax.sol";
import {MockOraclePtax} from "./mock/MockOraclePtax.sol";

contract OraclePtaxTest is Test {
    MockOraclePtax public oracle;

    function setUp() public {
        oracle = new MockOraclePtax(0x1234567890123456789012345678901234567890, 1);

        // Preenche o estado que os testes antigos esperam
        oracle.setTestState();
    }

    function testSource() public view {
        string memory expected =
            "const dateString = args[0];const url = `https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoDolarDia(dataCotacao=@dataCotacao)?@dataCotacao='${dateString}'&$top=100&$format=json&$select=cotacaoCompra,cotacaoVenda,dataHoraCotacao`;const apiResponse = await Functions.makeHttpRequest({url: url,responseType: 'json'});if (apiResponse.error) {throw Error('Request failed');}const { data } = apiResponse;const value = data.value[0]?.cotacaoCompra || '0';return Functions.encodeString(value.toString());";
        string memory actual = oracle.source();
        console.log(actual);
        assertEq(actual, expected);
    }

    function testLastURL() public view {
        string memory expected =
            "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoDolarDia(dataCotacao=@dataCotacao)?@dataCotacao='2025-01-19'&$top=100&$format=json&$select=cotacaoCompra,cotacaoVenda,dataHoraCotacao";
        string memory actual = oracle.lastURL();
        console.log(actual);
        assertEq(actual, expected);
    }

    function testLastPath() public view {
        string memory expected = "data.value[0]?.cotacaoCompra";
        string memory actual = oracle.lastPath();
        console.log(actual);
        assertEq(actual, expected);
    }

    function testLastData() public view {
        string memory expected = "2025-01-19";
        string memory actual = oracle.lastData();
        console.log(actual);
        assertEq(actual, expected);
    }

    function testLastSender() public view {
        address expected = address(this);
        address actual = oracle.lastSender();
        console.log(actual);
        assertEq(actual, expected);
    }

    function testLastResponse() public view {
        bytes memory expected = abi.encodePacked("4.123");
        bytes memory actual = oracle.lastResponse();
        console.logBytes(actual);
        assertEq(actual, expected);
    }

    function testLastError() public view {
        bytes memory expected = abi.encodePacked("Request failed");
        bytes memory actual = oracle.lastError();
        console.logBytes(actual);
        assertEq(actual, expected);
    }

    function testRequestIndex() public view {
        uint256 expected = 0;
        uint256 actual = oracle.requestIndex("2025-01-19");
        console.log(actual);
        assertEq(actual, expected);
    }

    function testRequestIds() public view {
        bytes32 expected = keccak256(abi.encodePacked("2025-01-19"));
        bytes32 actual = oracle.requestIds(oracle.requestIndex("2025-01-19"));
        console.logBytes32(actual);
        assertEq(actual, expected);
    }

    function testRequests() public view {
        OraclePtax.RequestStatus memory expected =
            OraclePtax.RequestStatus(true, true, abi.encodePacked("4.123"), abi.encodePacked("Request failed"));
        (bool fulfilled, bool exists, bytes memory response, bytes memory err) =
            oracle.requests(keccak256(abi.encodePacked("2025-01-19")));
        OraclePtax.RequestStatus memory actual = OraclePtax.RequestStatus(fulfilled, exists, response, err);
        console.log(actual.fulfilled);
        console.log(actual.exists);
        console.logBytes(actual.response);
        console.logBytes(actual.err);
        assertEq(actual.fulfilled, expected.fulfilled);
        assertEq(actual.exists, expected.exists);
        assertEq(actual.response, expected.response);
        assertEq(actual.err, expected.err);
    }

    function testSubscriptionId() public view {
        uint64 expected = 1;
        uint64 actual = oracle.subscriptionId();
        console.log(actual);
        assertEq(actual, expected);
    }

    function testGasLimit() public view {
        uint32 expected = 300000;
        uint32 actual = oracle.gasLimit();
        console.log(actual);
        assertEq(actual, expected);
    }

    function testDonID() public view {
        bytes32 expected = 0x66756e2d6f7074696d69736d2d7365706f6c69612d3100000000000000000000;
        bytes32 actual = oracle.donID();
        console.logBytes32(actual);
        assertEq(actual, expected);
    }

    function testRouter() public view {
        address expected = 0x1234567890123456789012345678901234567890;
        address actual = oracle.router();
        console.log(actual);
        assertEq(actual, expected);
    }

    function testSendRequest() public view {
        bytes32 expected = keccak256(abi.encodePacked("2025-01-19"));
        bytes32 actual = oracle.requestData("2025-01-19");
        console.logBytes32(actual);
        assertEq(actual, expected);
    }
}
