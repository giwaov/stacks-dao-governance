export interface Proposal {
  proposer: string;
  title: string;
  description: string;
  votesFor: number;
  votesAgainst: number;
  status: 'active' | 'passed' | 'rejected' | 'executed';
  startBlock: number;
  endBlock: number;
}

export interface Vote {
  voter: string;
  proposalId: number;
  support: boolean;
  amount: number;
}

export interface DAOStats {
  totalProposals: number;
  activeProposals: number;
  totalParticipants: number;
  treasury: number;
}

export interface WalletState {
  address: string | null;
  connected: boolean;
  balance: number;
}

export interface TransactionResult {
  txId: string;
  success: boolean;
  error?: string;
}
