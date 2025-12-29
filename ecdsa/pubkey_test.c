// 测试程序：验证 secp256k1_pubkey 的正确用法
#include <stdio.h>
#include <string.h>
#include <secp256k1.h>

int main() {
    // 创建上下文
    secp256k1_context *ctx = secp256k1_context_create(
        SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY
    );
    
    // 测试私钥（全1）
    unsigned char seckey[32];
    memset(seckey, 0x01, 32);
    
    // 验证私钥
    if (!secp256k1_ec_seckey_verify(ctx, seckey)) {
        printf("❌ Private key invalid\n");
        return 1;
    }
    printf("✅ Private key valid\n");
    
    // 创建公钥（内部格式，64字节）
    secp256k1_pubkey pubkey;
    if (!secp256k1_ec_pubkey_create(ctx, &pubkey, seckey)) {
        printf("❌ Failed to create public key\n");
        return 1;
    }
    printf("✅ Public key created\n");
    printf("   Internal format size: %zu bytes\n", sizeof(secp256k1_pubkey));
    
    // 序列化为未压缩格式（65字节）
    unsigned char output[65];
    size_t outputlen = 65;
    if (!secp256k1_ec_pubkey_serialize(ctx, output, &outputlen, &pubkey, SECP256K1_EC_UNCOMPRESSED)) {
        printf("❌ Failed to serialize\n");
        return 1;
    }
    
    printf("✅ Public key serialized (%zu bytes)\n", outputlen);
    printf("   First 10 bytes: ");
    for (int i = 0; i < 10; i++) {
        printf("%02x", output[i]);
    }
    printf("...\n");
    
    // 关键：打印 pubkey 的原始字节，看看内部格式
    printf("\n🔍 Internal pubkey structure (first 32 bytes):\n   ");
    unsigned char *pubkey_bytes = (unsigned char*)&pubkey;
    for (int i = 0; i < 32; i++) {
        printf("%02x", pubkey_bytes[i]);
    }
    printf("...\n");
    
    secp256k1_context_destroy(ctx);
    return 0;
}

