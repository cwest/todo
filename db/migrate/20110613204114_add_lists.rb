class AddLists < ActiveRecord::Migration
  
  class List < ActiveRecord::Base
    has_many :tasks
    attr_accessible :name
  end

  class Task < ActiveRecord::Base
    belongs_to :list
    attr_accessible :name
  end
  

  def self.up
  
    list = List.create(:name => 'Welcome')
    list.tasks.create(:name => 'Check out our docs https://docs.cloudfoundry.org')
    list.tasks.create(:name => 'Follow @pivotal https://twitter.com/pivotal')
    list.tasks.create(:name => 'Follow @caseywest https://twitter.com/caseywest')
    list.tasks.create(:name => 'We blog http://blog.pivotal.io')
    list.tasks.create(:name => 'Rock on!')
  end

  def self.down
    List.find_by_name('Test').destroy
  end
end
