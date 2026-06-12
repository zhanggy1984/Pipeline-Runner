# Pipeline Runner

半自动软件工程流水线——输入任务描述，自动完成 **设计 → 拆分 → 编码 → 测试 → 审查 → 修复闭环** 全流程。

仅在技术方案方向确认、A 级高风险任务、不可自动修复的失败时暂停。

## 安装

```bash
# Windows (PowerShell)
.\install.ps1           # 首次安装
.\install.ps1 -Force    # 覆盖已有 skill

# Linux / macOS
chmod +x install.sh
./install.sh            # 首次安装
./install.sh --force    # 覆盖已有 skill
```

## 快速开始

```
/pipeline-runner full "实现积分账本查询功能，支持分页和筛选"   # 自然语言描述
/pipeline-runner full docs/prd.md                              # 本地 PRD 文件
/pipeline-runner full https://example.com/prd.md               # 远程 PRD URL
```

三种方式启动全流程。之后你只需要：
1. 确认技术方案方向（2-3 个方案中选 1 个）
2. 偶尔在遇到 A 级任务或不可自动修复的问题时做决策

其他一切自动化——任务拆分、并行编码、测试生成、安全/性能/代码审查、自动修复。

### 从中间阶段恢复

```
/pipeline-runner from-split     # 设计已完成，从任务拆分继续
/pipeline-runner from-code      # 任务已拆分，从编码继续
/pipeline-runner from-test      # 编码已完成，从测试继续
/pipeline-runner from-review    # 测试已完成，从审查继续
/pipeline-runner status         # 查看当前进度
/pipeline-runner reset          # 重置状态，重新开始
```

## 流水线阶段

```
/pipeline-runner full "任务描述"
     │
     ├─ P1: DESIGN  方案设计         [暂停: 确认方向 + 确认详细设计]
     │     支持 自然语言 / 本地PRD / 远程URL 三种输入
     │     solution-design 协同完成技术方案 (2次确认)
     │     输出: .claude/workflow/solution.md
     │
     ├─ P2: SPLIT   任务拆分         自动
     │     task-splitter 拆分为可并行任务
     │     输出: .claude/workflow/tasks/INDEX.md + task-*.md
     │
     ├─ P3: CODE    并行编码         自动 (A级暂停)
     │     多个 backend/frontend-coder 子 Agent 并行
     │     构建验证硬门禁 (mvn compile / npm run build)
     │     输出: task-*.done + 编译通过的代码
     │
     ├─ P4: TEST    测试生成执行      自动
     │     test-master 生成测试 → 反模式预检 → 运行
     │     输出: tests/test-index.md + 测试结果
     │
     ├─ P5: REVIEW  审查 + 修复闭环   自动 (needs-human暂停)
     │     code-review + security + perf 并行审查
     │     发现分类 → auto-fix loop (max 3轮) → 交叉校验
     │     输出: review.done
     │
     └─ P6: DONE   汇总报告
           pipeline.done
```

## 用户介入点（仅 5 个）

| # | 时机 | 触发条件 |
|---|------|---------|
| 1 | DESIGN | 宏观方案方向选择（2-3 选 1） |
| 2 | DESIGN | 详细设计确认（数据模型、API、测试场景审查） |
| 3 | CODE | 遇到 A 级任务（DB DDL、MQ 消费者、核心计算等） |
| 4 | CODE | 构建失败且自动修复无效 |
| 5 | REVIEW | 审查发现架构级/安全级问题，不能自动修复 |

一个中等复杂度的功能（5-8 个任务），通常需介入 **2-3 次**。

## 安装的 Skill

| Skill | 用途 |
|-------|------|
| `/pipeline-runner` | 流水线编排器（入口） |
| `/solution-design` | 协同技术方案设计 |
| `/task-splitter` | 全自动任务拆分 |
| `/backend-coder` | 后端编码 (Spring Boot / MyBatis-Plus) |
| `/frontend-coder` | 前端编码 (React / Vue) |
| `/test-master` | 全自动测试生成执行 |
| `/code-reviewer-agent` | 独立代码审查 |
| `/security-reviewer` | 安全审查 (OWASP Top 10) |
| `/perf-reviewer` | 性能审查 (N+1, 索引, 包体积) |

每个 skill 也可以独立使用，不限于流水线模式。

## Sub-Agent 并发与交叉校验

### 并行编码
不同分支（Backend/Frontend）的任务零文件冲突时，同时启动多个子 Agent 并行编码，完成后自动合并验证。

### 并行审查
代码审查、安全审查、性能审查三个子 Agent 同时启动，互不干扰。

### 交叉校验
修复后重新审查时，每个审查 Agent 会收到上一轮其他审查维度的发现摘要，验证修复是否引入新问题。

### 反模式预检
测试生成时，独立子 Agent 审查 tests/test-index.md 草稿，检查覆盖缺口和反模式。

## 目录结构

```
\claude-auto-dev-kit\
├── README.md
├── install.ps1                     # Windows 安装
├── install.sh                      # Linux/macOS 安装
└── skills/
    ├── workflow/pipeline-runner.md
    ├── design/solution-design.md
    ├── planning/task-splitter.md
    ├── coding/backend-coder.md
    ├── coding/frontend-coder.md
    ├── testing/test-master.md
    └── review/
        ├── code-reviewer-agent.md
        ├── security-reviewer.md
        └── perf-reviewer.md
```

## 工作目录 (.claude/workflow/)

流水线运行时在项目根目录下生成：

| 文件 | 写入者 | 说明 |
|------|--------|------|
| `prd.md` | pipeline-runner | 输入预处理后的 PRD（来自文件或 URL） |
| `solution.md` | solution-design | 技术方案 + 测试场景 |
| `project-context.md` | coder skill | 项目扫描缓存 |
| `tasks/INDEX.md` | task-splitter | 任务概览 + 依赖图 + 并行组 |
| `tasks/task-N.md` | task-splitter | 单个任务规格 |
| `tasks/task-N.done` | coder skill | 任务完成标记 |
| `pipeline-state.md` | pipeline-runner | 流水线状态 |
| `tests/test-index.md` | test-master | 测试清单 (Draft → ✔ Final) |
| `review.done` | pipeline-runner | 审查完成标记 |
| `pipeline.done` | pipeline-runner | 流水线完成标记 |
