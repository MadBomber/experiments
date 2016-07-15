class Widget < Sequel::Model
  plugin :json_serializer
  @java_class = become_java!
  def self.java_class
    @java_class
  end
end
