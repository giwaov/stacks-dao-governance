"use client";
import { useState, useEffect } from "react";
import { AppConfig, UserSession, showConnect } from "@stacks/connect";
import { openContractCall } from "@stacks/connect";
import { stringUtf8CV, uintCV, PostConditionMode } from "@stacks/transactions";
import { STACKS_MAINNET } from "@stacks/network";

const appConfig = new AppConfig(["store_write"]);
const userSession = new UserSession({ appConfig });
const CONTRACT_ADDRESS = "SP3E0DQAHTXJHH5YT9TZCSBW013YXZB25QFDVXXWY";
const CONTRACT_NAME = "dao-v2";

export default function Home() {
  const [address, setAddress] = useState<string | null>(null);
  const [proposalTitle, setProposalTitle] = useState("");
  const [voteId, setVoteId] = useState("");

  useEffect(() => {
    if (userSession.isUserSignedIn()) {
      setAddress(userSession.loadUserData().profile.stxAddress.mainnet);
    }
  }, []);

  const connect = () => {
    showConnect({
      appDetails: { name: "Stacks DAO Governance", icon: "/icon.png" },
      onFinish: () => setAddress(userSession.loadUserData().profile.stxAddress.mainnet),
      userSession,
    });
  };

  const disconnect = () => {
    userSession.signUserOut();
    setAddress(null);
  };

  const createProposal = async () => {
    if (!proposalTitle) return;
    await openContractCall({
      contractAddress: CONTRACT_ADDRESS,
      contractName: CONTRACT_NAME,
      functionName: "create-proposal",
      functionArgs: [stringUtf8CV(proposalTitle)],
      network: STACKS_MAINNET,
      postConditionMode: PostConditionMode.Allow,
      onFinish: (data) => alert(`Proposal created! TX: ${data.txId}`),
    });
  };

  const voteYes = async () => {
    if (!voteId) return;
    await openContractCall({
      contractAddress: CONTRACT_ADDRESS,
      contractName: CONTRACT_NAME,
      functionName: "vote-yes",
      functionArgs: [uintCV(parseInt(voteId))],
      network: STACKS_MAINNET,
      postConditionMode: PostConditionMode.Allow,
      onFinish: (data) => alert(`Vote cast! TX: ${data.txId}`),
    });
  };

  const voteNo = async () => {
    if (!voteId) return;
    await openContractCall({
      contractAddress: CONTRACT_ADDRESS,
      contractName: CONTRACT_NAME,
      functionName: "vote-no",
      functionArgs: [uintCV(parseInt(voteId))],
      network: STACKS_MAINNET,
      postConditionMode: PostConditionMode.Allow,
      onFinish: (data) => alert(`Vote cast! TX: ${data.txId}`),
    });
  };

  return (
    <main style={{ padding: 40, fontFamily: "system-ui", maxWidth: 600, margin: "0 auto" }}>
      <h1>🏛️ Stacks DAO Governance</h1>
      <p>Decentralized proposal voting on Stacks Mainnet</p>

      {!address ? (
        <button onClick={connect} style={{ padding: "12px 24px", fontSize: 16, cursor: "pointer" }}>
          Connect Wallet
        </button>
      ) : (
        <div>
          <p>Connected: {address.slice(0, 8)}...{address.slice(-4)}</p>
          <button onClick={disconnect}>Disconnect</button>

          <div style={{ marginTop: 30, padding: 20, border: "1px solid #ccc", borderRadius: 8 }}>
            <h3>Create Proposal (0.1 STX fee)</h3>
            <input
              type="text"
              placeholder="Proposal title"
              value={proposalTitle}
              onChange={(e) => setProposalTitle(e.target.value)}
              style={{ width: "100%", padding: 10, marginBottom: 10 }}
            />
            <button onClick={createProposal} style={{ padding: "10px 20px" }}>
              Create Proposal
            </button>
          </div>

          <div style={{ marginTop: 20, padding: 20, border: "1px solid #ccc", borderRadius: 8 }}>
            <h3>Vote on Proposal (0.01 STX per vote)</h3>
            <input
              type="number"
              placeholder="Proposal ID"
              value={voteId}
              onChange={(e) => setVoteId(e.target.value)}
              style={{ width: "100%", padding: 10, marginBottom: 10 }}
            />
            <button onClick={voteYes} style={{ padding: "10px 20px", marginRight: 10, background: "#4CAF50", color: "white", border: "none" }}>
              Vote Yes
            </button>
            <button onClick={voteNo} style={{ padding: "10px 20px", background: "#f44336", color: "white", border: "none" }}>
              Vote No
            </button>
          </div>
        </div>
      )}

      <footer style={{ marginTop: 40, color: "#666", fontSize: 14 }}>
        <p>Contract: {CONTRACT_ADDRESS}.{CONTRACT_NAME}</p>
        <p>Built with @stacks/connect and @stacks/transactions</p>
      </footer>
    </main>
  );
}
