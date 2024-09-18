;; Auction Smart Contract

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AUCTION-ALREADY-STARTED (err u101))
(define-constant ERR-AUCTION-NOT-STARTED (err u102))
(define-constant ERR-AUCTION-ENDED (err u103))
(define-constant ERR-BID-TOO-LOW (err u104))
(define-constant ERR-TRANSFER-FAILED (err u105))
(define-constant ERR-AUCTION-NOT-ENDED (err u106))
(define-constant ERR-NO-BIDS (err u107))

;; Define the data for the auction
(define-data-var top-bid uint u0)
(define-data-var top-bidder (optional principal) none)
(define-data-var auction-start-block uint u0)
(define-data-var auction-end-block uint u0)
(define-data-var owner principal tx-sender)
(define-data-var item-name (string-ascii 50) "")
(define-data-var reserve-price uint u0)

;; Define a constant for minimum bid increment
(define-constant BID-STEP u1000000) ;; 1 STX

;; Function to start the auction
(define-public (initialize-auction (duration uint) (name (string-ascii 50)) (min-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (var-get auction-start-block) u0) ERR-AUCTION-ALREADY-STARTED)
    (asserts! (> duration u0) (err u108))
    (var-set auction-start-block block-height)
    (var-set auction-end-block (+ block-height duration))
    (var-set item-name name)
    (var-set reserve-price min-price)
    (ok true)))

;; Function to place a bid
(define-public (submit-bid (offer uint))
  (let (
    (current-offer (var-get top-bid))
    (min-valid-bid (if (> current-offer (var-get reserve-price))
                       (+ current-offer BID-STEP)
                       (var-get reserve-price))))
    (asserts! (> (var-get auction-start-block) u0) ERR-AUCTION-NOT-STARTED)
    (asserts! (< block-height (var-get auction-end-block)) ERR-AUCTION-ENDED)
    (asserts! (>= offer min-valid-bid) ERR-BID-TOO-LOW)
    (match (stx-transfer? offer tx-sender (as-contract tx-sender))
      success
        (begin
          (match (var-get top-bidder)
            previous-leader 
              (match (as-contract (stx-transfer? current-offer (as-contract tx-sender) previous-leader))
                refund-success (begin
                  (var-set top-bid offer)
                  (var-set top-bidder (some tx-sender))
                  (ok true))
                refund-error (begin
                  (unwrap-panic (as-contract (stx-transfer? offer (as-contract tx-sender) tx-sender)))
                  ERR-TRANSFER-FAILED))
            )
            (begin
              (var-set top-bid offer)
              (var-set top-bidder (some tx-sender))
              (ok true)))
        )
      error ERR-TRANSFER-FAILED)))

;; Function to end the auction and transfer funds to the owner
(define-public (conclude-auction)
  (begin
    (asserts! (>= block-height (var-get auction-end-block)) ERR-AUCTION-NOT-ENDED)
    (asserts! (is-some (var-get top-bidder)) ERR-NO-BIDS)
    (asserts! (>= (var-get top-bid) (var-get reserve-price)) (err u109))
    (match (var-get top-bidder)
      auction-winner
        (match (as-contract (stx-transfer? (var-get top-bid) (as-contract tx-sender) (var-get owner)))
          transfer-success (ok true)
          transfer-error ERR-TRANSFER-FAILED)
      ERR-NO-BIDS)))

;; Function to cancel the auction (only by owner, only if no bids)
(define-public (cancel-auction)
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (var-get top-bidder)) (err u110))
    (var-set auction-start-block u0)
    (var-set auction-end-block u0)
    (var-set top-bid u0)
    (var-set top-bidder none)
    (ok true)))

;; Read-only functions
(define-read-only (query-top-bid)
  (ok (var-get top-bid)))

(define-read-only (query-top-bidder)
  (ok (var-get top-bidder)))

(define-read-only (query-auction-end)
  (ok (var-get auction-end-block)))

(define-read-only (query-item-name)
  (ok (var-get item-name)))

(define-read-only (query-reserve-price)
  (ok (var-get reserve-price)))

(define-read-only (query-auction-status)
  (if (< block-height (var-get auction-start-block))
      (ok "Not started")
      (if (< block-height (var-get auction-end-block))
          (ok "In progress")
          (ok "Ended"))))