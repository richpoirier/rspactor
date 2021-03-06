class ExampleFiles
  def self.init
    @@filter = :all
    @@example_files = {}
    @@_sorted_files = []
    ExampleMatcher.init
  end
  
  def self.filter=(filter)
    if filter != @@filter
      @@filter = filter
      self.update_sorted_list
    end
  end
  
  def self.add_spec(spec)
    example_file = find_or_create_example_file_by_spec(spec)
    example_file.add_spec(spec)
    self.update_sorted_list
  end
  
  def self.tainting_required_on_all_files!
    @@example_files.each { |path, ef| ef.tainting_required! }
  end
  
  def self.total_failed_spec_count
    failed_spec_count = 0
    @@example_files.each { |path, file| failed_spec_count += file.spec_count(:failed)  }
    failed_spec_count
  end
  
  def self.files_count
    @@_sorted_files.size
  end
  
  def self.file_by_index(index)
    @@example_files[@@_sorted_files[index]]
  end
  
  def self.file_by_path(path)
    @@example_files[path]
  end
  
  def self.file_by_spec_id(spec_id)
    files = @@example_files.select { |path, ef| !ef.spec_by_id(spec_id).nil? }
    files.empty? ? nil : files.first[1]
  end
  
  def self.clear_tainted_specs_on_all_files!
    @@example_files.collect { |path, ef| ef.remove_tainted_specs }.compact
  end
  
  def self.clear_suicided_files!
    unless @@example_files.delete_if { |path, file| file.suicide? }.empty?
      self.update_sorted_list
      reset_internal_stats!
      Notification.send :file_table_reload_required
    end
  end
  
  def self.index_for_file(file)
    @@_sorted_files.index(file.path)
  end
  
  def self.find_example_for_file(file_path)
    if @@example_files[file_path]
      file_path
    elsif ExampleMatcher.file_is_a_spec?(file_path)
      @@example_files[file_path] = ExampleFile.new(:path => file_path)
      self.update_sorted_list
      file_path
    else
      ExampleMatcher.match_file_pairs(file_path, @@example_files)
    end
  end
  
  def self.clear!
    @@example_files = {}
    @@_sorted_files = []
    reset_internal_stats!
  end
  
  def self.passed
    @@_passed_files ||= @@example_files.collect { |path, ef| ef.passed? ? ef : nil }.compact
  end
  
  def self.pending
    @@_pending_files ||= @@example_files.collect { |path, ef| ef.pending? ? ef : nil }.compact
  end
  
  def self.failed
    @@_failed_files ||= @@example_files.collect { |path, ef| ef.failed? ? ef : nil }.compact
  end
  
  def self.specs_count(filter = :all)
    count = 0
    if filter == :all      
      @@example_files.collect { |path, ef| count += ef.specs.size }
    else
      @@example_files.collect { |path, ef| count += ef.specs.select { |s| s.state == filter }.size }
    end
    count
  end
  
  def self.sorted_specs_for_all_files(opts = {})
    opts = { :filter => :all, :sorted => false, :limit => 5 }.merge(opts)
    examples = @@example_files.collect { |path, ef| ef.specs.select { |s| opts[:filter] == :all ? true : s.state == opts[:filter] } }.flatten
    
    if opts[:sorted] && opts[:sorted] == true
      examples.sort { |a,b| b.run_time <=> a.run_time }[0...(opts[:limit])]
    else
      examples[0...(opts[:limit])]
    end
  end  
  
  
  private
  
  def self.find_or_create_example_file_by_spec(spec)
    return @@example_files[spec.full_file_path] if @@example_files[spec.full_file_path]    
    if example_file = self.find_example_file_by_spec_name(spec)
      example_file
    else
      reset_internal_stats!
      example_file = ExampleFile.new(:path => spec.full_file_path)
      @@example_files[example_file.path] = example_file
      example_file
    end
  end
  
  def self.find_example_file_by_spec_name(spec)
    found_pairs = @@example_files.select { |path, ef| ef.has_spec?(spec) }
    if found_pairs.empty?
      return nil
    else
      found_pairs.first[1]
    end
  end
  
  def self.update_sorted_list
    case @@filter
    when :all
      @@_sorted_files = @@example_files.sort { |a,b| b[1].mtime <=> a[1].mtime }.collect { |f| f[0] }
    when :failed
      @@_sorted_files = @@example_files.select { |path, ef| ef.failed? }.sort { |a,b| a[1].mtime <=> b[1].mtime }.collect { |f| f[0] }
    end
  end  
  
  def self.reset_internal_stats!
    @@_passed_files = nil
    @@_pending_files = nil
    @@_failed_files = nil    
  end
end