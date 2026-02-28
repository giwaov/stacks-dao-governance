export const CONTRACT_ADDRESS = "SP3E0DQAHTXJHH5YT9TZCSBW013YXZB25QFDVXXWY";

export const CONTRACTS = {
  DAO: { address: CONTRACT_ADDRESS, name: "dao-v2" },
  CROWDFUND: { address: CONTRACT_ADDRESS, name: "crowdfund" },
  ESCROW: { address: CONTRACT_ADDRESS, name: "escrow" },
  SUBSCRIPTION: { address: CONTRACT_ADDRESS, name: "subscription" },
  VOTING: { address: CONTRACT_ADDRESS, name: "voting-v2" },
  TIP_JAR: { address: CONTRACT_ADDRESS, name: "tip-jar-v3" },
  NFT: { address: CONTRACT_ADDRESS, name: "nft-v2" },
  AUCTION: { address: CONTRACT_ADDRESS, name: "auction-v3" },
} as const;

export const EXPLORER_URL = "https://explorer.hiro.so";

export function getContractUrl(contractName: string) {
  return `${EXPLORER_URL}/txid/${CONTRACT_ADDRESS}.${contractName}?chain=mainnet`;
}

export function getTxUrl(txId: string) {
  return `${EXPLORER_URL}/txid/${txId}?chain=mainnet`;
}

export function formatSTX(microSTX: number): string {
  return (microSTX / 1_000_000).toFixed(6) + " STX";
}

export function parseSTX(stx: number): number {
  return stx * 1_000_000;
}
