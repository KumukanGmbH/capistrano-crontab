module Capistrano
  module DSL
    def crontab_get_content
      capture(:crontab, "-l")
    end

    def crontab_set_content(content)
      tempfile = Tempfile.new
      tempfile.write("#{content}\n")
      tempfile.close

      begin
        upload!(tempfile.path, tempfile.path)
        execute(:crontab, tempfile.path)
      ensure
        execute(:rm, "-f", tempfile.path)
        tempfile.unlink
      end
    end

    def crontab_puts_content
      puts crontab_get_content
    end

    def crontab_add_line(content, marker = nil)
      old_crontab = crontab_get_content
      marker = _crontab_marker(marker)
      crontab_set_content("#{old_crontab.rstrip}\n#{content}#{marker}")
    end

    def crontab_remove_line(marker)
      marker = _crontab_marker(marker)

      lines = crontab_get_content.split("\n")
        .reject { |line| line.end_with?(marker) }

      crontab_set_content(lines.join("\n"))
    end

    def crontab_update_line(content, marker)
      crontab_remove_line(marker)
      crontab_add_line(content, marker)
    end

    def _crontab_marker(marker)
      marker.nil? ? "" : " # MARKER:%s" % [marker]
    end
  end
end
