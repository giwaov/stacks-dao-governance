;; DAO Governance Contract - Simple proposal voting with STX staking
;; Deployed on Stacks Mainnet

(define-data-var proposal-count uint u0)
(define-data-var min-stake uint u100000) ;; 0.1 STX minimum stake to vote

(define-map proposals 
  uint 
  {title: (string-utf8 100), creator: principal, yes-votes: uint, no-votes: uint, executed: bool, ends-at: uint}
)

(define-map stakes principal uint)
(define-map has-voted {proposal-id: uint, voter: principal} bool)

;; Stake STX to gain voting power
(define-public (stake (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set stakes tx-sender (+ (default-to u0 (map-get? stakes tx-sender)) amount))
    (ok amount)
  )
)

;; Unstake STX
(define-public (unstake (amount uint))
  (let ((current-stake (default-to u0 (map-get? stakes tx-sender))))
    (asserts! (>= current-stake amount) (err u1))
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set stakes tx-sender (- current-stake amount))
    (ok amount)
  )
)

;; Create a proposal
(define-public (create-proposal (title (string-utf8 100)))
  (let ((id (+ (var-get proposal-count) u1)))
    (asserts! (>= (default-to u0 (map-get? stakes tx-sender)) (var-get min-stake)) (err u2))
    (map-set proposals id {
      title: title,
      creator: tx-sender,
      yes-votes: u0,
      no-votes: u0,
      executed: false,
      ends-at: (+ block-height u144) ;; ~1 day
    })
    (var-set proposal-count id)
    (ok id)
  )
)

;; Vote yes on proposal
(define-public (vote-yes (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) (err u3)))
    (stake-amount (default-to u0 (map-get? stakes tx-sender)))
  )
    (asserts! (not (default-to false (map-get? has-voted {proposal-id: proposal-id, voter: tx-sender}))) (err u4))
    (asserts! (>= stake-amount (var-get min-stake)) (err u5))
    (map-set has-voted {proposal-id: proposal-id, voter: tx-sender} true)
    (map-set proposals proposal-id (merge proposal {yes-votes: (+ (get yes-votes proposal) stake-amount)}))
    (ok true)
  )
)

;; Vote no on proposal
(define-public (vote-no (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) (err u3)))
    (stake-amount (default-to u0 (map-get? stakes tx-sender)))
  )
    (asserts! (not (default-to false (map-get? has-voted {proposal-id: proposal-id, voter: tx-sender}))) (err u4))
    (asserts! (>= stake-amount (var-get min-stake)) (err u5))
    (map-set has-voted {proposal-id: proposal-id, voter: tx-sender} true)
    (map-set proposals proposal-id (merge proposal {no-votes: (+ (get no-votes proposal) stake-amount)}))
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

(define-read-only (get-proposal-count)
  (var-get proposal-count)
)
