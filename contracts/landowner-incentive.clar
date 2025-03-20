;; Landowner Incentive Contract
;; Manages payments for conservation participation

;; Define token for incentive payments (using STX for simplicity)
(define-fungible-token conservation-token)

;; Initial token mint for the contract
(begin
  (try! (ft-mint? conservation-token u1000000000 tx-sender))
)

;; Data structure for incentive programs
(define-map incentive-programs
  uint
  {
    name: (string-utf8 64),
    rate-per-area: uint,        ;; tokens per square meter
    min-duration: uint,         ;; minimum easement duration in blocks
    active: bool,
    total-budget: uint,         ;; total tokens allocated
    remaining-budget: uint      ;; tokens remaining
  }
)

;; Data structure for incentive payments
(define-map incentive-payments
  {easement-id: uint, payment-date: uint}
  {
    owner: principal,
    amount: uint,
    program-id: uint
  }
)

;; Create a new incentive program
(define-public (create-incentive-program
                (name (string-utf8 64))
                (rate-per-area uint)
                (min-duration uint)
                (budget uint))
  (let ((program-id (+ (var-get last-program-id) u1)))
    (asserts! (> budget u0) (err u1))

    (map-set incentive-programs program-id {
      name: name,
      rate-per-area: rate-per-area,
      min-duration: min-duration,
      active: true,
      total-budget: budget,
      remaining-budget: budget
    })

    (var-set last-program-id program-id)
    (ok program-id)
  )
)

;; Process payment for an easement
(define-public (process-payment (easement-id uint) (program-id uint) (parcel-area uint) (easement-duration uint))
  (let ((program (unwrap! (map-get? incentive-programs program-id) (err u405))))

    ;; Check program is active
    (asserts! (get active program) (err u407))

    ;; Check easement meets minimum duration
    (asserts! (>= easement-duration (get min-duration program)) (err u408))

    ;; Calculate payment amount based on parcel area and program rate
    (let ((payment-amount (calculate-payment parcel-area (get rate-per-area program))))

      ;; Check sufficient budget
      (asserts! (>= (get remaining-budget program) payment-amount) (err u409))

      ;; Record the payment
      (map-set incentive-payments
               {easement-id: easement-id, payment-date: block-height}
               {owner: tx-sender, amount: payment-amount, program-id: program-id})

      ;; Update program budget
      (map-set incentive-programs program-id
               (merge program {remaining-budget: (- (get remaining-budget program) payment-amount)}))

      ;; Transfer tokens to easement owner
      (try! (ft-transfer? conservation-token payment-amount tx-sender tx-sender))

      (ok payment-amount)
    )
  )
)

;; Calculate payment amount
(define-private (calculate-payment (area uint) (rate uint))
  (* area rate)
)

;; Get program details
(define-read-only (get-program (program-id uint))
  (map-get? incentive-programs program-id)
)

;; Get payment for a specific easement (only returns the first one found)
(define-read-only (get-payment-for-easement (easement-id uint))
  ;; This is a simplified version that doesn't use map-to-list
  ;; It just checks if a payment exists for the easement ID and the current block height
  (map-get? incentive-payments {easement-id: easement-id, payment-date: block-height})
)

;; Data variables
(define-data-var last-program-id uint u0)

