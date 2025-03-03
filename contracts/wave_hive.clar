;; WaveHive - Music Collaboration Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-track-exists (err u102))
(define-constant err-invalid-percentage (err u103))
(define-constant err-no-proposal (err u104))
(define-constant err-invalid-license-duration (err u105))
(define-constant err-license-expired (err u106))
(define-constant err-invalid-royalty-split (err u107))
(define-constant err-transfer-failed (err u108))
(define-constant err-invalid-recipient (err u109))
(define-constant err-paused (err u110))

;; Data Variables
(define-data-var next-track-id uint u1)
(define-data-var next-license-id uint u1)
(define-data-var total-royalties uint u0)
(define-data-var contract-paused bool false)

;; Events
(define-data-var last-distribution-block uint u0)

;; Define NFTs
(define-non-fungible-token track uint)
(define-non-fungible-token license uint)

;; Track Data
(define-map tracks 
    uint 
    {
        creator: principal,
        title: (string-utf8 256),
        timestamp: uint,
        collaborators: (list 10 principal),
        royalties: (list 10 uint),
        license-price: uint,
        license-duration: uint,
        total-earnings: uint
    }
)

;; License Data
(define-map licenses
    uint
    {
        track-id: uint,
        licensee: principal,
        start-block: uint,
        end-block: uint,
        usage-rights: (string-utf8 256),
        transferable: bool
    }
)

;; Administrative Functions
(define-public (pause-contract)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-paused true)
        (ok true)
    )
)

(define-public (unpause-contract)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-paused false)
        (ok true)
    )
)

;; Enhanced Distribute Royalties
(define-public (distribute-royalties (track-id uint))
    (let
        (
            (track-data (unwrap! (map-get? tracks track-id) err-not-authorized))
            (earnings (get total-earnings track-data))
            (collaborators (get collaborators track-data))
            (royalties (get royalties track-data))
        )
        (asserts! (not (var-get contract-paused)) err-paused)
        (asserts! (> earnings u0) err-invalid-royalty-split)
        (asserts! (>= block-height (+ (var-get last-distribution-block) u1)) err-not-authorized)
        
        ;; Perform distribution
        (try! (distribute-to-collaborators track-id collaborators royalties earnings))
        
        ;; Update state
        (var-set last-distribution-block block-height)
        (print {event: "royalties-distributed", track-id: track-id, amount: earnings})
        (ok true)
    )
)

;; Enhanced distribution helper
(define-private (distribute-to-collaborators (track-id uint) (collaborators (list 10 principal)) (royalties (list 10 uint)) (total uint))
    (let
        (
            (shares-sum (fold + royalties u0))
        )
        (asserts! (is-eq shares-sum u100) err-invalid-royalty-split)
        (map distribute-share collaborators royalties)
        (ok true)
    )
)

;; Enhanced share distribution
(define-private (distribute-share (recipient principal) (share uint))
    (let
        (
            (amount (/ (* total share) u100))
        )
        (if (and (> amount u0) (is-some recipient))
            (try! (stx-transfer? amount tx-sender recipient))
            false
        )
    )
)

[Previous functions remain unchanged...]
