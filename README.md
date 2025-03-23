# 链评系统 (ChainRate)

基于区块链技术的创新型校园课程评价平台，通过安全、透明的数据管理机制，构建学生、教师与教育管理者之间的信任桥梁。

## 项目架构

项目采用前后端分离的架构设计：

- **前端**：React.js + Ant Design + Web3.js
- **后端**：Node.js + Express + MySQL
- **区块链**：Ethereum + Hardhat + Solidity

## 项目结构

```
chainrate/
├── frontend/    # React前端应用
├── backend/     # Node.js后端API服务
└── contracts/   # Solidity智能合约
```

## 核心功能

1. **课程评价系统**
   - 多维度评分机制
   - 匿名评价功能
   - 实时反馈通道
   - 评价历史追踪

2. **教师评价系统**
   - 教学效果评估
   - 互动质量评价
   - 反馈响应机制
   - 改进建议收集

3. **数据分析系统**
   - 实时数据统计
   - 趋势分析报告
   - 对比分析功能
   - 预警提示机制

## 项目启动指南

### 前端(运行在8001端口)

```bash
cd chainrate-frontend
npm install
npm start
```

### 后端(运行在8000端口)

```bash
cd chainrate-backend
npm install
npm run dev
```

### 智能合约

```bash
cd chainrate-contracts
npm install
npx hardhat compile
npx hardhat test
```

## 贡献指南

请参阅每个子项目中的CONTRIBUTING.md文件。

## 许可证

MIT 