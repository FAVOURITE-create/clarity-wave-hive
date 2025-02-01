import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new track with licensing terms",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const title = "My First Track";
        const licensePrice = 1000;
        const licenseDuration = 100;
        
        let block = chain.mineBlock([
            Tx.contractCall('wave-hive', 'create-track', [
                types.utf8(title),
                types.uint(licensePrice),
                types.uint(licenseDuration)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let getTrack = chain.callReadOnlyFn(
            'wave-hive',
            'get-track-details',
            [types.uint(1)],
            deployer.address
        );
        
        const trackData = getTrack.result.expectSome().expectTuple();
        assertEquals(trackData['creator'], deployer.address);
        assertEquals(trackData['title'], title);
        assertEquals(trackData['license-price'], licensePrice);
        assertEquals(trackData['license-duration'], licenseDuration);
    }
});

Clarinet.test({
    name: "Can purchase and verify license",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const licensee = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('wave-hive', 'create-track', [
                types.utf8("Licensed Track"),
                types.uint(1000),
                types.uint(100)
            ], deployer.address),
            
            Tx.contractCall('wave-hive', 'purchase-license', [
                types.uint(1),
                types.utf8("Commercial usage rights")
            ], licensee.address)
        ]);
        
        block.receipts[1].result.expectOk().expectUint(1);
        
        let getLicense = chain.callReadOnlyFn(
            'wave-hive',
            'get-license-details',
            [types.uint(1)],
            licensee.address
        );
        
        const licenseData = getLicense.result.expectSome().expectTuple();
        assertEquals(licenseData['licensee'], licensee.address);
        assertEquals(licenseData['track-id'], 1);
        
        let checkValidity = chain.callReadOnlyFn(
            'wave-hive',
            'is-license-valid',
            [types.uint(1)],
            licensee.address
        );
        
        checkValidity.result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can propose and accept collaboration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const collaborator = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('wave-hive', 'create-track', [
                types.utf8("Collab Track"),
                types.uint(1000),
                types.uint(100)
            ], deployer.address),
            
            Tx.contractCall('wave-hive', 'propose-collab', [
                types.uint(1),
                types.principal(collaborator.address),
                types.uint(30)
            ], deployer.address)
        ]);
        
        block.receipts.forEach(receipt => {
            receipt.result.expectOk();
        });
        
        let acceptBlock = chain.mineBlock([
            Tx.contractCall('wave-hive', 'accept-collab', [
                types.uint(1)
            ], collaborator.address)
        ]);
        
        acceptBlock.receipts[0].result.expectOk();
        
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
