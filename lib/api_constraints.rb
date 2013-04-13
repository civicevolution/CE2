# Allows a header to specify if you want a version other than the default version
# test: curl -H 'Accept: application/vnd.example.v1' http://localhost:3000/api/products

class ApiConstraints
  def initialize(options)
    @version = options[:version]
    @default = options[:default]
  end

  def matches?(req)
    @default #|| req.headers['Accept'].include?("application/vnd.example.v#{@version}")
  end
end