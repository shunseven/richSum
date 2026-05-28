# 🎉 新春派对大富翁（Summer Engine 移植版）

基于 [Summer Engine / Godot 4.6](https://www.summerengine.com/) 的马里奥派对风格大富翁游戏，从 LeaferJS H5 版本（[richRain](https://github.com/shunseven/richRain)）完整迁移过来。

## 🎮 玩法

- **24 格环形棋盘**：起点 / 事件 / 系统 / 金币 / NPC / 普通六类格子
- **3D 骰子**：SubViewport 渲染，6 面贴图，多圈翻滚后落定
- **回合制**：投骰 → 移动 → 落地结算 → 切玩家 → 胜负判定
- **11 种系统事件**：瞬移、换位、星价升降、抽币、新增星等
- **金币事件**：−3 ~ +8 金币随机滚动
- **NPC 遭遇**：8 种 NPC 互动（捶背 / 跳舞 / 讨红包 / 加码大奖 / 再摇一次 等）
- **永久 / 一次性星星**：可购买，价格随系统事件升降
- **小游戏阶段**：每轮末抽取，玩家手动点选最多 3 名胜者
- **最后三轮**：BGM 加速 + 全员 +1 永久星
- **5 个编辑器**：角色 / NPC / 随机事件 / NPC 事件 / 小游戏 / 最终大奖
- **存档**：游戏进度自动保存到 `user://saves/rr_game_progress.json`

## 🛠️ 技术栈

- **引擎**：Summer Engine (Godot 4.6)
- **语言**：GDScript
- **背景**：JPG 帧序列循环（替代 H5 的 mp4）
- **音频**：AudioStreamGenerator 程序合成 BGM/SFX

## 🚀 运行

用 Summer Engine 打开 `project.godot`，点击 ▶ 运行，主场景为 `res://scenes/Boot.tscn`。

## 📂 目录结构

```
.
├── assets/             # 素材（角色头像 / 背景 / 帧序列）
├── data/               # 默认 JSON 数据（角色 / NPC / 事件 / 小游戏 / 大奖）
├── scenes/             # .tscn 场景
├── scripts/
│   ├── autoload/       # GameStore / SaveSystem / AudioBus / EventDB / SceneRouter
│   ├── scenes/         # 各场景控制脚本
│   ├── systems/        # BoardSpec 棋盘规格
│   └── ui/             # UIUtil / EditorUI / VideoBg / Dice3D
└── project.godot
```

## 🧪 端到端跑测

在 `user://`（macOS: `~/Library/Application Support/Godot/app_userdata/新春派对大富翁/`）下创建空文件 `auto_run`，启动游戏会自动跳过菜单，开始 3 轮自动驾驶对局，并把每回合状态写入 `user://e2e.log`。
