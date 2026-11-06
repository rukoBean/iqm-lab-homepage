# frozen_string_literal: true

module IQMLab
  # One shared source per member drives both cards and optional bilingual profiles.
  class Members < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      sources = site.pages.select do |page|
        page.relative_path.match?(%r!\Amember/[^/]+\.md\z!) && page.basename != "index"
      end
      site.pages -= sources

      site.data["members"] = sources.map do |source|
        member = source.data.dup
        member.delete("page")
        member["id"] = source.basename

        photo = "/member/portrait/#{member['id']}.webp"
        member["photo"] ||= photo if site.static_files.any? { |file| file.relative_path == photo }

        unless source.content.strip.empty?
          member["profile_urls"] = urls("#{member['id']}/")
          %w[zh en].each { |lang| add_profile_page(site, source, member, lang) }
        end

        member
      end.sort_by { |member| [member.fetch("order", Float::INFINITY), member["id"]] }
    end

    private

    def urls(suffix = "")
      { "zh" => "/member/#{suffix}", "en" => "/en/member/#{suffix}" }
    end

    def add_profile_page(site, source, member, lang)
      url = member["profile_urls"].fetch(lang)
      lab_name = lang == "en" ? "Intelligent Quantum Materials Lab" : "智能量子材料课题组"
      title_suffix = lang == "en" ? "IQM Lab" : lab_name
      profile = Jekyll::PageWithoutAFile.new(site, site.source, url.delete_prefix("/"), "index.md")
      profile.content = source.content
      profile.data.merge!(
        "layout" => "profile",
        "lang" => lang,
        "nav_id" => "member",
        "translation_path" => "member/#{member['id']}/",
        "permalink" => url,
        "title" => "#{member.fetch('name').fetch(lang)} | #{title_suffix}",
        "description" => member.fetch("bio", {})[lang],
        "heading" => member.fetch("name").fetch(lang),
        "intro" => "#{member.fetch('role').fetch(lang)} · #{lab_name}",
        "photo" => member["photo"],
        "member_path" => urls.fetch(lang)
      )
      site.pages << profile
    end
  end
end
