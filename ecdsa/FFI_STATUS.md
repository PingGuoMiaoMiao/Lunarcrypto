# ECDSA FFI 实现状态

## ⚠️ 当前状态：等待 libsecp256k1 安装

### 🔧 FFI 语法问题

MoonBit 的 FFI 语法需要进一步研究。当前遇到的问题：

1. **不透明指针类型**: 需要找到正确的方式表示 C 指针
2. **extern "C" 语法**: 可能需要特定的格式
3. **参数注解**: 需要 `#borrow` 或 `#owned` 注解

### 📋 已创建的文件

```
ecdsa/
├── ffi.mbt        🚧 FFI 绑定（语法需要调整）
├── sign.mbt       ✅ 签名实现逻辑（等待 FFI）
├── verify.mbt     ✅ 验证实现逻辑（等待 FFI）
├── recovery.mbt   ✅ 恢复实现逻辑（等待 FFI）
└── keypair.mbt    ✅ 更新了 derive_public_key（等待 FFI）
```

## 🎯 两种前进方案

### 方案 A: 研究 MoonBit FFI 文档

需要：
1. 查阅 MoonBit 官方 FFI 文档
2. 找到示例代码
3. 调整 `ffi.mbt` 的语法

**优势**: 保持 FFI 路径（最快、最安全）  
**时间**: 需要研究 MoonBit FFI 文档

### 方案 B: 先实现纯 MoonBit 版本

暂时跳过 FFI，先实现：
1. 大整数库
2. 椭圆曲线运算
3. 纯 MoonBit 的 ECDSA

**优势**: 无外部依赖  
**时间**: 6-8 周

## 🚀 推荐行动

### 立即行动：安装 libsecp256k1

即使 FFI 语法需要调整，先安装库总是好的：

```bash
# Arch Linux
sudo pacman -Sy libsecp256k1

# 验证
pkg-config --modversion libsecp256k1
```

### 然后：研究 MoonBit FFI

1. **查看官方文档**
   ```bash
   moon doc --help
   # 或访问 https://docs.moonbitlang.com
   ```

2. **寻找 FFI 示例**
   ```bash
   # 查看标准库中的 FFI 示例
   find ~/.moon/lib/core -name "*.mbt" -exec grep -l "extern" {} \;
   ```

3. **咨询 MoonBit 社区**
   - GitHub Issues
   - Discord/社区论坛

## 📝 FFI 替代方案

如果 MoonBit 的 Native FFI 不可用，还有其他选项：

### 选项 1: WASM FFI
- 将 Rust `k256` 编译为 WASM
- 通过 WASM 导入使用

### 选项 2: 外部进程
- 创建独立的 C 程序
- 通过标准输入/输出通信

### 选项 3: 等待 MoonBit 更新
- MoonBit 还在快速发展
- FFI 支持可能会改进

## 💡 当前建议

1. **安装 libsecp256k1**（随时准备好）
2. **研究 MoonBit FFI 文档**
3. **如果 FFI 不可行，考虑纯 MoonBit 实现**

## 📞 需要帮助

如果你：
- 找到了 MoonBit FFI 的示例代码
- 有 MoonBit FFI 的文档链接
- 决定换成其他实现方案

请告诉我，我会立即调整实现！

---

**更新时间**: 2025-12-05  
**状态**: ⏸️ 等待 FFI 语法确认或选择替代方案

