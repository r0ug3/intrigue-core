module Intrigue
  module Model
    class ScanResult < Sequel::Model
      plugin :validation_helpers
      plugin :serialization, :json, :options, :handlers, :whitelist_strings, :blacklist_strings

      many_to_one :logger
      many_to_one :project
      one_to_many :task_results
      many_to_one :base_entity, :class => :'Intrigue::Model::Entity', :key => :base_entity_id

      include Intrigue::Model::Mixins::Handleable

      def self.scope_by_project(project_name)
        named_project = Intrigue::Model::Project.first(:name => project_name)
        where(:project => named_project)
      end

      def validate
        super
        #validates_unique([:name, :project_id, :depth])
      end

      def start(queue)
        # Start our first task
        self.job_id = task_results.first.start(queue)
        self.save
      job_id
      end

      def add_filter_string(string)
        whitelist_strings << "#{string}"
        self.save
      end

      def log
        logger.full_log
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        return true if (entities.select {|e| e.match? entity}).length > 0
      end

      def entities
        # HACK!!!
        if self.project.scan_results.count > 1
          raise "unable to export"
        else
          return self.project.entities
        end

      end

      def increment_task_count
        self.incomplete_task_count += 1
        self.save
      end

      def decrement_task_count
        self.incomplete_task_count -= 1
        self.save
      end

      # just calculate it vs storing another property
      def timestamp_start
        return task_results.first.timestamp_start if task_results.first
      nil
      end

      # just calculate it vs storing another property
      def timestamp_end
        return task_results.last.timestamp_end if complete
      nil
      end

      ###
      ### Export!
      ###
      def export_hash
        {
          "id" => id,
          "name" => URI.escape(name),
          "depth" => depth,
          "complete" => complete,
          "machine" => machine,
          "timestamp_start" => timestamp_start,
          "timestamp_end" => timestamp_end,
          "whitelist_strings" => whitelist_strings,
          "blacklist_strings" => blacklist_strings,
          "project" => project.name,
          "base_entity" => base_entity.export_hash,
          #"task_results" => task_results.map{|t| t.export_hash },
          "entities" => entities.map {|e| e.export_hash },
          "options" => options,
          "log" => log
        }
      end

      def export_json
        export_hash.merge("generated_at" => "#{DateTime.now}").to_json
      end

      def export_csv
        self.entities.map{ |x| "#{x.export_csv}\n" }.join("")
      end

    end
  end
end
