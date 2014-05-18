#Hack to generalise call empty? on
#objects, arrays and hashes
class Object
	def empty?
		false
	end
end

module JsonResume
	class Formatter
    attr_reader :hash
    
		def initialize(hash)
      @hash = hash

      #recursively defined proc
			@hash_proc = Proc.new do |k,v| 
                    v = k if v.nil? #hack to make it common for hash and array
										v.delete_if(&@hash_proc) if [Hash,Array].any? { |x| v.instance_of? x }
                    v.empty?
                  end
		end

    def add_linkedin_github_url
      @hash["linkedin_url"] = "http://linkedin.com/in/" + @hash["linkedin_id"] if @hash["linkedin_id"]
      @hash["github_url"] = "http://github.com/" + @hash["github_id"] if @hash["github_id"]
    end

    def add_last_marker_on_stars
      return if @hash['bio_data']['stars'].nil?
			@hash["bio_data"]["stars"] = {
        "items" => @hash["bio_data"]["stars"].map{ |i| { "name" => i } }
      }
			@hash["bio_data"]["stars"]["items"][-1]["last"] = true
    end

    def add_last_marker_on_skills
      return if @hash['bio_data']['skills']['details'].nil?
      @hash['bio_data']['skills']['details'].each do |item|
        item['items'].map!{|x| {'name'=>x} }
        item['items'][-1]['last'] = true        
      end
    end

		def cleanse
			@hash.delete_if &@hash_proc
      self
    end

    def format_to_output_type
			format_proc = Proc.new do |k,v| 
                      v = k if v.nil?
                      v.each{|x| format_proc.call(x)} if [Hash,Array].any? {|x| v.instance_of? x}
                      format_string v if v.instance_of? String
                    end
      @hash.each{|x| format_proc.call(x)}
      self
    end

    def format_string str
      raise NotImplementedError.new("format_string not impl in formatter")
    end

    def is_false? item
      item == false || item == 'false'
    end

    def purge_gpa
      return if @hash['bio_data']['education'].nil?
      @hash["bio_data"]["education"].delete("show_gpa") if is_false?(@hash["bio_data"]["education"]["show_gpa"]) || @hash["bio_data"]["education"]["schools"].all? {|sch| sch["gpa"].nil? || sch["gpa"].empty?} 
    end

		def format
      return if @hash["bio_data"].nil?
      
      cleanse

      format_to_output_type 

      add_last_marker_on_stars

      add_last_marker_on_skills

      purge_gpa

      add_linkedin_github_url

      return self
		end


	end
end    

