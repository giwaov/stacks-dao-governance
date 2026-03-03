;; DAO Governance Contract - Comprehensive proposal voting with STX staking
;; Deployed on Stacks Mainnet

;; Error codes
(define-constant ERR_INSUFFICIENT_STAKE (err u1))
(define-constant ERR_AMOUNT_EXCEEDS_STAKE (err u2))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u3))
(define-constant ERR_ALREADY_VOTED (err u4))
(define-constant ERR_BELOW_MIN_STAKE (err u5))
(define-constant ERR_VOTING_ENDED (err u6))
(define-constant ERR_VOTING_ACTIVE (err u7))
(define-constant ERR_PROPOSAL_FAILED (err u8))
(define-constant ERR_ALREADY_EXECUTED (err u9))
(define-constant ERR_NO_QUORUM (err u10))
(define-constant ERR_NOT_AUTHORIZED (err u11))
(define-constant ERR_TIMELOCK_NOT_PASSED (err u12))

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant VOTING_PERIOD u144) ;; ~1 day in blocks
(define-constant EXECUTION_DELAY u72) ;; ~12 hours timelock
(define-constant QUORUM_PERCENTAGE u10) ;; 10% of total staked must vote

;; Data vars
(define-data-var proposal-count uint u0)
(define-data-var min-stake uint u100000) ;; 0.1 STX minimum stake to vote
(define-data-var total-staked uint u0)
(define-data-var proposals-passed uint u0)
(define-data-var proposals-failed uint u0)
(define-data-var dao-name (string-utf8 50) u"Stacks DAO")

;; Maps
(define-map proposals 
  uint 
  {
    title: (string-utf8 100), 
    description: (string-utf8 500),
    creator: principal, 
    yes-votes: uint, 
    no-votes: uint, 
    executed: bool, 
    cancelled: bool,
    starts-at: uint,
    ends-at: uint,
    execution-time: uint,
    proposal-type: (string-ascii 20)
  }
)

(define-map stakes principal uint)
(define-map has-voted {proposal-id: uint, voter: principal} bool)
(define-map vote-delegation principal principal) ;; delegator -> delegate
(define-map delegated-power principal uint) ;; delegate -> total power from delegators

;; Stake STX to gain voting power
(define-public (stake (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set stakes tx-sender (+ (default-to u0 (map-get? stakes tx-sender)) amount))
    (var-set total-staked (+ (var-get total-staked) amount))
    (ok amount)
  )
)

;; Unstake STX
(define-public (unstake (amount uint))
  (let ((current-stake (default-to u0 (map-get? stakes tx-sender))))
    (asserts! (>= current-stake amount) ERR_AMOUNT_EXCEEDS_STAKE)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set stakes tx-sender (- current-stake amount))
    (var-set total-staked (- (var-get total-staked) amount))
    (ok amount)
  )
)

;; Delegate voting power to another address
(define-public (delegate-vote (delegate principal))
  (let ((my-stake (default-to u0 (map-get? stakes tx-sender))))
    ;; Remove from previous delegate if any
    (match (map-get? vote-delegation tx-sender)
      prev-delegate
      (map-set delegated-power prev-delegate 
        (- (default-to u0 (map-get? delegated-power prev-delegate)) my-stake))
      true)
    ;; Add to new delegate
    (map-set vote-delegation tx-sender delegate)
    (map-set delegated-power delegate 
      (+ (default-to u0 (map-get? delegated-power delegate)) my-stake))
    (ok true)
  )
)

;; Remove delegation
(define-public (revoke-delegation)
  (let ((my-stake (default-to u0 (map-get? stakes tx-sender))))
    (match (map-get? vote-delegation tx-sender)
      delegate
      (begin
        (map-set delegated-power delegate 
          (- (default-to u0 (map-get? delegated-power delegate)) my-stake))
        (map-delete vote-delegation tx-sender)
        (ok true))
      (ok true))
  )
)

;; Create a proposal with description and type
(define-public (create-proposal (title (string-utf8 100)) (description (string-utf8 500)) (proposal-type (string-ascii 20)))
  (let ((id (+ (var-get proposal-count) u1)))
    (asserts! (>= (get-voting-power tx-sender) (var-get min-stake)) ERR_BELOW_MIN_STAKE)
    (map-set proposals id {
      title: title,
      description: description,
      creator: tx-sender,
      yes-votes: u0,
      no-votes: u0,
      executed: false,
      cancelled: false,
      starts-at: block-height,
      ends-at: (+ block-height VOTING_PERIOD),
      execution-time: (+ block-height VOTING_PERIOD EXECUTION_DELAY),
      proposal-type: proposal-type
    })
    (var-set proposal-count id)
    (ok id)
  )
)

