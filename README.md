# WaveHive

A decentralized music collaboration platform built on Stacks blockchain. WaveHive enables musicians to:

- Create and own music tracks as NFTs
- Collaborate with other artists
- Split royalties automatically through smart contracts
- Trade and license music rights
- Manage time-based licensing with automated validation

## Features

- NFT-based music track ownership
- Collaboration proposals and acceptance
- Automatic royalty distribution
- Advanced licensing system
  - Time-based license validity
  - Usage rights tracking
  - NFT-based license ownership
  - Automated license validation
- Collaboration history tracking

## Getting Started

1. Install Clarinet
2. Clone the repository
3. Run tests: `clarinet test`
4. Deploy contract using Clarinet console

## Contract Functions

- create-track: Create a new music track NFT with licensing terms
- propose-collab: Propose a collaboration on a track
- accept-collab: Accept a collaboration proposal
- purchase-license: Purchase a time-based license for a track
- is-license-valid: Check if a license is currently valid
- get-license-details: Get detailed information about a license
- get-track-details: Get track information including licensing terms

## Licensing System

The new licensing system enables:

1. Track creators to set license prices and durations
2. Users to purchase time-limited licenses as NFTs
3. Automatic validation of license validity
4. Tracking of usage rights and terms
5. Secure transfer of licensing fees to track owners

## License Types

- Commercial Usage
- Personal Use
- Streaming Rights
- Remix Rights
- Synchronization Rights

Each license includes:
- Start and end block heights
- Usage rights specification
- Automated validity checking
- NFT-based ownership proof
