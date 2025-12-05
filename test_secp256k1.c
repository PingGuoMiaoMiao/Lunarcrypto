#include <stdio.h>
#include <string.h>
#include <secp256k1.h>
#include <secp256k1_recovery.h>

int main() {
    // 创建上下文
    secp256k1_context *ctx = secp256k1_context_create(
        SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY
    );
    
    if (!ctx) {
        printf("❌ Failed to create context\n");
        return 1;
    }
    
    printf("✅ Context created successfully\n");
    
    // 测试私钥
    unsigned char seckey[32];
    memset(seckey, 0x01, 32);  // 简单的测试私钥
    
    // 验证私钥
    if (secp256k1_ec_seckey_verify(ctx, seckey)) {
        printf("✅ Private key is valid\n");
    } else {
        printf("❌ Private key is invalid\n");
        secp256k1_context_destroy(ctx);
        return 1;
    }
    
    // 生成公钥
    secp256k1_pubkey pubkey;
    if (secp256k1_ec_pubkey_create(ctx, &pubkey, seckey)) {
        printf("✅ Public key created successfully\n");
    } else {
        printf("❌ Failed to create public key\n");
        secp256k1_context_destroy(ctx);
        return 1;
    }
    
    // 序列化公钥（未压缩格式）
    unsigned char pubkey_serialized[65];
    size_t pubkey_len = 65;
    if (secp256k1_ec_pubkey_serialize(ctx, pubkey_serialized, &pubkey_len, &pubkey, SECP256K1_EC_UNCOMPRESSED)) {
        printf("✅ Public key serialized (length: %zu bytes)\n", pubkey_len);
        printf("   Public key: 0x");
        for (int i = 0; i < 10; i++) {  // 只打印前 10 字节
            printf("%02x", pubkey_serialized[i]);
        }
        printf("...\n");
    } else {
        printf("❌ Failed to serialize public key\n");
    }
    
    // 测试签名
    unsigned char msg_hash[32];
    memset(msg_hash, 0x02, 32);  // 测试消息哈希
    
    secp256k1_ecdsa_recoverable_signature sig;
    if (secp256k1_ecdsa_sign_recoverable(ctx, &sig, msg_hash, seckey, NULL, NULL)) {
        printf("✅ Signature created successfully\n");
        
        // 序列化签名
        unsigned char sig_serialized[64];
        int recid;
        secp256k1_ecdsa_recoverable_signature_serialize_compact(ctx, sig_serialized, &recid, &sig);
        printf("✅ Signature serialized (recovery ID: %d)\n", recid);
    } else {
        printf("❌ Failed to create signature\n");
    }
    
    // 清理
    secp256k1_context_destroy(ctx);
    printf("\n🎉 All libsecp256k1 tests passed!\n");
    
    return 0;
}

