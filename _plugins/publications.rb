# frozen_string_literal: true

module IQMLab
  # One shared source per paper drives both languages and every year archive.
  class Publications < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      sources = site.pages.select { |page| page.relative_path.match?(%r!\Apublications/paper/[1-9]\d*\.md\z!) }
      site.pages -= sources

      site.data["publications"] = sources.map do |source|
        publication = source.data.dup
        publication["number"] = source.basename.to_i
        publication.delete("page")

        publication["urls"] = urls("paper/#{publication['number']}/")
        %w[zh en].each { |lang| add_detail_page(site, source, publication, lang) }

        publication
      end.sort_by { |publication| -publication["number"] }

      site.data["publication_index_urls"] = urls
      site.data["publication_years"] = site.data["publications"].map { |pub| pub.fetch("year") }.uniq.sort.reverse.map do |year|
        archive = { "year" => year, "urls" => urls("#{year}/") }
        %w[zh en].each { |lang| add_year_page(site, archive, lang) }
        archive
      end
    end

    private

    def urls(suffix = "")
      { "zh" => "/publications/#{suffix}", "en" => "/en/publications/#{suffix}" }
    end

    def page_data(url, lang)
      {
        "lang" => lang,
        "nav_id" => "publications",
        "translation_path" => url.delete_prefix("/en/").delete_prefix("/"),
        "permalink" => url
      }
    end

    def add_year_page(site, archive, lang)
      url = archive["urls"].fetch(lang)
      index_url = urls.fetch(lang)
      index = site.pages.find { |page| page.url == index_url }
      raise "Missing publication index: #{index_url}" unless index

      year = archive.fetch("year")
      page = Jekyll::PageWithoutAFile.new(site, site.source, url.delete_prefix("/"), "index.html")
      page.data.merge!(index.data)
      page.data.merge!(page_data(url, lang))
      page.data.merge!(
        "year" => year,
        "title" => lang == "en" ? "#{year} Publications | IQM Lab" : "#{year} 年论文 | 智能量子材料课题组",
        "heading" => lang == "en" ? "#{year} Publications" : "#{year} 年论文列表"
      )
      site.pages << page
    end

    def add_detail_page(site, source, publication, lang)
      url = publication["urls"].fetch(lang)
      directory = url.delete_prefix("/")
      detail = Jekyll::PageWithoutAFile.new(site, site.source, directory, "index.md")
      detail.content = source.content
      detail.data.merge!(page_data(url, lang))
      detail.data.merge!(
        "layout" => "publication",
        "title" => publication["title"],
        "description" => publication["summary"],
        "publication" => publication
      )
      site.pages << detail
    end
  end
end
