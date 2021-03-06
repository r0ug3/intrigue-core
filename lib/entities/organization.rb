module Intrigue
module Entity
class Organization < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Organization",
      :description => "An organization",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

  def enrichment_tasks
    ["enrich/organization"]
  end

end
end
end
