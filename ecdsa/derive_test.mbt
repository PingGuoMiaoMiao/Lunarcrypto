///|
/// 测试公钥派生的完整流程
test "derive pubkey - full flow" {
  let flags = 0x0301
  let ctx = secp256k1_context_create(flags)

  // 测试私钥（全1）
  let seckey = FixedArray::make(32, b'\x01')

  // 1. 创建公钥（内部格式，64字节）
  let pubkey_internal = FixedArray::make(64, b'\x00')
  let create_result = secp256k1_ec_pubkey_create(ctx, pubkey_internal, seckey)
  inspect(create_result == 1, content="true")

  // 2. 序列化为未压缩格式（65字节）
  let output = FixedArray::make(65, b'\x00')
  let outputlen = FixedArray::make(1, 65U)
  let serialize_result = secp256k1_ec_pubkey_serialize(
    ctx, output, outputlen, pubkey_internal, 0x0002, // SECP256K1_EC_UNCOMPRESSED
  )
  inspect(serialize_result == 1, content="true")
  inspect(output[0] == b'\x04', content="true") // 未压缩格式前缀
  inspect(outputlen[0] == 65U, content="true")
  secp256k1_context_destroy(ctx)
}

///|
test "derive pubkey - compressed format" {
  let flags = 0x0301
  let ctx = secp256k1_context_create(flags)
  let seckey = FixedArray::make(32, b'\x01')

  // 创建公钥
  let pubkey_internal = FixedArray::make(64, b'\x00')
  let _ = secp256k1_ec_pubkey_create(ctx, pubkey_internal, seckey)

  // 序列化为压缩格式（33字节）
  let output = FixedArray::make(33, b'\x00')
  let outputlen = FixedArray::make(1, 33U)
  let serialize_result = secp256k1_ec_pubkey_serialize(
    ctx, output, outputlen, pubkey_internal, 0x0102, // SECP256K1_EC_COMPRESSED
  )
  inspect(serialize_result == 1, content="true")
  // 压缩格式前缀应该是 0x02 或 0x03
  inspect(output[0] == b'\x02' || output[0] == b'\x03', content="true")
  inspect(outputlen[0] == 33U, content="true")
  secp256k1_context_destroy(ctx)
}
