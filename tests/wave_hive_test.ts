import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can distribute royalties correctly with security checks",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const collaborator = accounts.get('wallet_1')!;
        
        // Test contract pause
        let pauseBlock = chain.mineBlock([
            Tx.contractCall('wave-hive', 'pause-contract', [], deployer.address)
        ]);
        pauseBlock.receipts[0].result.expectOk();
        
        // Test distribution while paused
        let failedDistribution = chain.mineBlock([
            Tx.contractCall('wave-hive', 'distribute-royalties', [
                types.uint(1)
            ], deployer.address)
        ]);
        failedDistribution.receipts[0].result.expectErr(110); // err-paused
        
        // Unpause and test normal distribution
        let unpauseBlock = chain.mineBlock([
            Tx.contractCall('wave-hive', 'unpause-contract', [], deployer.address)
        ]);
        unpauseBlock.receipts[0].result.expectOk();
        
        // Create track and test distribution
        let block = chain.mineBlock([
            Tx.contractCall('wave-hive', 'create-track', [
                types.utf8("Royalty Track"),
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
        
        let distributeBlock = chain.mineBlock([
            Tx.contractCall('wave-hive', 'distribute-royalties', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        distributeBlock.receipts[0].result.expectOk();
    }
});

[Previous test cases remain unchanged...]
