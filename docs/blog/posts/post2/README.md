# 费城公寓博客：Quarto 版本

这份 `index.qmd` 按截图中的格式编排：YAML 标题、日期、categories，以及 Markdown 正文。分类改为 housing 和 web scraping；正文加入小标题，保留已核实的数据、两张图和代码附录。

## 放进你现有的网站

1. 解压后打开 `post2` 文件夹。
2. 将里面的 `index.qmd`、`figures`、`data`、`R`、`setup.R`、`run.R` 和 `README.md` 一起复制到你网站的 `blog/posts/post2/` 文件夹，替换现有的占位 `index.qmd`。
3. 在 RStudio 中打开你原来的网站项目，再打开 `blog/posts/post2/index.qmd`。
4. 点击 **Render**。这篇文章会继承你网站已有的主题和导航。文中图片使用相对于文章的路径，所以不要只复制 qmd 文件。

包里的 `index.html` 是用 Quarto 随附的 Pandoc 生成的基础预览，可以直接打开。标准 Quarto 主题渲染需要写入系统缓存，本次未获得该目录权限，因此这里没有验证你网站主题的最终效果。正文已通过 Pandoc 解析，图片已嵌入预览；加入现有网站后，由 RStudio 的 Render 生成正式页面。`preview.css` 仅用于基础预览，不影响你的 qmd 网站主题。

## 重跑 R 分析

渲染文章不需要执行 R，也不会重新抓取网站；代码附录使用普通 R 代码块展示。若要复现分析，请在 RStudio 的 Console 中把工作目录设到这篇文章的 `post2` 文件夹，然后执行：

```r
source("run.R")
```

首次缺少的包会安装到项目的 `.R-library/` 中。默认使用 `data/snapshots/` 保存的真实 HTML 事实表格摘录，通过 rvest 提取，重建清理数据和图表。

实时抓取逻辑在 `R/01_scrape.R` 中：复抓前检查当前网站规则；命令行添加 `--live` 才会请求新页面。它会顺序请求、等待两秒，并在访问受限或 robots 规则变化时停止。新价格可能不同，因此刷新数据后须重新核对 `index.qmd` 的数字、结论及日期。

## 研究口径

数据抓取于 2026-09-21，共 21 个物业项目、59 条户型记录；16 个普通一卧一卫户型有数字租金，进入比较。排除其他卧室数、Junior、带书房/复式以及无数字报价的记录。来源、原文、清理结果、排除原因和 R 版本均保存在 `data/`。

研究仅涉及 Galman Group 在费城目录 HTML 中链接的物业，排除了 Jenkintown 推广链接。地区按物业页位置标题归类，Northeast Philadelphia 合并若干社区。价格为基础月起租价，未核实空房，不含统一计算的其他费用；不能代表全费城租房市场。

原始网站：https://galmangroup.com/philadelphia/

本次只是修改并验证本地 Quarto 文件，尚未发布到你的线上博客或 GitHub 仓库。
