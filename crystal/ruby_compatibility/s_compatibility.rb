# s_compatibility.rb
=begin

  There are just some methods that from an English point-of-view
  make more sense with an "s" appended.  For example:

    Ruby        Crystal
    include?    includes?
    exist?      exists?

=end

class Module
  def alias_class_method(n, o); singleton_class.class_eval{alias_method n, o}; end
end

Enumerable.alias_method :includes?, :include?   # covers Array, Hash
String.alias_method     :includes?, :include?

Dir.alias_class_method    :exists?, :exist?
File.alias_class_method   :exists?, :exist?

Pathname.alias_method     :exists?, :exist?
