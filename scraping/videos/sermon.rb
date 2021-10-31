# sermon.rb

require 'json'

Sermon  = Struct.new(
            :source,
            :speaker,
            :date,              # String:  YYYY-MM-DD DayOfWeek
            :title,
            :series,
            :filename,          # In the sermon_archive directory
            :errors,
            :notes,
            :youtube_video_id,
            :youtube_playlist_id,
            :youtube_playlist_name
          ) do

  def to_json
    JSON.pretty_generate(to_h)
  end
end
