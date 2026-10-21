# frozen_string_literal: true

module IQMLab
  # Publication Markdown files are the source for the list and optional pages.
  class Publications < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      sources = site.pages.select { |page| page.relative_path.match?(%r!\Apubs/[1-9]\d*\.md\z!) }
      site.pages -= sources

      site.data["publications"] = sources.map do |source|
        publication = source.data.dup
        publication["number"] = source.basename.to_i
        publication.delete("page")

        unless source.content.strip.empty?
          publication["page"] = "/pubs/#{publication['number']}/"
          %w[zh en].each { |lang| add_detail_page(site, source, publication, lang) }
        end

        publication
      end.sort_by { |publication| -publication["number"] }
    end

    private

    def add_detail_page(site, source, publication, lang)
      path = "pubs/#{publication['number']}/"
      directory = lang == "en" ? "en/#{path}" : path
      detail = Jekyll::PageWithoutAFile.new(site, site.source, directory, "index.md")
      detail.content = source.content
      detail.data.merge!(
        "layout" => "publication",
        "lang" => lang,
        "nav_id" => "publications",
        "title" => publication["title"],
        "description" => publication["summary"],
        "translation_path" => path,
        "permalink" => "/#{directory}",
        "publication" => publication
      )
      site.pages << detail
    end
  end
end
