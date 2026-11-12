# 喵伴 (EchoEar) 小智固件 — 带乐鑫底座全功能

基于 `esp-friends/esp-vocat` 的 `esp_vocat` 板型编译的**小智固件**，在原有底座功能基础上补齐了乐鑫最新底座的磁吸事件。

**主体**: ESP32-S3 (N16R8, 16MB Flash) · **底座**: ESP32-C61 (固件独立，不在本仓库)

## 目录

| 目录 | 内容 |
|---|---|
| `firmware/` | 可直接烧录的 6 个 `.bin` |
| `patch/` | 相对官方 `esp-vocat` 的源码补丁 |
| `flash.bat` | Windows 一键烧录脚本 |

## 烧录

### 地址表 (必须照抄)

| 文件 | 地址 |
|---|---|
| `bootloader.bin` | `0x0` |
| `partition-table.bin` | `0x8000` |
| `ota_data_initial.bin` | `0xd000` |
| `xiaozhi.bin` | `0x10000` |
| `expression_assets.bin` | `0x5ec000` |
| `srmodels.bin` | `0xbc8000` |

**ESP Flash Download Tool 设置**

| 项 | 值 |
|---|---|
| Chip | `ESP32-S3` |
| Port | 你看到的串口 |
| Baud | `460800` |
| Erase all flash before writing | ✅ 勾选 (从扣子固件换过来时必勾) |
| Flash Size | `16 MB` |
| SPI Speed | `80 MHz` |
| SPI Mode | `DIO` |

或命令行:

```bash
python -m esptool --chip esp32s3 -p COM5 -b 460800 \
  --before default_reset --after hard_reset \
  write_flash --flash_mode dio --flash_size 16MB --flash_freq 80m \
  0x0       bootloader.bin \
  0x8000    partition-table.bin \
  0xd000    ota_data_initial.bin \
  0x10000   xiaozhi.bin \
  0x5ec000  expression_assets.bin \
  0xbc8000  srmodels.bin
```

> **路径必须是纯英文**，老版 flash tool 读不了中文路径。

## 烧后验证顺序

1. 上电 → 底座做零位校准 (左转碰限位后右转约 95° 回中)
2. 串口日志出现 `Echo base connected` → UART 通信正常
3. 唤醒后底座跟随声源转动 → DOA 正常
4. 语音「摇摇头」→ 触发底座动作
5. 拨滑块上/下 → 切换聊天状态
6. 装/卸磁吸件 → 播放对应表情

## 源码修改

补丁相对 `gitee.com/esp-friends/esp-vocat`:

```bash
git clone https://gitee.com/esp-friends/esp-vocat.git
cd esp-vocat
git apply patch/base_control_full_events.diff
```

补齐的事件 (原实现仅 5 类):

- 小鱼干 / 冰淇淋 / 甜甜圈 卸下 → `neutral`
- 冰淇淋 / 甜甜圈 装上 → `eat` 动画
- 磁吸件从上/下方装入 → `insert` 动画
- 磁吸件从上/下方取下 → `neutral`
- 手机倚靠底座前部 → happy + 环顾
- 手机从底座下方放入/取出 → `insert` / `neutral`

## 编译 (可选)

```bash
# 需要 ESP-IDF >= 5.5
export IDF_COMPONENT_REGISTRY_URL=https://components.espressif.com/
cd examples/xiaozhi-esp32
python scripts/release.py esp_vocat
idf.py set-target esp32s3
idf.py build
```

`sdkconfig` 关键项 (脚本已自动生成):

| 项 | 值 | 作用 |
|---|---|---|
| `CONFIG_BOARD_TYPE_ESP_VOCAT` | `y` | 喵伴板型 |
| `CONFIG_FLASH_EXPRESSION_ASSETS` | `y` | **用本地 `.eaf` 表情包，不联网** |
| `CONFIG_USE_EMOTE_MESSAGE_STYLE` | `y` | **底座功能开关，不开则事件静默失效** |

## 注意

**PCB 版本**: `main/boards/esp_vocat/config.h` 的 `SELECT_BOARD` 是**源码宏**，不是 menuconfig 项。V1_0 与 V1_2 的底座 UART / 触摸 GPIO 不同。本固件按 **V1_2** 编译。若刷完「能对话但底座不动、触摸不好使」，先确认此项。

## 边界

- 底座 (ESP32-C61) 固件独立于 `gitee.com/esp-friends/esp-vocat-base`，不在本仓库
- CSI 近场感知串口命令乐鑫尚未开放，未实现
- 线性霍尔底座硬件上仅 2 个磁吸事件，无法补齐