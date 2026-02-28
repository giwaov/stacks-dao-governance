;; DAO Governance V2 - Simplified voting without staking (for mainnet deployment)

(define-data-var proposal-count uint u0)

(define-map proposals 
  uint 
  {title: (string-utf8 100), creator: principal, yes-votes: uint, no-votes: uint}
)

(define-map has-voted {proposal-id: uint, voter: principal} bool)

;; Create a proposal (costs 0.1 STX fee)
(define-public (create-proposal (title (string-utf8 100)))
  (let ((id (+ (var-get proposal-count) u1)))
    (try! (stx-transfer? u100000 tx-sender 'SP3E0DQAHTXJHH5YT9TZCSBW013YXZB25QFDVXXWY))
    (map-set proposals id {
      title: title,
      creator: tx-sender,
      yes-votes: u0,
      no-votes: u0
    })
    (var-set proposal-count id)
    (ok id)
  )
)

;; Vote yes (costs 0.01 STX)
(define-public (vote-yes (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) (err u1))))
    (asserts! (not (default-to false (map-get? has-voted {proposal-id: proposal-id, voter: tx-sender}))) (err u2))
    (try! (stx-transfer? u10000 tx-sender 'SP3E0DQAHTXJHH5YT9TZCSBW013YXZB25QFDVXXWY))
    (map-set has-voted {proposal-id: proposal-id, voter: tx-sender} true)
    (map-set proposals proposal-id (merge proposal {yes-votes: (+ (get yes-votes proposal) u1)}))
    (ok true)
  )
)

;; Vote no (costs 0.01 STX)
(define-public (vote-no (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) (err u1))))
    (asserts! (not (default-to false (map-get? has-voted {proposal-id: proposal-id, voter: tx-sender}))) (err u2))
    (try! (stx-transfer? u10000 tx-sender 'SP3E0DQAHTXJHH5YT9TZCSBW013YXZB25QFDVXXWY))
    (map-set has-voted {proposal-id: proposal-id, voter: tx-sender} true)
    (map-set proposals proposal-id (merge proposal {no-votes: (+ (get no-votes proposal) u1)}))
    (ok true)
  )
)

;; Read-only
(define-read-only (get-proposal (id uint))
  (map-get? proposals id)
)

(define-read-only (get-proposal-count)
  (var-get proposal-count)
)

(define-read-only (has-user-voted (proposal-id uint) (user principal))
  (default-to false (map-get? has-voted {proposal-id: proposal-id, voter: user}))
)
