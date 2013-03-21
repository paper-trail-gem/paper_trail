module PaperTrail
  module Cleaner
    def gather_all_versions
      Version.all.group_by(&:item_id)
    end

    def get_all_keys
      @versions.keys
    end

    def grouping_for_key(key)
      @versions[key].group_by(&:grouping_by_date)
    end

    def sanitize(group)
      group.pop
      if group.size > 0
        group.each do |member| 
          member.destroy
        end
      end
    end

    def analyze_grouping(grouping)
      grouping.each_value do |group|
        sanitize(group)
      end
    end

    def acquire_version_info
      @versions = gather_all_versions
      @keys = get_all_keys
    end

    def examine_and_clean_versions
      @keys.each do |key|
        grouping = grouping_for_key(key)
        analyze_grouping(grouping)
      end
    end 

    def clean_paper_trail_versions
      acquire_version_info
      examine_and_clean_versions
    end
  end
end
