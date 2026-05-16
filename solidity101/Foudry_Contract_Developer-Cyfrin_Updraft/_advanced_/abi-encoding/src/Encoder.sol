// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Encoder {
    function encodeNumber() public pure returns (bytes memory) {
        bytes memory number = abi.encode(15);
        return number;
    }

    // combineStrings() e combineStringsWithConcat() hanno lo stesso output
    function combineStrings() public pure returns (string memory) {
        return string(abi.encodePacked("Hi Mom! ", "Miss you!"));
    }

    function combineStringsWithConcat() public pure returns (string memory) {
        return string.concat("Hi Mom! ", "Miss you!");
    }

    // Output not packed. Non contiene solo i caratteri "Some string", ma anche offset, lunghezza e padding.
    // L'offset ci dice: “il contenuto dinamico della stringa inizia dopo x byte”.
    // La lunghezza ci dice il numero di bytes (caratteri ASCII in questo caso)
    function encodeString() public pure returns (bytes memory) {
        bytes memory someString = abi.encode("Some string");
        return someString;
    }

    // Output packed. Same for encodeStringPacked() and encodeStringBytes()
    function encodeStringPacked() public pure returns (bytes memory) {
        bytes memory someString = abi.encodePacked("Some string");
        return someString;
    }

    function encodeStringBytes() public pure returns (bytes memory) {
        bytes memory someString = bytes("Some string");
        return someString;
    }

    function decodeString() public pure returns (string memory) {
        string memory someString = abi.decode(encodeString(), (string));
        return someString;
    }

    function multiEncode() public pure returns (bytes memory) {
        bytes memory someString = abi.encode("some string", "it's bigger!");
        return someString;
    }

    function multiDecode() public pure returns (string memory, string memory) {
        (string memory someString, string memory someOtherString) = abi.decode(
            multiEncode(),
            (string, string)
        );

        return (someString, someOtherString);
    }

    function multiEncodePacked() public pure returns (bytes memory) {
        bytes memory someString = abi.encodePacked(
            "some string",
            "it's bigger!"
        );
        return someString;
    }

    // This doesn't work!
    //function multiDecodePacked() public pure returns (string memory) {
    //   string memory someString = abi.decode(multiEncodePacked(), (string));
    //    return someString;
    //}

    function multiStringCastPacked() public pure returns (string memory) {
        string memory someString = string(multiEncodePacked());
        return someString;
    }

    // What's needed to call a function of a deplyed contract?
    // 1. ABI
    // 2. Contract Address
    // How do we send transaction that call functions with just the data field populated?
    // How do we populate the data field?

    // Solidity has some more "low-level" keywords, namely "staticcall" and "call".

    // call: How we call functions to change the state of the blockchain.
    // staticcall: This is how (at a low level) we do our "view" or "pure" function calls.

    // destinationAddress.call{value:}("")
    // - In {} we are able to pass specific fields of a transaction, like value.
    // - In () we are able to pass data in order to call a specific function
}
