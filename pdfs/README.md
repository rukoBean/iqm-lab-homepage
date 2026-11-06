# 论文 PDF 存放目录

中英文页面共用此目录的 PDF。每篇论文只有一个源文件：
`publications/paper/<id>.md`。ID 永久保留，与发表年份无关；新增论文时选择下一个未使用的 ID。

PDF 文件名使用元数据中完整标题的可见文字（去除 HTML 格式标签、解码 HTML 实体），
统一为 Unicode NFKC 形式并转为小写，将连续的非字母、非数字字符替换为一个连字符，
去除首尾连字符，最后加上 `.pdf`。保留 Unicode 字母和数字，不缩短标题。
重命名前检查文件关联、大小写不敏感的文件名冲突、Windows 文件名及路径长度限制，避免覆盖文件。

例如 `Bilayer nickelates: A theoretical perspective` 对应
`bilayer-nickelates-a-theoretical-perspective.pdf`。

新增论文时，手动按上述规则命名 PDF，将其放入本目录，并在论文源文件中填写共享的根相对路径：

```yaml
paper: /pdfs/bilayer-nickelates-a-theoretical-perspective.pdf
```

源文件保留完整显示标题、作者、年份、期刊、DOI 和可选正文。运行 `jekyll build` 后，
自动生成 `/publications/paper/<id>/` 和 `/en/publications/paper/<id>/`，
以及相应年份的中英文列表和年份导航。无需英文论文副本、静态年份 Markdown 或自动 PDF 重命名。
