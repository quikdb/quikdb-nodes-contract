import { ethers } from "ethers";

export interface TransactionResponse extends ethers.TransactionResponse {}
export interface TransactionReceipt extends ethers.TransactionReceipt {}

export interface BaseModule {
  connect(provider: ethers.Provider): void;
  setSigner(signer: ethers.Signer): void;
}
