import { callReadOnlyFunction, cvToValue, standardPrincipalCV, uintCV } from "@stacks/transactions";
import { STACKS_MAINNET } from "@stacks/network";

const CONTRACT_ADDRESS = "SP3E0DQAHTXJHH5YT9TZCSBW013YXZB25QFDVXXWY";
const CONTRACT_NAME = "dao-v2";

export async function getProposal(id: number) {
  const result = await callReadOnlyFunction({
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: "get-proposal",
    functionArgs: [uintCV(id)],
    network: STACKS_MAINNET,
    senderAddress: CONTRACT_ADDRESS,
  });
  return cvToValue(result);
}

export async function getProposalCount() {
  const result = await callReadOnlyFunction({
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: "get-proposal-count",
    functionArgs: [],
    network: STACKS_MAINNET,
    senderAddress: CONTRACT_ADDRESS,
  });
  return cvToValue(result);
}

export async function hasUserVoted(proposalId: number, user: string) {
  const result = await callReadOnlyFunction({
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: "has-user-voted",
    functionArgs: [uintCV(proposalId), standardPrincipalCV(user)],
    network: STACKS_MAINNET,
    senderAddress: CONTRACT_ADDRESS,
  });
  return cvToValue(result);
}
