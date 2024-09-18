;; Define the data for the auction
(define-data-var top-bid uint u0)
(define-data-var top-bidder (optional principal) none)
(define-data-var auction-close-block uint u0)
(define-data-var owner principal tx-sender)

;; Define a constant for minimum bid increment
(define-constant BID-STEP u1000000) ;; 1 STX

;; Function to start the auction
(define-public (initialize-auction (blocks-active uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err u100))
    (asserts! (is-eq (var-get auction-close-block) u0) (err u101))
    (var-set auction-close-block (+ block-height blocks-active))
    (ok true)))

;; Function to place a bid
(define-public (submit-bid (offer uint))
  (let ((current-offer (var-get top-bid)))
    (asserts! (< block-height (var-get auction-close-block)) (err u200))
    (asserts! (> offer (+ current-offer BID-STEP)) (err u201))
    (match (stx-transfer? offer tx-sender (as-contract tx-sender))
      success
        (begin
          (match (var-get top-bidder)
            previous-leader (as-contract (stx-transfer? current-offer (as-contract tx-sender) previous-leader))
            true)
          (var-set top-bid offer)
          (var-set top-bidder (some tx-sender))
          (ok true))
      error (err u202))))

;; Function to end the auction and transfer funds to the creator
(define-public (conclude-auction)
  (begin
    (asserts! (>= block-height (var-get auction-close-block)) (err u300))
    (asserts! (is-some (var-get top-bidder)) (err u301))
    (match (var-get top-bidder)
      auction-winner
        (begin
          (as-contract (stx-transfer? (var-get top-bid) (as-contract tx-sender) (var-get owner)))
          (ok true))
      (err u302))))

;; Read-only function to get the current highest bid
(define-read-only (query-top-bid)
  (ok (var-get top-bid)))

;; Read-only function to get the current highest bidder
(define-read-only (query-top-bidder)
  (ok (var-get top-bidder)))

;; Read-only function to get the auction end height
(define-read-only (query-auction-close)
  (ok (var-get auction-close-block)))