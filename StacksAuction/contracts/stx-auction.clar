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
(define-constant ERR-INVALID-DURATION (err u108))
(define-constant ERR-RESERVE-NOT-MET (err u109))
(define-constant ERR-AUCTION-IN-PROGRESS (err u110))
(define-constant ERR-INVALID-NAME-LENGTH (err u111))
(define-constant ERR-INVALID-RESERVE-PRICE (err u112))

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
    ;; Check that the sender is authorized
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-AUTHORIZED)
    ;; Check that the auction hasn't started yet
    (asserts! (is-eq (var-get auction-start-block) u0) ERR-AUCTION-ALREADY-STARTED)
    ;; Check that the duration is valid
    (asserts! (> duration u0) ERR-INVALID-DURATION)
    ;; Check that the item name is not empty and is within the 50-character limit
    (asserts! (> (len name) u0) ERR-INVALID-NAME-LENGTH)
    (asserts! (<= (len name) u50) ERR-INVALID-NAME-LENGTH)
    ;; Check that the minimum price is positive
    (asserts! (> min-price u0) ERR-INVALID-RESERVE-PRICE)
    ;; Initialize auction variables
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
    ;; Ensure auction has started
    (asserts! (> (var-get auction-start-block) u0) ERR-AUCTION-NOT-STARTED)
    ;; Ensure auction hasn't ended
    (asserts! (< block-height (var-get auction-end-block)) ERR-AUCTION-ENDED)
    ;; Ensure bid is valid
    (asserts! (>= offer min-valid-bid) ERR-BID-TOO-LOW)
    ;; Transfer the bid and update top-bidder
    (match (stx-transfer? offer tx-sender (as-contract tx-sender))
      success
        (match (var-get top-bidder)
          previous-leader 
            (begin
              (try! (as-contract (stx-transfer? current-offer (as-contract tx-sender) previous-leader)))
              (var-set top-bid offer)
              (var-set top-bidder (some tx-sender))
              (ok true))
          (begin
            (var-set top-bid offer)
            (var-set top-bidder (some tx-sender))
            (ok true)))
      error ERR-TRANSFER-FAILED)))

;; Function to end the auction and transfer funds to the owner
(define-public (conclude-auction)
  (begin
    ;; Ensure auction has ended
    (asserts! (>= block-height (var-get auction-end-block)) ERR-AUCTION-NOT-ENDED)
    ;; Ensure there's a valid bid
    (asserts! (is-some (var-get top-bidder)) ERR-NO-BIDS)
    ;; Ensure reserve price is met
    (asserts! (>= (var-get top-bid) (var-get reserve-price)) ERR-RESERVE-NOT-MET)
    ;; Transfer funds to the owner
    (match (var-get top-bidder)
      auction-winner
        (as-contract (stx-transfer? (var-get top-bid) (as-contract tx-sender) (var-get owner)))
      ERR-NO-BIDS)))

;; Function to cancel the auction (only by owner, only if no bids)
(define-public (cancel-auction)
  (begin
    ;; Check if sender is owner
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-AUTHORIZED)
    ;; Check that no bids have been placed
    (asserts! (is-none (var-get top-bidder)) ERR-AUCTION-IN-PROGRESS)
    ;; Reset auction data
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
