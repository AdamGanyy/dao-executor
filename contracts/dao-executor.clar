;; ------------------------------------------------------------
;; dao-executor.clar
;; DAO Contract for STX Transfers
;; ------------------------------------------------------------

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-ALREADY-EXECUTED (err u2))
(define-constant ERR-NO-PROPOSAL (err u3))
(define-constant ERR-INVALID-AMOUNT (err u4))

;; Status values
(define-constant STATUS-PENDING u0)
(define-constant STATUS-EXECUTED u1)

;; Contract state
(define-data-var owner principal tx-sender)
(define-data-var next-id uint u0)

;; Proposal structure
(define-map dao-proposals
  uint
  {
    proposer: principal,
    recipient: principal,
    amount: uint,
    status: uint
  }
)

;; Internal functions
(define-private (is-owner)
  (is-eq tx-sender (var-get owner)))

(define-private (is-valid-amount (amount uint))
  (> amount u0))

;; Read only functions
(define-read-only (get-owner)
  (var-get owner))

(define-read-only (get-proposal-count)
  (var-get next-id))

(define-read-only (get-proposal (id uint))
  (map-get? dao-proposals id))

;; Public functions
(define-public (transfer-ownership)
  (begin
    (asserts! (is-owner) ERR-UNAUTHORIZED)
    (ok true)))

(define-public (create-proposal (to principal) (amount uint))
  (begin
    (asserts! (is-owner) ERR-UNAUTHORIZED)
    (asserts! (is-valid-amount amount) ERR-INVALID-AMOUNT)
    (let 
      ((id (+ (var-get next-id) u1))
       (new-proposal {
          proposer: tx-sender,
          recipient: to,
          amount: amount,
          status: STATUS-PENDING
       }))
      (var-set next-id id)
      (map-set dao-proposals id new-proposal)
      (ok id))))

(define-public (execute-proposal (id uint))
  (let ((proposal (unwrap! (map-get? dao-proposals id) ERR-NO-PROPOSAL)))
    (begin
      (asserts! (is-owner) ERR-UNAUTHORIZED)
      (asserts! (not (is-eq (get status proposal) STATUS-EXECUTED)) ERR-ALREADY-EXECUTED)
      (try! (stx-transfer? 
              (get amount proposal)
              tx-sender
              (get recipient proposal)))
      (map-set dao-proposals id
        (merge proposal { status: STATUS-EXECUTED }))
      (ok true))))
