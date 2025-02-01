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

;; Data Variables
(define-data-var next-track-id uint u1)
(define-data-var next-license-id uint u1)

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
        license-duration: uint
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
        usage-rights: (string-utf8 256)
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

;; Create Track
(define-public (create-track (title (string-utf8 256)) (license-price uint) (license-duration uint))
    (let 
        (
            (track-id (var-get next-track-id))
        )
        (asserts! (not (nft-get-owner? track track-id)) err-track-exists)
        (try! (nft-mint? track track-id tx-sender))
        (map-set tracks track-id {
            creator: tx-sender,
            title: title,
            timestamp: block-height,
            collaborators: (list tx-sender),
            royalties: (list u100),
            license-price: license-price,
            license-duration: license-duration
        })
        (var-set next-track-id (+ track-id u1))
        (ok track-id)
    )
)

;; Purchase License
(define-public (purchase-license (track-id uint) (usage-rights (string-utf8 256)))
    (let
        (
            (track-data (unwrap! (map-get? tracks track-id) err-not-authorized))  
            (license-id (var-get next-license-id))
            (duration (get license-duration track-data))
        )
        (asserts! (> duration u0) err-invalid-license-duration)
        (try! (stx-transfer? (get license-price track-data) tx-sender contract-owner))
        (try! (nft-mint? license license-id tx-sender))
        
        (map-set licenses license-id {
            track-id: track-id,
            licensee: tx-sender,
            start-block: block-height,
            end-block: (+ block-height duration),
            usage-rights: usage-rights
        })
        
        (var-set next-license-id (+ license-id u1))
        (ok license-id)
    )
)

;; Check License Validity
(define-read-only (is-license-valid (license-id uint))
    (let
        (
            (license-data (unwrap! (map-get? licenses license-id) err-not-authorized))
        )
        (ok (< block-height (get end-block license-data)))
    )
)

;; Get License Details
(define-read-only (get-license-details (license-id uint))
    (map-get? licenses license-id)
)

;; Propose Collaboration
(define-public (propose-collab (track-id uint) (collaborator principal) (royalty-share uint))
    (let
        (
            (track-data (unwrap! (map-get? tracks track-id) err-not-authorized))
        )
        (asserts! (is-eq (get creator track-data) tx-sender) err-not-authorized)
        (asserts! (<= royalty-share u100) err-invalid-percentage)
        (map-set collaboration-proposals 
            {track-id: track-id, collaborator: collaborator}
            {
                proposed-by: tx-sender,
                royalty-share: royalty-share,
                status: "pending"
            }
        )
        (ok true)
    )
)

;; Accept Collaboration
(define-public (accept-collab (track-id uint))
    (let
        (
            (proposal (unwrap! (map-get? collaboration-proposals {track-id: track-id, collaborator: tx-sender}) err-no-proposal))
            (track-data (unwrap! (map-get? tracks track-id) err-not-authorized))
            (current-collaborators (get collaborators track-data))
            (current-royalties (get royalties track-data))
        )
        (asserts! (is-eq (get status proposal) "pending") err-not-authorized)
        (map-set tracks track-id {
            creator: (get creator track-data),
            title: (get title track-data),
            timestamp: (get timestamp track-data),
            collaborators: (append current-collaborators tx-sender),
            royalties: (append current-royalties (get royalty-share proposal)),
            license-price: (get license-price track-data),
            license-duration: (get license-duration track-data)
        })
        (map-set collaboration-proposals 
            {track-id: track-id, collaborator: tx-sender}
            {
                proposed-by: (get proposed-by proposal),
                royalty-share: (get royalty-share proposal),
                status: "accepted"
            }
        )
        (ok true)
    )
)

;; Read Only Functions
(define-read-only (get-track-details (track-id uint))
    (map-get? tracks track-id)
)

(define-read-only (get-collab-proposal (track-id uint) (collaborator principal))
    (map-get? collaboration-proposals {track-id: track-id, collaborator: collaborator})
)
