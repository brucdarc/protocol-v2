// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    //solium-disable-next-line
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0. wtf is "solidity scratch pad"?

      //So we are just fucking writing our local memory directly with no local variables here?
      //And then it delegate call we just tell it to take params from our memory data starting at 0?
      //Calldata has its own specific buffer location, so to modify it in assembly we need specific op codes
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      //switch case is its own assembly operation, interesting, I didn't know it was that simple.
      switch result
        // delegatecall returns 0 on error.
        case 0 {
          //Assumes you are reading from memory data type I assume. So does compiler do implicit conversion if you try and return storage or just revert?
          revert(0, returndatasize()) //0 here is referring to the start byte of the return data bytes in memory to return
        }
        default {
          //Assume memory
          return(0, returndatasize()) //0 reffering to the byte location in memory to take the returndata from, and second param is how many bytes to read
        }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}
