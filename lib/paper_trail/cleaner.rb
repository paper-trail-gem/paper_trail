module PaperTrail
  module Cleaner

    # Deletes all versions that were created on a given date except the last `keep_int` versions.
    # `date` argument should receive either an object of type `Date` or `:all` (which will clean versions on all dates).
    def clean_versions!(keep_int = 1, date = :all)
      version_hash = gather_versions(date)
      version_hash.each do |item_id, versions|
        grouping_by_date = versions.group_by { |v| v.created_at.to_date } # now group the versions by date
        grouping_by_date.each do |date, versions|
          versions.pop(keep_int)
          versions.map(&:destroy)
        end
      end
    end

    private

    # Returns a hash of versions in this format: {:item_id => PaperTrail::Version}
    def gather_versions(date)
      raise "`date` argument must receive a Timestamp or `:all`" unless date == :all || date.respond_to?(:to_time)
      versions = date == :all ? Version.all : Version.between(date, date+1.day)
      versions.group_by(&:item_id)
    end

  end
end
