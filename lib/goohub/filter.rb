# coding: utf-8
module Goohub
  class Filter
    def initialize(filter_id, sentence_items)
      @filter_id = filter_id
      @sentence_items = sentence_items
      @kvs = Goohub::DataStore.create(:redis, {:host => "localhost", :port => "6379".to_i, :db => "0".to_i})
      set_db
      filters = load("filters")
      filters.each { |f|
        @filter = f if f["name"]["#{@filter_id}"]
      }
    end

    def apply
      return if @filter_id == "no_filter"
      if expand_query("condition") != nil && expand_query("condition") != false
        expand_query("modifier")
      end
      @sentence_items
    end

    private

    #eval では，それまでに定義していない変数名を利用できないため，あえてif文を利用している
    def expand_query(type)
      if type == "condition" then
        method = @filter['condition'].split(':')[0]
        field =  @filter['condition'].split(':')[1]
        value =  @filter['condition'].split(':')[2]
        eval("#{method}(field,value)")
      elsif type == "modifier" then
        method = @filter['modifier'].split(':')[0]
        field =  @filter['modifier'].split(':')[1]
        value =  @filter['modifier'].split(':')[2]
        eval("#{method}(field,value)")
      end
    end

    #####################################################
    ### templete_methods
    #####################################################
    def replace(field, str)
      @sentence_items["#{field}"] = str
    end

    def match(field, pattern)
      @sentence_items["#{field}"].match(pattern)
    end

    def include?(field, str)
      @sentence_items["#{field}"].include?(str)
    end

    #####################################################
    ### setting_methods
    #####################################################
    def set_db
      summary_delete  ={
        "id" => "1",
        "name" => "summary_delete",
        "condition" => "match:summary:.",
        "modifier" => "replace:summary:"
      }
      created_delete  ={
        "id" => "2",
        "name" => "created_delete",
        "condition" => "match:summary:.",
        "modifier" => "replace:created:"
      }
      location_delete  ={
        "id" => "3",
        "name" => "location_delete",
        "condition" => "match:summary:.",
        "modifier" => "replace:location:"
      }
      filters = []
      filters << summary_delete << created_delete << location_delete
      register(filters, "filters")
    end

    #####################################################
    ### db_methods
    #####################################################

    def register(h, key)
      @kvs.store(key, h.to_json)
    end

    def delete(key)
      @kvs.delete(key)
    end

    def load(key)
      JSON.parse(@kvs.load(key))
    end
  end# class Filter
end# module Goohub