;; Vote yes on proposal
(define-public (vote-yes (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
    (voting-power (get-voting-power tx-sender))
  )
    (asserts! (< block-height (get ends-at proposal)) ERR_VOTING_ENDED)
    (asserts! (not (default-to false (map-get? has-voted {proposal-id: proposal-id, voter: tx-sender}))) ERR_ALREADY_VOTED)
    (asserts! (>= voting-power (var-get min-stake)) ERR_BELOW_MIN_STAKE)
    (map-set has-voted {proposal-id: proposal-id, voter: tx-sender} true)
    (map-set proposals proposal-id (merge proposal {yes-votes: (+ (get yes-votes proposal) voting-power)}))
    (ok voting-power)
  )
)

;; Vote no on proposal
(define-public (vote-no (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
    (voting-power (get-voting-power tx-sender))
  )
    (asserts! (< block-height (get ends-at proposal)) ERR_VOTING_ENDED)
    (asserts! (not (default-to false (map-get? has-voted {proposal-id: proposal-id, voter: tx-sender}))) ERR_ALREADY_VOTED)
    (asserts! (>= voting-power (var-get min-stake)) ERR_BELOW_MIN_STAKE)
    (map-set has-voted {proposal-id: proposal-id, voter: tx-sender} true)
    (map-set proposals proposal-id (merge proposal {no-votes: (+ (get no-votes proposal) voting-power)}))
    (ok voting-power)
  )
)

;; Execute a passed proposal (after timelock)
(define-public (execute-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
  )
    (asserts! (> block-height (get ends-at proposal)) ERR_VOTING_ACTIVE)
    (asserts! (>= block-height (get execution-time proposal)) ERR_TIMELOCK_NOT_PASSED)
    (asserts! (not (get executed proposal)) ERR_ALREADY_EXECUTED)
    (asserts! (not (get cancelled proposal)) ERR_NOT_AUTHORIZED)
    (asserts! (has-quorum proposal-id) ERR_NO_QUORUM)
    (asserts! (> (get yes-votes proposal) (get no-votes proposal)) ERR_PROPOSAL_FAILED)
    (map-set proposals proposal-id (merge proposal { executed: true }))
    (var-set proposals-passed (+ (var-get proposals-passed) u1))
    (ok true)
  )
)

;; Cancel proposal (creator only, before execution)
(define-public (cancel-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get creator proposal)) ERR_NOT_AUTHORIZED)
    (asserts! (not (get executed proposal)) ERR_ALREADY_EXECUTED)
    (map-set proposals proposal-id (merge proposal { cancelled: true }))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-proposal (id uint))
  (map-get? proposals id)
)

(define-read-only (get-stake (user principal))
  (default-to u0 (map-get? stakes user))
)

(define-read-only (get-voting-power (user principal))
  (+ 
    (default-to u0 (map-get? stakes user))
    (default-to u0 (map-get? delegated-power user))
  )
)

(define-read-only (get-delegate (user principal))
  (map-get? vote-delegation user)
)

(define-read-only (get-proposal-count)
  (var-get proposal-count)
)

(define-read-only (get-total-staked)
  (var-get total-staked)
)

(define-read-only (get-dao-stats)
  {
    total-proposals: (var-get proposal-count),
    proposals-passed: (var-get proposals-passed),
    proposals-failed: (var-get proposals-failed),
    total-staked: (var-get total-staked),
    min-stake: (var-get min-stake)
  }
)

(define-read-only (has-quorum (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal
    (let (
      (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
      (quorum-threshold (/ (* (var-get total-staked) QUORUM_PERCENTAGE) u100))
    )
      (>= total-votes quorum-threshold))
    false
  )
)

(define-read-only (get-proposal-state (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal
    (if (get cancelled proposal)
      "cancelled"
      (if (get executed proposal)
        "executed"
        (if (< block-height (get ends-at proposal))
          "active"
          (if (not (has-quorum proposal-id))
            "no-quorum"
            (if (<= (get yes-votes proposal) (get no-votes proposal))
              "defeated"
              (if (< block-height (get execution-time proposal))
                "queued"
                "ready"))))))
    "not-found"
  )
)

(define-read-only (is-voting-active (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (< block-height (get ends-at proposal))
    false
  )
)

(define-read-only (get-time-remaining (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal
    (if (>= block-height (get ends-at proposal))
      u0
      (- (get ends-at proposal) block-height))
    u0
  )
)
