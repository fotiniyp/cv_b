#!/usr/bin/env ruby
# CV PDF Generator
# Reads data.yml and generates a PDF using pandoc and LaTeX

require 'yaml'
require 'fileutils'

def load_yaml(filepath)
  YAML.load_file(filepath)
end

def generate_markdown(data)
  md = []

  # Header
  sidebar = data['sidebar'] || {}
  name = sidebar['name'] || 'Name'
  tagline = sidebar['tagline'] || ''

  md << "# #{name}"
  md << "**#{tagline}**" if tagline && !tagline.empty?
  md << ""
  md << "---"
  md << ""

  # Contact
  md << "## Contact"
  md << ""
  md << "- Email: #{sidebar['email']}" if sidebar['email']
  md << "- Phone: #{sidebar['phone']}" if sidebar['phone']
  md << "- Website: #{sidebar['website']}" if sidebar['website']
  md << "- LinkedIn: #{sidebar['linkedin']}" if sidebar['linkedin']
  md << "- GitHub: #{sidebar['github']}" if sidebar['github']
  md << ""

  # Languages (can be in sidebar or at root level)
  languages = sidebar['languages'] || data['languages'] || {}
  if languages['info'] && !languages['info'].empty?
    md << "---"
    md << ""
    md << "## Languages"
    md << ""
    languages['info'].each do |lang|
      md << "- #{lang['idiom']} (#{lang['level']})"
    end
    md << ""
  end

  # Experience
  experiences = data['experiences'] || {}
  if experiences['info'] && !experiences['info'].empty?
    md << "---"
    md << ""
    md << "## Experience"
    md << ""
    experiences['info'].each do |exp|
      role = exp['role'] || ''
      company = exp['company'] || ''
      time = exp['time'] || ''
      details = exp['details'] || ''

      md << "### #{role} | #{company}"
      md << "*#{time}*" if time && !time.empty?
      md << ""
      md << details.strip if details && !details.empty?
      md << ""
    end
  end

  # Education
  education = data['education'] || {}
  if education['info'] && !education['info'].empty?
    md << "---"
    md << ""
    md << "## Education"
    md << ""
    education['info'].each do |edu|
      degree = edu['degree'] || ''
      university = edu['university'] || ''
      time = edu['time'] || ''

      if time && !time.empty?
        md << "- **#{degree}** - #{university} (#{time})"
      else
        md << "- **#{degree}** - #{university}"
      end
    end
    md << ""
  end

  # Certifications
  certifications = data['certifications'] || {}
  if certifications['list'] && !certifications['list'].empty?
    md << "---"
    md << ""
    md << "## Certifications"
    md << ""
    certifications['list'].each do |cert|
      name = cert['name'] || ''
      org = cert['organization'] || ''
      start_year = cert['start'] || ''
      end_year = cert['end'] || ''
      details = cert['details'] || ''

      md << "### #{name}"
      if org && !org.empty? && start_year && end_year
        md << "*#{org} (#{start_year}-#{end_year})*"
      elsif org && !org.empty?
        md << "*#{org}*"
      end
      md << ""
      md << details.strip if details && !details.empty?
      md << ""
    end
  end

  # Skills
  skills = data['skills'] || {}
  if skills['toolset'] && !skills['toolset'].empty?
    md << "---"
    md << ""
    md << "## Skills"
    md << ""
    skills['toolset'].each do |skill|
      md << skill['name'] if skill['name']
    end
    md << ""
  end

  # Projects
  projects = data['projects'] || {}
  if projects['assignments'] && !projects['assignments'].empty?
    md << "---"
    md << ""
    md << "## Projects"
    md << ""
    md << projects['intro'] if projects['intro']
    md << ""
    projects['assignments'].each do |proj|
      title = proj['title'] || ''
      tagline = proj['tagline'] || ''
      link = proj['link'] || ''

      if link && link != '#' && !link.empty?
        md << "### [#{title}](#{link})"
      else
        md << "### #{title}"
      end
      md << tagline if tagline && !tagline.empty?
      md << ""
    end
  end

  md.join("\n")
end

def generate_pdf(markdown_content, output_file)
  # Find pandoc
  pandoc_paths = [
    'pandoc',
    'C:\Users\konip\AppData\Local\Pandoc\pandoc.exe',
    'C:\Program Files\Pandoc\pandoc.exe',
    '/usr/bin/pandoc',
    '/usr/local/bin/pandoc'
  ]

  pandoc_path = nil
  pandoc_paths.each do |path|
    if system("#{path} --version > /dev/null 2>&1") || system("\"#{path}\" --version > nul 2>&1")
      pandoc_path = path
      break
    end
  end

  # On Linux/CI, pandoc should be in PATH
  pandoc_path ||= 'pandoc'

  # Create temporary markdown file with YAML front matter
  temp_md = 'temp_cv.md'
  full_content = <<~MARKDOWN
    ---
    geometry: margin=2cm
    fontsize: 11pt
    linkcolor: blue
    ---

    #{markdown_content}
  MARKDOWN

  File.write(temp_md, full_content)

  # Run pandoc
  cmd = "\"#{pandoc_path}\" #{temp_md} -o #{output_file} --pdf-engine=pdflatex"
  puts "Running: #{cmd}"

  success = system(cmd)

  # Clean up
  FileUtils.rm(temp_md) if File.exist?(temp_md)

  if success
    puts "Successfully generated: #{output_file}"
  else
    puts "Error generating PDF"
    exit 1
  end
end

def main
  # Default file paths
  script_dir = File.dirname(File.expand_path(__FILE__))
  yaml_file = File.join(script_dir, 'data.yml')
  output_pdf = File.join(script_dir, 'cv.pdf')

  # Allow custom input/output from command line
  yaml_file = ARGV[0] if ARGV[0]
  output_pdf = ARGV[1] if ARGV[1]

  puts "Reading: #{yaml_file}"

  # Load YAML
  data = load_yaml(yaml_file)

  # Generate Markdown
  markdown = generate_markdown(data)

  # Generate PDF
  generate_pdf(markdown, output_pdf)
end

main
