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

;; Data Variables
(define-data-var next-track-id uint u1)
(define-data-var next-license-id uint u1)
(define-data-var total-royalties uint u0)

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

;; Collaboration Proposals
(define-map collaboration-proposals
    {track-id: uint, collaborator: principal}
    {
        proposed-by: principal,
        royalty-share: uint,
        status: (string-ascii 20)
    }
)

;; Distribute Royalties
(define-public (distribute-royalties (track-id uint))
    (let
        (
            (track-data (unwrap! (map-get? tracks track-id) err-not-authorized))
            (earnings (get total-earnings track-data))
            (collaborators (get collaborators track-data))
            (royalties (get royalties track-data))
        )
        (asserts! (> earnings u0) err-invalid-royalty-split)
        (try! (distribute-to-collaborators track-id collaborators royalties earnings))
        (ok true)
    )
)

;; Helper function for royalty distribution
(define-private (distribute-to-collaborators (track-id uint) (collaborators (list 10 principal)) (royalties (list 10 uint)) (total uint))
    (let
        (
            (shares-sum (fold + royalties u0))
        )
        (asserts! (is-eq shares-sum u100) err-invalid-royalty-split)
        (ok (map distribute-share collaborators royalties))
    )
)

;; Transfer License
(define-public (transfer-license (license-id uint) (recipient principal))
    (let
        (
            (license-data (unwrap! (map-get? licenses license-id) err-not-authorized))
        )
        (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? license license-id) err-not-authorized)) err-not-authorized)
        (asserts! (get transferable license-data) err-not-authorized)
        (try! (nft-transfer? license license-id tx-sender recipient))
        (ok true)
    )
)

[Previous functions remain unchanged...]
