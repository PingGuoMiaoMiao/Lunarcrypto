///|
/// libsecp256k1 FFI 实际调用测试

///|
/// 测试 1: 创建和销毁上下文
test "ffi call - context lifecycle" {
  let flags = 0x0301 // SIGN | VERIFY
  let ctx = secp256k1_context_create(flags)

  // 如果能到这里，说明调用成功
  inspect(true, content="true")

  // 清理
  secp256k1_context_destroy(ctx)
  inspect(true, content="true")
}

///|
/// 测试 2: 验证私钥
test "ffi call - verify private key" {
  let flags = 0x0301
  let ctx = secp256k1_context_create(flags)

  // 创建一个简单的测试私钥（全1）
  let seckey = FixedArray::make(32, b'\x01')

  // 验证私钥
  let result = secp256k1_ec_seckey_verify(ctx, seckey)

  // 应该返回 1（有效）
  inspect(result == 1, content="true")

  // 清理
  secp256k1_context_destroy(ctx)
}
