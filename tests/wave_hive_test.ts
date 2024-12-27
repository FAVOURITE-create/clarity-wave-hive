import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new track",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const title = "My First Track";
        
        let block = chain.mineBlock([
            Tx.contractCall('wave-hive', 'create-track', [
                types.utf8(title)
            ], deployer.address)
        ]);
        
        // Verify transaction success
        block.receipts[0].result.expectOk().expectUint(1);
        
        // Check track details
        let getTrack = chain.callReadOnlyFn(
            'wave-hive',
            'get-track-details',
            [types.uint(1)],
            deployer.address
        );
        
        const trackData = getTrack.result.expectSome().expectTuple();
        assertEquals(trackData['creator'], deployer.address);
        assertEquals(trackData['title'], title);
    }
});

Clarinet.test({
    name: "Can propose and accept collaboration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const collaborator = accounts.get('wallet_1')!;
        
        // Create track first
        let block = chain.mineBlock([
            Tx.contractCall('wave-hive', 'create-track', [
                types.utf8("Collab Track")
            ], deployer.address),
            
            // Propose collaboration
            Tx.contractCall('wave-hive', 'propose-collab', [
                types.uint(1),
                types.principal(collaborator.address),
                types.uint(30) // 30% royalty share
            ], deployer.address)
        ]);
        
        block.receipts.forEach(receipt => {
            receipt.result.expectOk();
        });
        
        // Accept collaboration
        let acceptBlock = chain.mineBlock([
            Tx.contractCall('wave-hive', 'accept-collab', [
                types.uint(1)
            ], collaborator.address)
        ]);
        
        acceptBlock.receipts[0].result.expectOk();
        
        // Verify collaboration details
        let getTrack = chain.callReadOnlyFn(
            'wave-hive',
            'get-track-details',
            [types.uint(1)],
            deployer.address
        );
        
        const trackData = getTrack.result.expectSome().expectTuple();
        const collaborators = trackData['collaborators'].expectList();
        assertEquals(collaborators.length, 2);
    }
});