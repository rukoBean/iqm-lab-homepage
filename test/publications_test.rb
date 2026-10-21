# frozen_string_literal: true

require "minitest/autorun"
require "jekyll"
require "tmpdir"
require "fileutils"
require "yaml"
require_relative "../_plugins/publications"

class PublicationsTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def setup
    @directory = Dir.mktmpdir("iqm-publications-test-")
    @source = File.join(@directory, "source")
    @destination = File.join(@directory, "output")
    FileUtils.mkdir_p(File.join(@source, "_data"))
    %w[_includes _layouts].each { |path| FileUtils.cp_r(File.join(ROOT, path), @source) }
    FileUtils.cp(File.join(ROOT, "_data/i18n.yml"), File.join(@source, "_data/i18n.yml"))

    write("pubs/10.md", {
      "title" => "Study of La<sub>3</sub>Ni<sub>2</sub>O<sub>7</sub>",
      "venue" => "Example Journal 12, 345",
      "year" => 2026,
      "label" => [{ "zh" => "编辑推荐", "en" => "Editors’ Suggestion" },
                  { "zh" => "封面论文", "en" => "Cover Article" }],
      "authors" => [{ "name" => "First Author" }, { "name" => "Our Author", "ours" => true }],
      "doi" => "10.1234/example",
      "paper" => "pdfs/example paper.pdf",
      "cover" => { "image" => "assets/cover.png" },
      "summary" => "A short description."
    }, "## Research details\n\nA **formatted** article body.\n")
    write("pubs/3.md", { "title" => "Whitespace body", "year" => 2025,
                          "doi" => "https://doi.org/10.1234/full-url",
                          "page" => "https://example.org/should-be-ignored" }, " \n\t\n")
    write("pubs/2.md", { "title" => "Front matter only", "year" => 2026,
                          "venue" => nil, "label" => [{ "zh" => "", "en" => nil }],
                          "authors" => [{ "name" => " " }], "doi" => " ", "paper" => "",
                          "cover" => { "image" => nil }, "summary" => " " })
    %w[zh en].each do |lang|
      prefix = lang == "en" ? "en/" : ""
      write("#{prefix}publications/index.html", { "layout" => "publications", "lang" => lang })
      write("#{prefix}publications/2026/index.html", { "layout" => "publications", "lang" => lang, "year" => 2026 })
    end

    @site = Jekyll::Site.new(Jekyll.configuration(
      "source" => @source, "destination" => @destination, "baseurl" => "/lab",
      "url" => "https://example.org", "quiet" => true, "disable_disk_cache" => true
    ))
    @site.process
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_numeric_order_year_filtering_and_localized_labels
    assert_equal [10, 3, 2], @site.data["publications"].map { |publication| publication["number"] }
    %w[zh en].each do |lang|
      prefix = lang == "en" ? "en/" : ""
      list = html("#{prefix}publications/index.html")
      assert_equal %w[pub-10 pub-3 pub-2], list.scan(/<article[^>]*id="([^"]+)"/).flatten
      expected_labels = lang == "en" ? ["Editors’ Suggestion", "Cover Article"] : ["编辑推荐", "封面论文"]
      publication = article(list, 10)
      assert_equal expected_labels, publication.scan(/<span class="badge star-badge">(.*?)<\/span>/).flatten
      assert_equal %w[pub-10 pub-2], html("#{prefix}publications/2026/index.html").scan(/<article[^>]*id="([^"]+)"/).flatten
      assert_equal %w[3 2 7], publication.scan(/<sub>(.*?)<\/sub>/).flatten
      assert_includes publication, '<strong class="pub-author-ours">Our Author</strong>'
      assert_includes publication, '<strong>Example Journal 12, 345</strong>'
      assert_includes publication, '<span class="pub-year">(2026)</span>'
    end
  end

  def test_optional_pages_render_markdown_and_keep_language_and_baseurl
    %w[zh en].each do |lang|
      prefix = lang == "en" ? "en/" : ""
      details_path = "#{prefix}pubs/10/index.html"
      assert File.file?(File.join(@destination, details_path))
      detail = html(details_path)
      assert_match(/<h2[^>]*>Research details<\/h2>/, detail)
      assert_includes detail, '<strong>formatted</strong>'
      assert_includes detail, '<title>Study of La3Ni2O7</title>'
      assert_match(/<h1><span class="pub-meta">.*?<\/span><a class="pub-title-link" href="https:\/\/doi.org\/10.1234\/example" target="_blank" rel="noopener">Study of La<sub>3<\/sub>Ni<sub>2<\/sub>O<sub>7<\/sub><\/a><\/h1>/, detail)
      assert_includes detail, "href=\"/lab/#{prefix}publications/#pub-10\""
      list = html("#{prefix}publications/index.html")
      assert_includes article(list, 10), "href=\"/lab/#{prefix}pubs/10/\""
      other_prefix = lang == "en" ? "" : "en/"
      assert_includes detail, "class=\"lang\" href=\"/lab/#{other_prefix}pubs/10/\""
      actions = detail[/<div class="pub-actions">(.*?)<\/div>/m, 1]
      refute_includes actions, "href=\"/lab/#{prefix}pubs/10/\""
      assert_equal ["PDF"], actions.scan(/<a\b[^>]*>(.*?)<\/a>/).flatten
      list_actions = article(list, 10)[/<div class="pub-actions">(.*?)<\/div>/m, 1]
      assert_equal [lang == "en" ? "Details" : "详情", "PDF"], list_actions.scan(/<a\b[^>]*>(.*?)<\/a>/).flatten
      [2, 3].each do |number|
        refute File.exist?(File.join(@destination, "#{prefix}pubs/#{number}/index.html"))
        refute File.exist?(File.join(@destination, "#{prefix}pubs/#{number}.html"))
      end
    end
  end

  def test_optional_links_metadata_and_empty_values
    list = html("en/publications/index.html")
    publication = article(list, 10)
    links = publication.scan(/<a[^>]*href="([^"]+)"[^>]*>([^<]+)<\/a>/).to_h { |href, text| [text, href] }
    assert_equal "/lab/pdfs/example%20paper.pdf", links["PDF"]
    assert_equal "/lab/en/pubs/10/", links["Details"]
    assert_equal %w[PDF Details].sort, links.keys.sort
    assert_includes publication, 'src="/lab/assets/cover.png"'
    assert_includes publication, '<p class="pub-summary">A short description.</p>'
    empty = article(list, 2)
    refute_match(/<a\b|class="badge|class="pub-authors|class="pub-cover|class="pub-summary|<strong>/, empty)
    assert_nil @site.data["publications"].find { |publication| publication["number"] == 3 }["page"]
  end

  def test_titles_link_to_doi_identifiers_and_full_urls_without_doi_buttons
    title = 'Study of La<sub>3</sub>Ni<sub>2</sub>O<sub>7</sub>'
    %w[publications/index.html publications/2026/index.html pubs/10/index.html].each do |path|
      ["", "en/"].each do |prefix|
        rendered = html("#{prefix}#{path}")
        assert_includes rendered, "<a class=\"pub-title-link\" href=\"https://doi.org/10.1234/example\" target=\"_blank\" rel=\"noopener\">#{title}</a>"
        refute_match(/<a\b[^>]*>DOI<\/a>/, rendered)
      end
    end
    ["", "en/"].each do |prefix|
      list = html("#{prefix}publications/index.html")
      assert_includes article(list, 3), '<a class="pub-title-link" href="https://doi.org/10.1234/full-url" target="_blank" rel="noopener">Whitespace body</a>'
      assert_includes article(list, 2), '<div class="pub-title">Front matter only</div>'
    end
  end

  private

  def write(path, data, body = "")
    target = File.join(@source, path)
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, "---\n#{YAML.dump(data).sub(/\A---\s*\n/, '')}---\n#{body}")
  end

  def html(path)
    File.read(File.join(@destination, path))
  end

  def article(html, number)
    html[/<article\b[^>]*id="pub-#{number}">(.*?)<\/article>/m, 1]
  end
end
