;; Conservation Easement Contract
;; Manages legal protection agreements

(define-data-var last-easement-id uint u0)

;; Data structure for conservation easements
(define-map easements
  uint
  {
    parcel-id: uint,
    owner: principal,
    start-date: uint,         ;; block height when easement starts
    duration: uint,           ;; duration in blocks (approximately)
    terms: (string-utf8 256), ;; legal terms hash or summary
    active: bool              ;; whether the easement is currently active
  }
)

;; Create a new conservation easement
(define-public (create-easement
                (parcel-id uint)
                (duration uint)
                (terms (string-utf8 256)))
  (let ((new-id (+ (var-get last-easement-id) u1)))
    ;; Duration must be reasonable (at least 1 year in blocks, ~52,560)
    (asserts! (> duration u52560) (err u400))

    (map-set easements new-id {
      parcel-id: parcel-id,
      owner: tx-sender,
      start-date: block-height,
      duration: duration,
      terms: terms,
      active: true
    })

    (var-set last-easement-id new-id)
    (ok new-id)
  )
)

;; Terminate an easement (only owner can do this)
(define-public (terminate-easement (easement-id uint))
  (let ((easement (unwrap! (map-get? easements easement-id) (err u404))))
    ;; Only owner can terminate
    (asserts! (is-eq tx-sender (get owner easement)) (err u403))

    ;; Update the easement to inactive
    (map-set easements easement-id (merge easement { active: false }))
    (ok true)
  )
)

;; Check if an easement is active
(define-read-only (is-easement-active (easement-id uint))
  (match (map-get? easements easement-id)
    easement (ok (get active easement))
    (err u404)
  )
)

;; Get easement details
(define-read-only (get-easement (easement-id uint))
  (map-get? easements easement-id)
)

;; Get easement for a specific parcel (only returns the first one found)
(define-read-only (get-easement-for-parcel (parcel-id uint))
  ;; This is a simplified version that doesn't use map-to-list
  ;; It just checks if easement ID 1 matches the parcel ID
  (let ((easement (map-get? easements u1)))
    (match easement
      e (if (is-eq (get parcel-id e) parcel-id)
            (ok e)
            (err u404))
      (err u404)
    )
  )
)

