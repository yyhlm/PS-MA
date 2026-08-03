# 论文实验代码

论文《Online Learning Framework for Distributed Selection Problems》的实验代码。


## 结构

- `EdgeComputing/`：移动边缘计算（MEC）应用
- `TCP/`：多路径 TCP 应用
- `data/`：论文中使用的实验结果文件

两种应用各对比五种算法：
`psma`、`hlinucb`、`tsicf`、`gcl`、`glmucb`。

## 运行 1000-seed 实验

### EdgeComputing

```matlab
cd('EdgeComputing');        % 在仓库根目录（code/）打开 MATLAB 后
addpath(genpath('.'));

config = allm_config();                 % S=1000, T=2000, K=50, d=10, M=5
campaign = run_allm_campaign(config);   % 单个正式 campaign
% 或运行全部预注册场景：
run_allm_scenario_suite();
```

多进程分片并行（单进程太慢时）：

```matlab
run_allm_shard(allm_config(), 1, 4);    % 分别开 4 个 MATLAB 跑 shard 1..4
% 全部 shard 完成后合并：
merge_allm_shards(allm_config(), 4);
```

### TCP

```matlab
cd('TCP');                  % 在仓库根目录（code/）打开 MATLAB 后
addpath(genpath('.'));

config = tcp_four_method_config();      % S=1000
comparison = run_comparison(config);
% 或一键全跑：
run_all_tcp_full();
```
