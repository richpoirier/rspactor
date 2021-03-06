require 'osx/cocoa'

class Notification  
  def self.subscribe(handled_by, subscription)    
    OSX::NSNotificationCenter.defaultCenter.addObserver_selector_name_object(
      handled_by, 
      subscription.values.first.to_s, 
      subscription.keys.first.to_sym, 
      nil 
    )          
  end  
  
  def self.send(name, *args)
    OSX::NSNotificationCenter.defaultCenter.postNotificationName_object_userInfo(name.to_s, self, args)    
  end    
end